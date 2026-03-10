# Remote Functions Detailed Guide

## Overview

Remote functions (`command()`, `query()`, `form()`) from `$app/server`
enable server-side code execution from client components. They
automatically handle serialization, network transport, and validation.

## Available Functions

### command()

**Purpose:** One-time server actions (writes, updates, deletes)

**Signatures:**

```typescript
// With validation
command<T>(schema: StandardSchemaV1, handler: (input: T) => Promise<Result>)

// Without validation
command(handler: () => Promise<Result>)

// Unchecked mode
command.unchecked(handler: (input: unknown) => Promise<Result>)
```

**Example:**

```typescript
import { command } from "$app/server";
import * as v from "valibot";

export const create_post = command(
  v.object({
    title: v.string(),
    content: v.string(),
  }),
  async ({ title, content }) => {
    const post = await db.posts.create({ title, content });
    return { id: post.id };
  },
);
```

### query()

**Purpose:** Repeated reads, data fetching (supports batching)

**Batching:** Since v2.35, multiple `query()` calls can be
automatically batched into a single request.

**Example:**

```typescript
import { query } from "$app/server";
import * as v from "valibot";

export const get_user = query(v.object({ id: v.string() }), async ({ id }) => {
  return await db.users.findById(id);
});

// Client side - these may be batched:
const user1 = await get_user({ id: "1" });
const user2 = await get_user({ id: "2" });
```

### query.batch()

**Purpose:** Solve the n+1 problem by batching requests in the same macrotask.

Unlike regular `query()` which may batch automatically, `query.batch()`
explicitly groups requests and lets you resolve them efficiently (e.g.,
single DB query for multiple IDs).

```typescript
import { query } from "$app/server";
import * as v from "valibot";

export const get_weather = query.batch(v.string(), async (cities) => {
  // cities is an array of all requested city names
  const weather = await db.sql`
    SELECT * FROM weather WHERE city = ANY(${cities})
  `;

  // Return a resolver function
  const lookup = new Map(weather.map((w) => [w.city, w]));
  return (city) => lookup.get(city);
});
```

**Usage in component:**

```svelte
{#each cities as city}
  <!-- All these calls batch into ONE server request -->
  <CityWeather weather={await get_weather(city.id)} />
{/each}
```

**How it works:**

1. Multiple calls in same macrotask are collected
2. Server receives array of all inputs
3. Your handler returns a resolver function
4. SvelteKit calls resolver for each input to get individual results

## Using Queries in Svelte Components

Queries return promises. Use `{#await}` blocks or the imperative
`query.current`/`query.loading`/`query.error` properties.

> **⚠️ Known Bug:** `<svelte:boundary>` + `{@const await}` causes an
> infinite navigation loop during client-side page transitions when
> multiple pages share `query()` calls. The browser freezes as
> components mount/destroy endlessly. See
> [sveltejs/svelte#17717](https://github.com/sveltejs/svelte/issues/17717)
> (open) and
> [sveltejs/svelte#17512](https://github.com/sveltejs/svelte/issues/17512).
> Use `{#await}` or imperative query properties until this is fixed.

### Pattern 1: {#await} Block (Recommended)

```svelte
<script lang="ts">
	import { get_posts } from '$lib/posts.remote'

	// Query is cached - same call returns same promise
	const data = get_posts()
</script>

{#await data}
	<p>Loading...</p>
{:then posts}
	{#each posts as post}
		<article>{post.title}</article>
	{/each}
{:catch error}
	<p>Error: {error.message}</p>
{/await}
```

### Pattern 2: Imperative Query Properties

No `experimental.async` needed — works with any Svelte 5 version:

```svelte
<script lang="ts">
	import { get_posts } from '$lib/posts.remote'

	const query = get_posts()
</script>

{#if query.loading}
	<p>Loading...</p>
{:else if query.error}
	<p>Error: {query.error.message}</p>
{:else}
	{#each query.current as post}
		<article>{post.title}</article>
	{/each}
{/if}
```

### Pattern 3: Reactive Query with Navigation

For queries that depend on route params, `$derived()` returns a **Query
object** (not a plain promise). Use `.ready`/`.current` properties:

```svelte
<script lang="ts">
	import { page } from '$app/state'
	import { get_post } from '$lib/posts.remote'

	// Extract reactive value first
	let slug = $derived(page.params.slug)

	// Returns a reactive Query object — use .ready/.current
	let post_query = $derived(get_post({ slug }))
</script>

{#if !post_query.ready}
	<p>Loading...</p>
{:else}
	<h1>{post_query.current.title}</h1>
	<div>{@html post_query.current.content}</div>
{/if}
```

**Query object properties:**

- `.ready` — `true` after first successful load
- `.current` — resolved data (`undefined` until ready)
- `.loading` — active loading/reloading state
- `.error` — rejection error
- `.refresh()` — re-fetch from server
- `.set(value)` — manually update cached value
- `.withOverride(fn)` — optimistic updates

**Experimental async alternative** (requires `experimental.async` in svelte.config.js):

```svelte
<script lang="ts">
	let slug = $derived(page.params.slug)
	let post = $derived(await get_post({ slug }))
</script>

<h1>{post.title}</h1>
```

### Polling with Refresh

```svelte
<script lang="ts">
	import { get_active_visitors } from '$lib/analytics.remote'

	// Query is cached
	const data = get_active_visitors({ limit: 10 })

	// Refresh every 5 seconds - updates cached query in place
	$effect(() => {
		const interval = setInterval(
			() => get_active_visitors({ limit: 10 }).refresh(),
			5000,
		)
		return () => clearInterval(interval)
	})
</script>

{#await data}
	<p>Loading...</p>
{:then result}
	<p>{result.total} active visitors</p>
{/await}
```

**Key points:**

- Queries are cached while on the page (`get_posts() === get_posts()`)
- Call `.refresh()` on the query to refetch from server
- Use imperative `query.current` for flicker-free refresh updates

### Error Handling and Polling

#### .refresh() returns a rejectable Promise

`query().refresh()` returns a Promise. On server error (e.g., 500), the
promise **rejects** with `HttpError`. If uncaught, this is a silent
unhandled promise rejection.

#### Cache eviction on error

Failed queries are evicted from the internal cache (`query_map`). The
next call to the same remote function creates a **new** Query object,
not the cached one. Prefer refreshing an existing reference over
re-calling the function.

#### Safe polling pattern

```svelte
<script lang="ts">
	import { get_active_visitors } from '$lib/analytics.remote'

	const data = get_active_visitors({ limit: 10 })

	$effect(() => {
		const interval = setInterval(() => {
			// MUST .catch() — one 500 kills the loop via uncaught rejection
			data.refresh().catch(() => {})
		}, 5000)
		return () => clearInterval(interval)
	})
</script>

{#if data.error}
	<p>Error: {data.error.message}</p>
{:else if !data.ready}
	<p>Loading...</p>
{:else}
	<p>{data.current.total} active visitors</p>
{/if}
```

#### State after failed .refresh()

- `.ready` stays `true` (doesn't reset)
- `.error` gets set with the rejection error
- `.current` retains the last successful value
- The Promise rejects (must be caught)

#### Best practices

- **Always `.catch()`** refresh calls in `setInterval` loops
- **Prefer refreshing an existing reference** over re-calling the remote function
- **Check `.error`** in your template for graceful degradation
- **Don't rely on cache** after errors — the query is evicted

### Common Mistakes

❌ **Wrong: svelte:boundary + {@const await} — navigation loop bug**

```svelte
<!-- DO NOT USE until sveltejs/svelte#17717 is fixed -->
<svelte:boundary>
	{#snippet pending()}
		<p>Loading...</p>
	{/snippet}

	{@const result = await data}
	...
</svelte:boundary>
```

This causes infinite mount/destroy loops during client-side navigation
when pages share `query()` calls.

❌ **Wrong: Not tracking reactive dependencies**

```svelte
<script>
	// path is NOT tracked - won't re-run on navigation!
	const data = get_data({ path: page.url.pathname })
</script>
```

✅ **Right: Extract reactive value first**

```svelte
<script>
	let path = $derived(page.url.pathname)

	// path IS tracked - re-runs when path changes
	let data = $derived(get_data({ path }))
</script>
```

### form()

**Purpose:** Generate form props for progressive enhancement

**Basic usage:**

```typescript
import { form } from "$app/server";
import * as v from "valibot";

export const create_post = form(
  v.object({
    title: v.string(),
    content: v.string(),
  }),
  async ({ title, content }) => {
    await db.posts.create({ title, content });
  },
);
```

### Form Field Spreading

Use `.fields` with `.as()` to get typed input attributes:

```svelte
<form {...createPost}>
  <label>
    Title
    <input {...createPost.fields.title.as('text')} />
  </label>

  <label>
    Content
    <textarea {...createPost.fields.content.as('text')} />
  </label>

  <button>Publish</button>
</form>
```

**What `.as()` provides:**

- Correct `type` attribute
- `name` for form data construction
- `value` populated on validation error (user doesn't re-enter)
- `aria-invalid` for accessibility

**Input types:** `'text'`, `'email'`, `'password'`, `'number'`, `'checkbox'`, etc.

### Private Fields (Sensitive Data)

Prefix field names with `_` to prevent repopulation on validation error:

```svelte
<form {...register}>
  <input {...register.fields.username.as('text')} />
  <!-- Password won't be sent back if validation fails -->
  <input {...register.fields._password.as('password')} />
  <button>Sign up</button>
</form>
```

Use for passwords, credit cards, sensitive data that shouldn't round-trip.

### Multiple Submit Buttons

Add a field for button value, use `.as('submit', value)`:

```svelte
<form {...loginOrRegister}>
  <input {...loginOrRegister.fields.username.as('text')} />
  <input {...loginOrRegister.fields._password.as('password')} />

  <button {...loginOrRegister.fields.action.as('submit', 'login')}>Login</button>
  <button {...loginOrRegister.fields.action.as('submit', 'register')}>Register</button>
</form>
```

### enhance() Callback

Customize form submission behavior:

```svelte
<form {...createPost.enhance(async ({ form, data, submit }) => {
  try {
    await submit();
    form.reset();
    showToast('Published!');
  } catch (error) {
    showToast('Something went wrong');
  }
})}>
```

**Note:** With `enhance`, form is NOT auto-reset - call `form.reset()` manually.

## Validation

Remote functions support **StandardSchemaV1** - a universal schema
standard implemented by Valibot, Zod, ArkType, and others.

### With Valibot

```typescript
import * as v from "valibot";

export const update_settings = command(
  v.object({
    theme: v.union([v.literal("light"), v.literal("dark")]),
    notifications: v.boolean(),
  }),
  async (settings) => {
    // settings is fully typed and validated
    await db.settings.update(settings);
  },
);
```

### Without Validation

```typescript
export const simple_action = command(async () => {
  // No input validation
  return { timestamp: Date.now() };
});
```

### Unchecked Mode

```typescript
export const flexible_action = command.unchecked(async (input) => {
  // input is unknown - validate manually if needed
  return process(input);
});
```

## Serialization Rules

**Can serialize:**

- Primitives: string, number, boolean, null
- Plain objects and arrays
- Date objects
- Maps and Sets
- RegExp
- TypedArrays

**Cannot serialize:**

- Functions
- Class instances (unless they have toJSON)
- Symbols
- Circular references

**Example:**

```typescript
// ✅ Valid
return {
  name: "Alice",
  age: 30,
  created: new Date(),
};

// ❌ Invalid
return {
  user: new User(), // Class instance
  callback: () => {}, // Function
};
```

## Access Request Context

Use `getRequestEvent()` inside remote functions to access cookies,
headers, etc:

```typescript
import { command, getRequestEvent } from "$app/server";

export const get_session = command(async () => {
  const event = getRequestEvent();
  const sessionId = event.cookies.get("session");

  return { sessionId };
});
```

### ⚠️ Cookie Limitation

**`event.cookies.set()` in `command()` functions does NOT propagate Set-Cookie headers to the browser.** This is a known limitation.

❌ **Don't use command() for auth that needs to set cookies:**

```typescript
// BROKEN: Cookies won't be set in browser
export const demo_login = command(async () => {
  const event = getRequestEvent();
  const result = await auth.api.signInEmail({ ... });

  // This won't work - cookie not sent to browser!
  event.cookies.set('session', token, { path: '/' });

  return { success: true };
});
```

✅ **Use client-side auth SDK instead:**

```svelte
<script>
  import { goto } from '$app/navigation';
  import { auth_client } from '$lib/auth-client';

  async function handle_login() {
    // Client-side auth properly handles cookies
    const result = await auth_client.signIn.email({ email, password });

    if (!result.error) {
      await goto('/dashboard', { invalidateAll: true });
    }
  }
</script>
```

**For auth operations that need cookies**, use:

- Client-side auth SDK (Better Auth, Auth.js client)
- Form actions with `throw redirect()`
- API routes (`+server.ts`)

## Error Handling

Thrown errors are serialized and re-thrown on the client:

```typescript
export const risky_action = command(
  v.object({ id: v.string() }),
  async ({ id }) => {
    const item = await db.items.find(id);
    if (!item) {
      throw new Error("Item not found");
    }
    return item;
  },
);

// Client side:
try {
  await risky_action({ id: "123" });
} catch (error) {
  console.error(error.message); // "Item not found"
}
```

## File Naming Convention

Use `*.remote.ts` suffix to indicate files containing remote
functions:

```
src/lib/
	users.remote.ts		 ← Remote functions
	database.server.ts	← Server-only utilities (no remote calls)
	utils.ts						← Universal utilities
```

## Performance Tips

1. **Use query() for reads** - Benefits from batching
2. **Batch operations** - Group multiple writes into one command
3. **Return minimal data** - Serialization has overhead
4. **Cache query results** - Client-side caching works normally

## Common Patterns

### CRUD Operations

```typescript
export const create_item = command(schema, async (data) => { ... });
export const read_item = query(idSchema, async ({ id }) => { ... });
export const update_item = command(updateSchema, async (data) => { ... });
export const delete_item = command(idSchema, async ({ id }) => { ... });
```

### With Authorization

```typescript
export const admin_action = command(schema, async (data) => {
  const event = getRequestEvent();
  const user = await getUserFromEvent(event);

  if (!user.isAdmin) {
    throw new Error("Unauthorized");
  }

  return performAdminAction(data);
});
```

### Single-Flight Mutations with .updates()

By default, all queries refresh after form submission. Use `.updates()`
for efficient client-driven single-flight mutations:

**In enhance callback (forms):**

```svelte
<form {...createPost.enhance(async ({ submit }) => {
  // Only refresh getPosts, not all queries
  await submit().updates(getPosts());
})}>
```

**With commands:**

```typescript
// Refresh specific query after command
await addLike(item.id).updates(getLikes(item.id));
```

### Optimistic Updates with .withOverride()

Show instant UI feedback while mutation is in flight:

```typescript
// Optimistic increment - shows immediately, auto-rollback on error
await addLike(item.id).updates(getLikes(item.id).withOverride((n) => n + 1));
```

**Form example:**

```svelte
<form {...addTodo.enhance(async ({ data, submit }) => {
  await submit().updates(
    todos.withOverride((list) => [...list, { text: data.get('text') }])
  );
})}>
```

**How it works:**

1. Override applied immediately (instant UI)
2. Server mutation runs
3. On success: real data replaces override
4. On error: override released, original data restored

### Server-Side Query Updates

Inside command/form handlers, use `.refresh()` or `.set()`:

```typescript
export const updatePost = form(schema, async (data) => {
  const result = await externalApi.update(post);

  // Option 1: Refetch from DB
  await getPost(post.id).refresh();

  // Option 2: Set directly (if you have the data)
  await getPost(post.id).set(result);
});
```

This sends updated data back with the response - no second round-trip.

### Manual Optimistic Updates (Alternative)

For cases where built-in `.withOverride()` doesn't fit:

```typescript
let items = $state([...]);

async function addItem(item) {
	items = [...items, item];

	try {
		await create_item(item);
	} catch (error) {
		items = items.filter(i => i !== item);
		throw error;
	}
}
```

## TypeScript Tips

Remote functions maintain full type safety:

```typescript
// Server
export const get_post = query(
  v.object({ id: v.number() }),
  async ({ id }): Promise<{ title: string; body: string }> => {
    return await db.posts.find(id);
  },
);

// Client - fully typed!
const post = await get_post({ id: 42 });
post.title; // ✅ string
post.invalid; // ❌ Type error
```

## Comparison with Traditional Approaches

| Approach                | Use Case                 | Pros                               | Cons                      |
| ----------------------- | ------------------------ | ---------------------------------- | ------------------------- |
| Remote Functions        | Client-initiated actions | Simple, type-safe, no routing      | Requires v2.27+           |
| Form Actions            | Progressive forms        | SEO-friendly, works without JS     | Page-based, less flexible |
| API Routes (+server.ts) | Public APIs, webhooks    | Full control, RESTful              | More boilerplate          |
| Load Functions          | Page data                | Automatic, integrated with routing | Page-lifecycle bound      |

Choose remote functions when you need:

- Type-safe RPC from components
- Simple CRUD operations
- Client-driven interactions
- No public API exposure needed

## Testing Remote Functions

Remote functions depend on `$app/server` runtime and can't be tested
directly. Extract business logic into **helper files** and test those.

### Helper Files Paradigm

```
src/lib/
  agents.remote.ts       → thin wrapper (command/query + auth guard)
  agents.helpers.ts      → pure business logic (DB queries, transforms)
  agents.helpers.test.ts → unit tests for the helpers
```

### Example

**Remote file (thin wrapper):**

```typescript
// agents.remote.ts
import { command } from "$app/server";
import * as v from "valibot";
import { create_agent, delete_agent } from "./agents.helpers";

export const create = command(
  v.object({ name: v.string(), model: v.string() }),
  async (input) => {
    const event = getRequestEvent();
    const user = await getUserFromEvent(event);
    return create_agent(user.id, input);
  },
);

export const remove = command(v.object({ id: v.string() }), async ({ id }) => {
  const event = getRequestEvent();
  const user = await getUserFromEvent(event);
  return delete_agent(user.id, id);
});
```

**Helper file (testable logic):**

```typescript
// agents.helpers.ts
export async function create_agent(
  user_id: string,
  input: { name: string; model: string },
) {
  const agent = await db.agents.create({ ...input, owner_id: user_id });
  return { id: agent.id, name: agent.name };
}

export async function delete_agent(user_id: string, agent_id: string) {
  const agent = await db.agents.findById(agent_id);
  if (agent?.owner_id !== user_id) throw new Error("Unauthorized");
  await db.agents.delete(agent_id);
  return { success: true };
}
```

**Test file:**

```typescript
// agents.helpers.test.ts
import { describe, it, expect, vi } from "vitest";
import { create_agent, delete_agent } from "./agents.helpers";

describe("create_agent", () => {
  it("creates agent with owner", async () => {
    const result = await create_agent("user-1", {
      name: "Bot",
      model: "gpt-4",
    });
    expect(result).toHaveProperty("id");
    expect(result.name).toBe("Bot");
  });
});

describe("delete_agent", () => {
  it("throws if not owner", async () => {
    await expect(delete_agent("wrong-user", "agent-1")).rejects.toThrow(
      "Unauthorized",
    );
  });
});
```

### What stays in remote vs helpers

| Remote file (`.remote.ts`)      | Helper file (`.helpers.ts`) |
| ------------------------------- | --------------------------- |
| `command()`/`query()`/`form()`  | Business logic              |
| Schema validation               | DB queries and transforms   |
| Auth guards (`getRequestEvent`) | Data validation rules       |
| Input/output shaping            | Error conditions            |

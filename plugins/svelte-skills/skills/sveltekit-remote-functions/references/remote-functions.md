# SvelteKit Remote Functions

Verified against SvelteKit 2.58.0 on 2026-04-24.

Remote functions are exported from `.remote.ts`/`.remote.js` files and can be
called anywhere in the app. They always execute on the server. On the client,
SvelteKit transforms calls into generated `fetch` requests.

Remote functions are still experimental. Enable them explicitly:

```js
// svelte.config.js
export default {
	kit: {
		experimental: {
			remoteFunctions: true
		}
	},
	compilerOptions: {
		experimental: {
			async: true // optional; needed for `await` in components
		}
	}
};
```

Remote files can live anywhere under `src` except `src/lib/server`.

## Function Types

| Function      | Use for                                      | Notes |
| ------------- | -------------------------------------------- | ----- |
| `query()`     | Dynamic server reads                         | Cached while rendered; supports refresh and batching |
| `form()`      | Progressive form mutations                   | Works without JS; supports fields, validation, enhance |
| `command()`   | Imperative/event-handler mutations           | Cannot be called during render |
| `prerender()` | Static/build-time reads                      | For data that changes at most once per deployment |

## query()

Use `query()` for dynamic server reads.

```ts
import { query } from '$app/server';
import * as v from 'valibot';

export const getPost = query(v.string(), async (slug) => {
	return db.posts.findBySlug(slug);
});
```

In components with async enabled:

```svelte
<script lang="ts">
	import { getPost } from './posts.remote';
	let { slug } = $props();
	const post = $derived(await getPost(slug));
</script>

<h1>{post.title}</h1>
```

Without async in components, use `{#await}`:

```svelte
{#await getPost(slug) then post}
	<h1>{post.title}</h1>
{/await}
```

### Query refresh

```svelte
<button onclick={() => getPost(slug).refresh()}>
	Refresh
</button>
```

Queries are cached while on the page. Calling `getPost(slug)` repeatedly returns
the same active query instance for that argument.

### query.batch()

Use `query.batch()` for n+1 reads. Calls made in the same macrotask are grouped
into one server request. The handler receives all inputs and returns a resolver.

```ts
import { query } from '$app/server';
import * as v from 'valibot';

export const getWeather = query.batch(v.string(), async (cityIds) => {
	const rows = await db.weather.findMany(cityIds);
	const byId = new Map(rows.map((row) => [row.city_id, row]));
	return (cityId) => byId.get(cityId);
});
```

## form()

Use `form()` for mutations that should gracefully degrade when JavaScript is
disabled.

```ts
import { form } from '$app/server';
import * as v from 'valibot';

export const createPost = form(
	v.object({
		title: v.pipe(v.string(), v.nonEmpty()),
		content: v.pipe(v.string(), v.nonEmpty())
	}),
	async ({ title, content }) => {
		await db.posts.create({ title, content });
	}
);
```

Use `.fields.<name>.as(type)` to bind typed inputs:

```svelte
<form {...createPost}>
	<input {...createPost.fields.title.as('text')} />
	<textarea {...createPost.fields.content.as('text')}></textarea>
	<button>Publish</button>
</form>
```

`.as(...)` supplies `name`, type-specific attributes, validation state, and
repopulation behavior after failed validation.

### Sensitive fields

Prefix sensitive field names with `_` to prevent repopulation after invalid
non-enhanced submissions:

```svelte
<input {...login.fields._password.as('password')} />
```

Use this for passwords, credit card numbers, tokens, and similar secrets.

### Validation

If schema validation fails, the handler does not run. Issues are exposed through
field helpers:

```svelte
{#each createPost.fields.title.issues() as issue}
	<p class="error">{issue.message}</p>
{/each}
```

Programmatic validation inside a handler uses `invalid` from `@sveltejs/kit`:

```ts
import { invalid } from '@sveltejs/kit';
import { form } from '$app/server';

export const login = form(schema, async (data, issue) => {
	if (!(await auth.check(data))) {
		invalid(issue.email('Invalid credentials'));
	}
});
```

Client-side preflight validation can prevent invalid submissions before they hit
the server:

```svelte
<form {...createPost.preflight(schema)}>
	<!-- fields -->
</form>
```

### enhance()

`enhance` customizes JS-enabled submission. Since SvelteKit 2.57,
`submit()` returns a boolean: `true` means the submission completed without
validation failure; `false` means validation failed and the handler did not run.

```svelte
<form {...createPost.enhance(async ({ form, submit }) => {
	try {
		if (await submit()) {
			form.reset();
			showToast('Published');
		}
	} catch (error) {
		showToast('Something went wrong');
	}
})}>
	<!-- fields -->
</form>
```

With `enhance`, the form is not automatically reset. Call `form.reset()` when you
want to clear inputs.

### Multiple form instances

Use `.for(id)` when rendering the same form many times and each instance needs
isolated state.

```svelte
{#each todos as todo}
	{@const modify = modifyTodo.for(todo.id)}
	<form {...modify}>
		<input {...modify.fields.description.as('text', todo.description)} />
		<button disabled={!!modify.pending}>Save</button>
	</form>
{/each}
```

### Multiple submit buttons

Model the clicked submit button as a schema field and bind buttons with
`.as('submit', value)`.

```svelte
<form {...loginOrRegister}>
	<input {...loginOrRegister.fields.email.as('email')} />
	<input {...loginOrRegister.fields._password.as('password')} />
	<button {...loginOrRegister.fields.action.as('submit', 'login')}>Login</button>
	<button {...loginOrRegister.fields.action.as('submit', 'register')}>Register</button>
</form>
```

### File uploads

Remote `form()` supports file uploads. Since SvelteKit 2.49, enhanced forms use a
streaming binary upload format so server-side form handlers can access form data
before large files finish uploading. SvelteKit 2.52 tightened file metadata and
offset-table validation.

Practical rules:

- Keep file schemas explicit and validate type/size server-side.
- Do not trust client-provided file metadata.
- Prefer streaming processing/storage for large files.
- Handle upload errors as normal form validation or request errors.

## command()

Use `command()` for mutations from event handlers or other imperative code.
Prefer `form()` when progressive enhancement matters.

```ts
import { command } from '$app/server';
import * as v from 'valibot';

export const addLike = command(v.string(), async (postId) => {
	await db.posts.incrementLikes(postId);
});
```

```svelte
<button onclick={() => addLike(post.id).updates(getLikes(post.id))}>
	Like
</button>
```

Commands cannot be called during render.

## Single-flight mutations

Use single-flight mutations to refresh query data in the same request as a
`form()` submission or `command()` invocation. This avoids an extra round-trip
and prevents stale UI.

There are two sides:

1. **Client requests updates** with `.updates(...)`
2. **Server accepts updates** with `requested(queryFn, limit)`

### Client: .updates()

`.updates()` accepts query functions, query instances, and optimistic overrides.

```ts
// Refresh all active getPosts instances
await createPost(data).updates(getPosts);

// Refresh one instance
await addLike(post.id).updates(getLikes(post.id));

// Optimistic update
await addLike(post.id).updates(getLikes(post.id).withOverride((n) => n + 1));
```

Inside enhanced forms:

```svelte
<form {...createPost.enhance(async ({ submit }) => {
	await submit().updates(getPosts);
})}>
	<!-- fields -->
</form>
```

### Server: requested(queryFn, limit)

`requested` is required for client-requested refreshes. The `limit` argument is
required as of SvelteKit 2.58 because the list is client-controlled and each item
can cause validation and data fetching.

```ts
import { command, query, requested } from '$app/server';

export const getPosts = query(filterSchema, async (filter) => {
	return db.posts.find(filter);
});

export const createPost = command(createSchema, async (data) => {
	await db.posts.create(data);

	for (const { arg, query } of requested(getPosts, 5)) {
		// arg is the validated/transformed argument
		// query is bound to the original client cache key
		void query.refresh();
	}
});
```

Important current behavior:

- `requested(queryFn, limit)` yields `{ arg, query }` objects, not raw args.
- Use the yielded `query` instance for `.refresh()`/`.set(...)`; it is bound to
the original client cache key even if validation transformed `arg`.
- `limit` is required. Choose the maximum refreshes you are willing to process
per mutation. `Infinity` is possible but usually a DoS footgun.
- If parsing one requested argument fails, that query errors, but the whole
mutation does not fail.

Shorthand:

```ts
await requested(getPosts, 5).refreshAll();
```

This is equivalent to looping and calling `void query.refresh()` for each
requested query.

### Server-driven updates

If the server already knows exactly what changed, call `.refresh()` or `.set()`
inside the handler without waiting for a client request.

```ts
export const updatePost = command(updateSchema, async ({ id, title }) => {
	const post = await db.posts.update(id, { title });

	void getPost(id).set(post);     // send known value back
	void getPosts().refresh();      // refetch list in same response
});
```

Use `void` rather than `await`; SvelteKit awaits and serializes these updates for
the response.

## prerender()

Use `prerender()` for data that changes at most once per deployment. Results are
computed during prerendering and can be cached on a CDN.

```ts
import { prerender } from '$app/server';
import * as v from 'valibot';

export const getPosts = prerender(async () => {
	return db.posts.allPublished();
});

export const getPost = prerender(v.string(), async (slug) => {
	return db.posts.findBySlug(slug);
});
```

SvelteKit's crawler automatically saves calls it discovers while prerendering.
Use the `inputs` option when you need to enumerate values explicitly.

## getRequestEvent()

Use `getRequestEvent()` inside remote functions for cookies, headers, locals,
and other request context.

```ts
import { getRequestEvent, query } from '$app/server';

export const getMe = query(async () => {
	const event = getRequestEvent();
	return event.locals.user;
});
```

## Serialization

Remote arguments and return values are serialized with `devalue`.

Can serialize:

- primitives, arrays, plain objects
- `Date`, `Map`, `Set`, typed arrays

Avoid:

- functions
- class instances without serialization support
- symbols
- circular references
- `RegExp` as remote function arguments

Query cache keys are based on serialized arguments. Object keys are normalized,
so `{ limit: 10, offset: 20 }` and `{ offset: 20, limit: 10 }` refer to the same
query cache entry.

## Common Gotchas

- Remote functions are HTTP endpoints; validate every exposed input.
- `form()` invalid schema submissions do not run the handler.
- `command()` does not auto-refresh anything; use `.updates()` or server-driven
query updates.
- `form()` auto-invalidates broadly after successful submissions unless you use
more targeted single-flight updates.
- `requested()` must name each query function the server is willing to refresh;
this protects bundle size and avoids unbounded client-controlled work.
- Use `form()` instead of `command()` when no-JS behavior matters.
- Do not export shared schemas from `.remote.ts`; put them in a shared module or
component module script.

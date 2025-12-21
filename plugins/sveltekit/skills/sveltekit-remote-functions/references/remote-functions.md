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
import { command } from '$app/server';
import * as v from 'valibot';

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
import { query } from '$app/server';
import * as v from 'valibot';

export const get_user = query(
	v.object({ id: v.string() }),
	async ({ id }) => {
		return await db.users.findById(id);
	},
);

// Client side - these may be batched:
const user1 = await get_user({ id: '1' });
const user2 = await get_user({ id: '2' });
```

### form()

**Purpose:** Generate form props for progressive enhancement

**Usage:**

```typescript
import { form } from '$app/server';
import * as v from 'valibot';

export const login_form = form(
	v.object({
		email: v.string(),
		password: v.string(),
	}),
	async ({ email, password }) => {
		// Handle login
		return { success: true };
	}
);

// In component:
<form {...login_form}>
	<input name="email" />
	<input name="password" type="password" />
	<button>Login</button>
</form>
```

## Validation

Remote functions support **StandardSchemaV1** - a universal schema
standard implemented by Valibot, Zod, ArkType, and others.

### With Valibot

```typescript
import * as v from 'valibot';

export const update_settings = command(
	v.object({
		theme: v.union([v.literal('light'), v.literal('dark')]),
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
	name: 'Alice',
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
import { command, getRequestEvent } from '$app/server';

export const get_session = command(async () => {
	const event = getRequestEvent();
	const sessionId = event.cookies.get('session');

	return { sessionId };
});
```

## Error Handling

Thrown errors are serialized and re-thrown on the client:

```typescript
export const risky_action = command(
	v.object({ id: v.string() }),
	async ({ id }) => {
		const item = await db.items.find(id);
		if (!item) {
			throw new Error('Item not found');
		}
		return item;
	},
);

// Client side:
try {
	await risky_action({ id: '123' });
} catch (error) {
	console.error(error.message); // "Item not found"
}
```

## File Naming Convention

Use `*.remote.ts` suffix to indicate files containing remote
functions:

```
src/lib/
  users.remote.ts     ← Remote functions
  database.server.ts  ← Server-only utilities (no remote calls)
  utils.ts            ← Universal utilities
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
		throw new Error('Unauthorized');
	}

	return performAdminAction(data);
});
```

### Optimistic Updates

```typescript
// Client code
let items = $state([...]);

async function addItem(item) {
	// Optimistic update
	items = [...items, item];

	try {
		await create_item(item);
	} catch (error) {
		// Rollback on error
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

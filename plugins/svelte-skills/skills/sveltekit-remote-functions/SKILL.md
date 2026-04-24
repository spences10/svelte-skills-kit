---
name: sveltekit-remote-functions
# IMPORTANT: Keep description on ONE line for agent compatibility
# prettier-ignore
description: "SvelteKit remote functions guidance. Use for query(), form(), command(), and prerender() patterns in .remote.ts files."
---

# SvelteKit Remote Functions

## Current Status

Remote functions are **experimental** in SvelteKit 2.58. Enable them in
`svelte.config.js`:

```js
export default {
	kit: { experimental: { remoteFunctions: true } },
	compilerOptions: { experimental: { async: true } } // only for await in components
};
```

## Quick Start

**File naming:** export remote functions from `*.remote.ts` or `*.remote.js`.
Remote files can live anywhere under `src` except `src/lib/server`.

**Which function?**

- Dynamic reads → `query()`
- Progressive forms → `form()`
- Event-handler mutations → `command()`
- Build-time/static reads → `prerender()`

## Example

```ts
// posts.remote.ts
import { command, query, requested } from '$app/server';
import * as v from 'valibot';

export const getPosts = query(v.object({ tag: v.optional(v.string()) }), async (filter) => {
	return db.posts.find(filter);
});

export const createPost = command(v.object({ title: v.string() }), async (data) => {
	await db.posts.create(data);

	for (const { query } of requested(getPosts, 5)) {
		void query.refresh();
	}
});
```

Client:

```svelte
<script lang="ts">
	import { createPost, getPosts } from './posts.remote';

	const posts = $derived(await getPosts({ tag: 'svelte' }));
</script>

<button onclick={() => createPost({ title: 'New' }).updates(getPosts)}>
	Create
</button>
```

## Current Rules

- Remote functions always run on the server, even when called from the browser.
- Args/returns use `devalue`; avoid functions, class instances, symbols, circular refs, and `RegExp`.
- Validate exposed inputs with Standard Schema (`valibot`, `zod`, `arktype`, etc.) or use `.unchecked`/`'unchecked'` deliberately.
- `query.batch()` batches calls from the same macrotask to solve n+1 reads.
- `form().enhance()` `submit()` returns `true` when submission is valid/successful and `false` for validation failures.
- `.updates()` is client-requested; server handlers must opt in with `requested(queryFn, limit)`.
- `requested()` now yields `{ arg, query }`; call `query.refresh()`/`query.set(...)` on the bound instance.
- `limit` is required for `requested()` to cap client-controlled refresh requests.
- Inside command/form handlers, use `void query.refresh()`/`void query.set(value)`; SvelteKit awaits and serializes the updates.
- Prefer `form()` over `command()` where progressive enhancement matters.
- Use `prerender()` for data that changes at most once per deployment.
- **Last verified:** SvelteKit 2.58.0, 2026-04-24

## Reference Files

- [references/remote-functions.md](references/remote-functions.md) - Current patterns, examples, and gotchas

<!--
PROGRESSIVE DISCLOSURE GUIDELINES:
- Keep this file ~50 lines total (max ~150 lines)
- Use 1-2 code blocks only (recommend 1)
- Keep description <200 chars for Level 1 efficiency
- Move detailed docs to references/ for Level 3 loading
- This is Level 2 - quick reference ONLY, not a manual

LLM WORKFLOW (when editing this file):
1. Write/edit SKILL.md
2. Format (if formatter available)
3. Run: npx skills add . --list
4. If the skill is not discovered, check SKILL.md frontmatter formatting
5. Validate again to confirm
-->

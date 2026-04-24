---
name: sveltekit-remote-functions
# IMPORTANT: Keep description on ONE line for agent compatibility
# prettier-ignore
description: "SvelteKit remote functions guidance. Use for command(), query(), form() patterns in .remote.ts files."
---

# SvelteKit Remote Functions

## Quick Start

**File naming:** `*.remote.ts` for remote function files

**Which function?** One-time action → `command()` | Repeated reads →
`query()` | Forms → `form()`

## Example

```typescript
// actions.remote.ts
import { command } from "$app/server";
import * as v from "valibot";

export const delete_user = command(
  v.object({ id: v.string() }),
  async ({ id }) => {
    await db.users.delete(id);
    return { success: true };
  },
);

// Call from client: await delete_user({ id: '123' });
```

## Reference Files

- [references/remote-functions.md](references/remote-functions.md) -
  Complete guide with all patterns

## Notes

- Remote functions execute on server when called from browser
- Args/returns must be JSON-serializable (RegExp is **forbidden** — throws)
- Schema validation via StandardSchemaV1 (Valibot/Zod)
- `getRequestEvent()` available for cookies/headers access
- **In components:** No-param `query()` works with `{#await}`. Parameterized queries with `$derived` return Query objects — use `.ready`/`.current` or `$derived(await ...)` with experimental async
- **Reactive context required:** `.current`/`.error`/`.loading`/`.ready` only work in reactive contexts (component top-level, `$derived`, `$effect`). Outside (event handlers, universal `load`), use `.run()` instead
- **Hydration:** Queries rendered during hydration must also render on server. Use `onMount` for client-only queries, not `browser` guards
- **Warning:** `<svelte:boundary>` + `{@const await}` causes infinite navigation loops with shared queries ([sveltejs/svelte#17717](https://github.com/sveltejs/svelte/issues/17717))
- **Single-flight mutations:** `.updates()` accepts query functions (`getPosts`) or instances. Server must opt-in via `requested()` from `$app/server`
- **Refresh queries:** Call `query().refresh()` - updates without flicker. No-op if no cached instance
- **Polling safety:** Always `.catch()` on `query().refresh()` in intervals — errors reject the Promise and evict the query from cache
- **Server handlers:** Use `void` (not `await`) for `.refresh()` inside command/form handlers
- **Cache keys:** Object property order doesn't matter for queries — keys are sorted alphabetically
- **Last verified:** 2026-04-06

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

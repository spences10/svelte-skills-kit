# svelte-skills-kit

Svelte 5 and SvelteKit skills marketplace for Claude Code.

## Quick Start

```bash
# 1. Add marketplace (one-time)
/plugin marketplace add spences10/svelte-skills-kit

# 2. Install plugin
/plugin install svelte-skills
```

> **Note:** Marketplace = catalog. Plugin = what you install from it.

## Skills Included

- **ecosystem-guide** - Tool selection for spences10's Claude Code ecosystem
- **layerchart-svelte5** - LayerChart patterns with Svelte 5 snippets
- **svelte-components** - Component patterns (Bits UI, Ark UI, Melt UI)
- **svelte-deployment** - Adapters, Vite config, pnpm, PWA
- **svelte-runes** - $state, $derived, $effect, migration
- **svelte-template-directives** - {@attach}, {@html}, {@render}, {@const}
- **sveltekit-data-flow** - Load functions, form actions
- **sveltekit-remote-functions** - command(), query(), form() patterns
- **sveltekit-structure** - Routing, layouts, error handling, SSR

## Ecosystem

Part of the [@spences10](https://github.com/spences10) Claude Code ecosystem:

| Repo                                                                    | Description                       |
| ----------------------------------------------------------------------- | --------------------------------- |
| [claude-code-toolkit](https://github.com/spences10/claude-code-toolkit) | Performance, productivity, skills |
| [mcp-omnisearch](https://github.com/spences10/mcp-omnisearch)           | Unified search MCP (Tavily, Kagi) |
| [mcp-sqlite-tools](https://github.com/spences10/mcp-sqlite-tools)       | Safe SQLite operations MCP        |
| [mcpick](https://github.com/spences10/mcpick)                           | Dynamic MCP server toggling       |
| [cclog](https://github.com/spences10/cclog)                             | Claude Code transcript → SQLite   |
| [claude-skills-cli](https://github.com/spences10/claude-skills-cli)     | CLI for creating skills           |

## Local Development

```bash
# Clone marketplace
git clone git@github.com:spences10/svelte-skills-kit.git ~/code/svelte-skills-kit

# 1. Add marketplace
/plugin marketplace add ~/code/svelte-skills-kit

# 2. Install plugin
/plugin install svelte-skills
```

**Note:** Plugin files are cached at `~/.claude/plugins/cache/`. After editing source files, reinstall or manually sync cache.

## Hooks

Three hook options in `plugins/svelte-skills/hooks/`:

- `skill-simple-instruction.sh` - Basic echo instruction
- `skill-activation-forced-eval.sh` - Enforces Evaluate→Activate→Implement
- `skill-activation-llm-eval.sh` - Smart matching via Claude API

**Important:** Hook commands must use `${CLAUDE_PLUGIN_ROOT}` for paths:

```json
"command": "${CLAUDE_PLUGIN_ROOT}/hooks/your-script.sh"
```

## Versioning

Bump `version` in `plugins/svelte-skills/.claude-plugin/plugin.json` on changes.

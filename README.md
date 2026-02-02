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

## Skills Ecosystem

Part of a connected suite of tools for Claude Code power users. These projects work together to give Claude Code persistent memory, better search, framework expertise, and self-improving skills.

### Skills & Plugins

Create, share, and use Claude Code skills with reliable activation.

| Project                                                                   | What it does                                                                  |
| ------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| [claude-code-toolkit](https://github.com/spences10/claude-code-toolkit)   | Performance plugins, productivity skills, and ecosystem guide                 |
| [svelte-skills-kit](https://github.com/spences10/svelte-skills-kit)       | Production-ready Svelte 5 & SvelteKit skills (90%+ verified accuracy)         |
| [claude-skills-cli](https://github.com/spences10/claude-skills-cli)       | Create skills with progressive disclosure validation and 84% activation hooks |
| [svelte-claude-skills](https://github.com/spences10/svelte-claude-skills) | Original Svelte skills collection - now consolidated into svelte-skills-kit   |

### MCP Servers & Tools

Extend Claude Code's capabilities with MCP servers for search, databases, and usage tracking.

| Project                                                           | What it does                                                          |
| ----------------------------------------------------------------- | --------------------------------------------------------------------- |
| [mcp-omnisearch](https://github.com/spences10/mcp-omnisearch)     | Unified search across Tavily, Brave, Kagi, Perplexity, and GitHub     |
| [mcp-sqlite-tools](https://github.com/spences10/mcp-sqlite-tools) | Safe SQLite operations with schema inspection and query building      |
| [mcpick](https://github.com/spences10/mcpick)                     | Toggle MCP servers on/off without restarting - reduce context bloat   |
| [ccrecall](https://github.com/spences10/ccrecall)                 | Sync Claude Code transcripts to SQLite for usage analytics and search |

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

# svelte-skills-kit

Svelte 5 and SvelteKit skills marketplace for Claude Code.

## Skills Included

- **project-context** - Ensures project patterns are consulted
- **research** - Verified source research
- **svelte-components** - Component patterns (Bits UI, Ark UI, Melt UI)
- **svelte-deployment** - Adapters, Vite config, pnpm, PWA
- **svelte-runes** - $state, $derived, $effect, migration
- **sveltekit-data-flow** - Load functions, form actions
- **sveltekit-remote-functions** - command(), query(), form() patterns
- **sveltekit-structure** - Routing, layouts, error handling, SSR

## Local Development

```bash
# Clone marketplace
git clone git@github.com:spences10/svelte-skills-kit.git ~/code/svelte-skills-kit

# Install plugin (creates cache)
/plugin marketplace add ~/code/svelte-skills-kit
/plugin install svelte-skills
```

**Note:** Plugin files are cached at `~/.claude/plugins/cache/`. After editing source files, reinstall or manually sync cache.

## Team Installation

```bash
/plugin marketplace add spences10/svelte-skills-kit
/plugin install svelte-skills
```

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

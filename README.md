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

# Symlink plugin for immediate use
ln -s ~/code/svelte-skills-kit/plugins/sveltekit ~/.claude/plugins/sveltekit
```

Edit in marketplace repo → changes work immediately → push when ready.

## Team Installation

```bash
/plugin marketplace add spences10/svelte-skills-kit
/plugin install sveltekit
```

## Hooks

Three hook options in `plugins/sveltekit/hooks/`:

- `skill-simple-instruction.sh` - Basic echo instruction
- `skill-activation-forced-eval.sh` - Enforces Evaluate→Activate→Implement
- `skill-activation-llm-eval.sh` - Smart matching via Claude API

## Versioning

Bump `version` in `plugins/sveltekit/.claude-plugin/plugin.json` on changes.

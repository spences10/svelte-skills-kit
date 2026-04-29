# svelte-skills-kit

Claude Code plugin marketplace wrapper for the Svelte skills from [spences10/skills](https://github.com/spences10/skills).

This repo distributes the Svelte subset for Claude Code users. For vendor-agnostic installs across compatible agents, use the canonical [spences10/skills](https://github.com/spences10/skills) repo.

## Quick Start

```bash
# 1. Add marketplace (one-time)
/plugin marketplace add spences10/svelte-skills-kit

# 2. Install plugin
/plugin install svelte-skills
```

## Universal Install Alternative

If you are not using Claude Code plugins, install directly from the vendor-agnostic canonical skills repo:

```bash
npx skills add spences10/skills --agent claude-code --skill svelte-runes
npx skills add spences10/skills --agent pi --skill svelte-runes
npx skills add spences10/skills --agent opencode --skill svelte-runes
```

## Skills Included

- **ecosystem-guide** - Tool selection for spences10's Claude Code ecosystem
- **svelte-components** - Component patterns (Bits UI, Ark UI, Melt UI)
- **svelte-deployment** - Adapters, Vite config, pnpm, PWA
- **svelte-layerchart** - LayerChart patterns for Svelte
- **svelte-runes** - `$state`, `$derived`, `$effect`, `$props`, `$bindable`
- **svelte-styling** - CSS patterns, `style:` directive, `:global`, custom properties
- **svelte-template-directives** - `{@attach}`, `{@html}`, `{@render}`, `{@const}`
- **sveltekit-data-flow** - Load functions, form actions
- **sveltekit-remote-functions** - `command()`, `query()`, `form()` patterns
- **sveltekit-structure** - Routing, layouts, error handling, SSR

## Sync From Canonical Repo

```bash
# from this repo
./scripts/sync-from-skills.sh

# or if the canonical repo is elsewhere
SKILLS_REPO=/path/to/skills ./scripts/sync-from-skills.sh
```

## Local Development

```bash
git clone https://github.com/spences10/svelte-skills-kit.git ~/code/svelte-skills-kit
cd ~/code/svelte-skills-kit

# Validate Claude Code plugin marketplace
claude plugin validate .

# Validate skill discovery
npx skills add . --list
```

**Note:** Plugin files are cached at `~/.claude/plugins/cache/`. After editing source files, reinstall or manually sync cache.

## Versioning

Bump `version` in `.claude-plugin/marketplace.json` and `plugins/svelte-skills/.claude-plugin/plugin.json` on changes.

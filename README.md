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

## Svelte Language Server

The `svelte-lsp` plugin connects Claude Code to the Svelte language server, so Claude gets type errors after editing `.svelte` files and can look up definitions, references and types in them. Claude Code has no official code intelligence plugin for Svelte.

The plugin is configuration only. Install the language server first and check it is on your `PATH`:

```bash
npm i -g svelte-language-server
which svelteserver
```

Then install the plugin and restart Claude Code:

```bash
/plugin marketplace add spences10/svelte-skills-kit
/plugin install svelte-lsp@svelte-skills-kit
```

It handles `.svelte` files only. For `.ts` and `.js` files, also install a TypeScript plugin: the official `typescript-lsp`, or the one below.

## TypeScript Language Server

The `typescript-lsp` plugin is the official `typescript-lsp` configuration with one option added:

```json
"initializationOptions": {
  "tsserver": { "useSyntaxServer": "never" }
}
```

With the official plugin, the first `findReferences` or `goToDefinition` call of a session can come back incomplete, with nothing to say so. `typescript-language-server` answers from a lightweight syntax server while the project is still loading, and that server only knows about the file it was asked about. Turning it off makes the first call wait for the project and return the full result. It is a workaround suggested by the [language server's maintainer](https://github.com/typescript-language-server/typescript-language-server/discussions/1067) for the Claude Code bug tracked in [anthropics/claude-code#76870](https://github.com/anthropics/claude-code/issues/76870).

The trade-off is that the first call is slower, because it waits for the project to load.

Install the language server first:

```bash
npm i -g typescript-language-server typescript
which typescript-language-server
```

Then install the plugin, disable the official one so two servers do not both handle `.ts` files, and restart Claude Code:

```bash
/plugin install typescript-lsp@svelte-skills-kit
/plugin disable typescript-lsp@claude-plugins-official
```

It works in any TypeScript or JavaScript project, not only Svelte ones.

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

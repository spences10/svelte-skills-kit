---
name: ecosystem-guide
description: "Guide to spences10's Claude Code ecosystem tools. Use when user asks which tool to use, how tools relate, or needs help choosing between MCP servers, skills, or CLIs."
---

# Claude Code Ecosystem Guide

A curated set of tools for enhanced Claude Code workflows.

## The Stack

| Tool                  | Type   | Purpose                                                      |
| --------------------- | ------ | ------------------------------------------------------------ |
| **toolkit-skills**    | Plugin | Forced-eval hook + core skills (pair with any skills plugin) |
| **svelte-skills-kit** | Plugin | Svelte/SvelteKit skills (pair with toolkit-skills)           |
| **ccrecall**          | CLI    | Sync transcripts → SQLite for analytics                      |
| **mcp-omnisearch**    | MCP    | Unified search (Tavily, Kagi, GitHub, etc.)                  |
| **mcp-sqlite-tools**  | MCP    | Safe SQLite operations                                       |
| **mcpick**            | CLI    | Manage MCP servers, plugins, cache, and profiles             |
| **research**          | Skill  | Verified source research patterns                            |
| **skill-creator**     | Skill  | Create Claude skills with best practices                     |

## Decision Tree

### "I want skills to activate reliably"

→ **toolkit-skills** - Forced-eval hook evaluates every prompt against available skills. Install alongside any skills plugin.

### "I need to search the web"

→ **mcp-omnisearch** - Web search, GitHub code search, AI answers

### "I need to query a database"

→ **mcp-sqlite-tools** - Read/write SQLite with safety guards

### "I have too many MCPs eating context"

→ **mcpick** - Enable/disable servers per-project

### "I need to install or update plugins"

→ **mcpick** - `mcpick plugins install|update|list`

### "My plugin cache is stale after a version bump"

→ **mcpick** - `mcpick cache clear` or `mcpick cache clean-orphaned`

### "I want to track my Claude Code usage"

→ **ccrecall** - Sync transcripts, query with mcp-sqlite-tools

### "I'm building with Svelte/SvelteKit"

→ **svelte-skills-kit** - Runes, routing, data flow patterns

### "I need to research a topic or verify sources"

→ **research skill** - Verified source research, repo cloning patterns

### "I want to create a new Claude skill"

→ **skill-creator skill** - Progressive disclosure, writing guide, CLI reference

## Typical Workflows

### Recommended Setup (Skills)

```bash
# Core: forced-eval hook + ecosystem skills
npx mcpick plugins install toolkit-skills@claude-code-toolkit

# Domain skills (optional, based on your stack)
npx mcpick plugins install svelte-skills@svelte-skills-kit

# Keep plugins up to date
npx mcpick plugins update toolkit-skills
```

toolkit-skills hook ensures skills from any plugin activate on relevant prompts.

### Add an MCP Server

```bash
npx mcpick add omnisearch -- npx -y mcp-omnisearch
```

### Research Mode

```bash
npx mcpick enable omnisearch
# Now Claude has web search, GitHub search, AI answers
```

### Data Analysis Mode

```bash
npx mcpick enable sqlite-tools
# Query databases, analyze CSVs, manage data
```

### Minimal Context Mode

```bash
npx mcpick disable omnisearch sqlite-tools
# Just Claude Code core tools
```

### Fix Stale Plugin Cache

```bash
npx mcpick cache status          # Check what's stale
npx mcpick cache clear           # Clear and refresh
npx mcpick cache clean-orphaned  # Remove old versions
```

### Save/Load Profiles

```bash
npx mcpick profile save research-mode
npx mcpick profile load research-mode
```

### Analytics Review

```bash
bun x ccrecall sync  # Update database
# Then query ~/.claude/ccrecall.db with mcp-sqlite-tools
```

## Links

| Tool                | GitHub                                           |
| ------------------- | ------------------------------------------------ |
| claude-code-toolkit | https://github.com/spences10/claude-code-toolkit |
| svelte-skills-kit   | https://github.com/spences10/svelte-skills-kit   |
| ccrecall            | https://github.com/spences10/ccrecall            |
| mcp-omnisearch      | https://github.com/spences10/mcp-omnisearch      |
| mcp-sqlite-tools    | https://github.com/spences10/mcp-sqlite-tools    |
| mcpick              | https://github.com/spences10/mcpick              |

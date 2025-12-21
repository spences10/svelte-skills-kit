# Repo Cloning Pattern

For library/framework research, clone source repos to get authoritative, current information.

## When to Use

- Questions about library internals/implementation
- Undocumented behavior
- Checking actual source vs docs
- Framework patterns not covered in official docs

## Pattern: Subagent Clone Research

**Always delegate to subagent to avoid context pollution.**

```
Task(subagent_type=Explore) →
  1. git clone --depth 1 <repo> /tmp/research-<name>
  2. Glob/Grep for relevant patterns
  3. Read key files
  4. Return distilled findings
  5. rm -rf /tmp/research-<name>
```

## Example Prompt for Subagent

```
Clone https://github.com/sveltejs/svelte to /tmp/research-svelte
Find how $effect() cleanup works internally.
Search for cleanup patterns in src/
Read relevant implementation files
Summarize findings
Delete clone when done
```

## Key Points

- Use `--depth 1` for speed (no history needed)
- Clone to `/tmp/` for auto-cleanup on reboot
- Always cleanup after: `rm -rf /tmp/research-*`
- Subagent keeps main context clean
- Return only essential findings, not full file contents

## Anti-Patterns

- Cloning in main context (trashes context)
- Full clone with history (slow, unnecessary)
- Leaving clones around (disk clutter)
- Dumping entire files back to main context

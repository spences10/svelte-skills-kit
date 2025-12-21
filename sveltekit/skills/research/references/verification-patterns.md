# Verification Patterns

Detailed patterns for verifying sources during research.

## Pattern 1: URL Research

When given a URL to research:

1. Use WebFetch to get the actual content
2. Read the complete relevant sections
3. Don't rely on summaries or snippets
4. Quote specific passages that support claims
5. Cite exact URLs

**Example:**

```
User: "Research this article about MCP performance"

WRONG approach:
- Search for article
- Present snippet results
- Make claims based on title

RIGHT approach:
- WebFetch the URL
- Read full content
- Search for performance mentions
- Quote specific data/claims
- If no performance data exists, say so
```

## Pattern 2: Official Sources

When asked to "use official sources":

1. Search for official documentation
2. **Fetch the actual pages** (don't trust search snippets)
3. Read relevant sections completely
4. Quote specific parts
5. Cite exact URLs for each claim

## Pattern 3: Questionable Claims

When something seems questionable:

- Fetch the original source
- Compare snippet/summary to actual content
- Call out discrepancies explicitly
- Say "I couldn't verify this" if sources don't support

## Anti-Patterns

Never do these:

❌ Presenting search snippets as facts without verification
❌ Trusting summaries without checking original sources
❌ Citing sources you haven't actually read
❌ Assuming snippets accurately represent full content
❌ Making confident claims based on titles alone

## When To Admit Uncertainty

If you can't verify because:
- Source is behind paywall/404
- Content doesn't support the claim
- Multiple sources contradict

**Say so explicitly.** Better to admit uncertainty than present unverified info.

## Detailed Examples

### Example 1: Security Documentation

User: "Research how Claude Code handles bash security"

Process:
1. Search for official Claude Code security docs
2. **Fetch the actual documentation pages**
3. Read security sections completely
4. Extract specific quotes about bash handling
5. Present findings with exact citations and line references

Not: Just present search result snippets

### Example 2: Technical Article

User: "Study this article and tell me what it says about overhead"

Process:
1. **Fetch the actual article content**
2. Search for mentions of "overhead", "performance"
3. Read those sections in full context
4. Quote specific passages
5. If article doesn't mention overhead, say "The article doesn't actually discuss overhead"

Not: Assume what it says based on title/snippet

### Example 3: Contradictory Sources

User: "Research whether MCP tools are faster than CLI"

Process:
1. Search for relevant sources
2. **Fetch multiple actual sources**
3. Compare what they actually say
4. If they contradict, present both views with quotes
5. Explain the contradiction explicitly
6. Don't pick one without evidence

Not: Present the first search result as truth

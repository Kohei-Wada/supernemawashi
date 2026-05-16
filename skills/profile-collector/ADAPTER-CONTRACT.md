# Adapter File Contract

Each `*.md` file in the `adapters/` directory defines one data-source adapter for profile-collector. To add a new adapter, create a file following this template:

```markdown
---
adapter: [name]
output_tag: [tag used in facts.md, e.g. slack]
identifiers: [list of subject identifiers this adapter accepts, e.g. email, handle, display_name]
---

# Adapter: [Name]

## Purpose
[1-2 sentences: what this source contributes to a profile]

## MCP Tools Required
- [tool name] — [what it is used for]
...

If any required tool is unavailable in this session, skip this adapter.

## Collection Recipe
[Numbered steps for searching and reading data about the target person]

## Fact Extraction
[What signals to record, the URL format if any, and how to format the facts.md line]

## Pitfalls
[Common gotchas, accounts to filter out, rate-limit considerations]
```

**Required fields:** All sections above are mandatory. The `output_tag` value is what appears inside `[...]` for entries this adapter contributes to facts.md (e.g. `- [2026-03-27] [slack] ...`). The `identifiers` field tells the collector which subject fields the adapter can search by — the collector skips adapters whose identifiers it cannot resolve for the target.

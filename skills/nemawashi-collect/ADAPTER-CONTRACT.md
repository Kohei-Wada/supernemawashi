# Adapter File Contract

Each `*.md` file in the `adapters/` directory defines one data-source adapter for nemawashi-collect. To add a new adapter, create a file following this template:

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
[Numbered steps for searching and reading data about the target person — used by nemawashi-collect]

## Fact Extraction
[What signals to record, the URL format if any, and how to format the facts.md line]

## Discovery Recipe
[Numbered steps for scanning the source to find unprofiled people the user interacts with — used by nemawashi-discover. Optional; omit when the source has no person-discovery shape.]

## Pitfalls
[Common gotchas, accounts to filter out, rate-limit considerations]
```

**Required fields:** All sections above are mandatory **except `## Discovery Recipe`**, which is optional. The `output_tag` value is what appears inside `[...]` for entries this adapter contributes to facts.md (e.g. `- [2026-03-27] [slack] ...`). The `identifiers` field tells the collector which subject fields the adapter can search by — the collector skips adapters whose identifiers it cannot resolve for the target.

**Consumers:** The same adapter file is read by both `nemawashi-collect` (Collection Recipe) and `nemawashi-discover` (Discovery Recipe). Source-specific knowledge (MCP tools, identifiers, pitfalls) lives once, in one place.

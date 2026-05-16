---
adapter: github
output_tag: github
identifiers: [github_login, email]
---

# Adapter: GitHub

## Purpose
Captures code-collaboration style: PR review tone, approval/rejection patterns, comment depth, authored PR scope, commit message discipline.

## MCP Tools Required
- `gh` CLI (preferred), OR a GitHub MCP server if installed (e.g. `mcp__github__*`)

If neither is available, skip this adapter.

## Collection Recipe
1. Resolve the target's GitHub login.
2. List PRs they authored: `gh pr list --author <login> --state all --limit 20`.
3. List PRs they reviewed: `gh search prs --reviewed-by <login> --limit 20`.
4. For interesting PRs, fetch reviews: `gh pr view <num> --json reviews,comments`.

## Fact Extraction
Signals worth capturing:
- Review tone (terse "lgtm" vs. detailed line-by-line vs. nitpicky)
- Approval willingness (rubber-stamper vs. blocker)
- PR scope authored (large refactors vs. tiny fixes)
- Commit message discipline (one-liners vs. structured)

`facts.md` line format:

```
- [YYYY-MM-DD] [github] <observable behavior> (https://github.com/<owner>/<repo>/pull/<num>)
```

## Discovery Recipe
Used by profile-discovery to find unprofiled people the user interacts with.

1. List the user's recent PRs / reviews / issue comments across their org/repos within the scan window (default 14 days).
   - `gh search prs --author @me --updated ">=YYYY-MM-DD" --limit 50`
   - `gh search prs --reviewed-by @me --updated ">=YYYY-MM-DD" --limit 50`
2. Extract co-authors, reviewers, and commenters from those PRs/issues.
3. Exclude the user themselves and bots (dependabot, copilot, CI bots).
4. Count interactions per login.
5. Return a list of `{github_login, display_name, interaction_count}` records.

## Pitfalls
- **Permissions**: only access repos the user has permission for. `gh` and the MCP enforce this.
- **Sampling bias**: PRs from a single intense project will skew tone. Sample across repos when possible.
- **Bot reviews**: dependabot, copilot, CI bots can show up as reviewers — filter them out.

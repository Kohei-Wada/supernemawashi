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

Append one JSONL record per signal to `<profile-dir>/facts.jsonl` following the canonical schema in `../FACTS-SCHEMA.md`. Use `source: "github"`. GitHub-specific optional field: `repository` (as `owner/repo`).

Example:

```jsonl
{"date":"2026-03-28","source":"github","content":"<observable behavior>","url":"https://github.com/<owner>/<repo>/pull/<num>","repository":"<owner>/<repo>"}
```

Never modify a pre-existing `facts.md` — new entries always go to `facts.jsonl`.

## Discovery Recipe
Used by nemawashi-discover to find unprofiled people the user interacts with.

### Pre-Check (solo-repo detection)

Many users work mostly on solo repos where reviewers are dominated by bots (dependabot, github-actions, copilot, amazon-q-developer, renovate, etc.). For them, the full recipe spends ~100s of wall-clock time fetching per-PR review data only to filter everything out as bots. Run this cheap probe first and abort early when that is the case.

1. List the operator's recent PRs:
   - `gh search prs --author "@me" --updated ">=YYYY-MM-DD" --limit 20 --json number,repository`
2. Sample 3-5 of the returned PRs and fetch their reviewers:
   - `gh pr view <owner>/<repo>#<num> --json reviews`
3. Classify each reviewer login as bot or human. A login counts as a bot if it ends in `[bot]` or matches the known list: `dependabot`, `github-actions`, `copilot`, `amazon-q-developer`, `renovate`.
4. **Abort the adapter and return an empty list if either:**
   - ≥ 90 % of the sampled reviewers are bots, OR
   - none of the sampled PRs have any reviewers at all.

   In the final report to nemawashi-discover, note: "GitHub: no human collaborators detected, adapter skipped (probe-based)."

The pre-check is intentionally inline (no cached marker) — 4-6 API calls per discover run, negligible compared to the full recipe it gates. A persistent skip-marker with expiry is tracked as a follow-up.

### Full Recipe

1. List the user's recent PRs / reviews / issue comments across their org/repos within the scan window (default 14 days).
   - `gh search prs --author @me --updated ">=YYYY-MM-DD" --limit 50`
   - `gh search prs --reviewed-by @me --updated ">=YYYY-MM-DD" --limit 50`
2. Extract co-authors, reviewers, and commenters from those PRs/issues.
3. Exclude the user themselves and bots, using the same bot-classification rule as the Pre-Check (logins ending in `[bot]` plus the known list above).
4. Count interactions per login.
5. Return a list of `{github_login, display_name, interaction_count}` records.

## Identity Resolution
Used by the identity cache (`.identity.md`) to record the user's own GitHub identifiers once per refresh cycle.

1. Call `gh api user` (or equivalent MCP user-lookup) — returns `login`, `email`, `name`.
2. Record `login` (= GitHub handle, used in `@me` queries and `--author` filters) and `email` (commit email, may differ from primary work email).

Output (written to the `## github` section of `.identity.md`):

```
- login: <login>
- email: <email>
```

## Pitfalls
- **Permissions**: only access repos the user has permission for. `gh` and the MCP enforce this.
- **Sampling bias**: PRs from a single intense project will skew tone. Sample across repos when possible.
- **Bot reviews**: dependabot, copilot, CI bots can show up as reviewers — filter them out.

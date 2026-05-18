---
name: nemawashi-check
description: Use when user wants to check which profiles need re-analysis - scans all profiles for staleness and new unanalyzed data
---

# Profile Freshness

Check analysis staleness across all profiles and triage which ones need re-analysis.

## When to Use

- User says "check profiles", "which profiles are stale?", "who needs re-analysis?"
- User says "profile status" or "freshness check"

## Process

### Step 1: Scan Profiles

1. List all directories in `PROFILE_DIR/`
2. For each profile directory, read `profile.md` and extract the `<!-- analyzed: YYYY-MM-DD, facts_count: N -->` HTML comment
3. Read `facts.md` and count the actual number of fact entries (lines matching the pattern `- [YYYY-MM-DD] [source]`)
4. Record: profile name, last analyzed date, analyzed facts count, current facts count

If a profile has no `<!-- analyzed: -->` comment, mark it as "Never Analyzed."

### Step 2: Classify

Classify each profile into one of four categories:

| Category | Criteria | Priority |
|----------|----------|----------|
| **Never Analyzed** | No `<!-- analyzed: -->` comment in profile.md | High |
| **Stale** | Last analyzed > 7 days ago OR current facts count > analyzed facts count | Medium |
| **Fresh** | Last analyzed within 7 days AND no new facts | Low (no action) |
| **No Data** | Profile has profile.md but no facts.md | None (run nemawashi-collect first) |

### Step 3: Present Dashboard

Display a dashboard table grouped by action needed:

```markdown
## Profile Freshness Dashboard

### Needs Re-analysis
| Profile | Last Analyzed | Days Ago | Facts (analyzed/current) | Reason |
|---------|--------------|----------|------------------------|--------|
| john | 2026-03-15 | 13 | 8 → 15 | Stale + new facts |
| alice | never | — | 0 → 6 | Never analyzed |
| bob | 2026-03-20 | 8 | 10 → 10 | Stale (>7 days) |

### Up to Date
| Profile | Last Analyzed | Days Ago | Facts |
|---------|--------------|----------|-------|
| carol | 2026-03-27 | 1 | 12 |

Summary: 3 need re-analysis, 1 up to date
```

After the dashboard, prompt:
> "Re-analyze stale profiles? (e.g., 'yes' for all, 'john only', or 'no')"

### Step 4: Re-analyze (Optional)

If the user selects profiles to re-analyze, dispatch parallel agents — one per profile — each invoking `nemawashi-analyze`. nemawashi-analyze is local-file-only (no MCP calls), so parallelism is unconstrained.

After all agents return, show an updated dashboard summary.

## Edge Cases

- **No profiles exist**: Report that no profiles were found. Suggest running nemawashi-collect or nemawashi-discover first.
- **All profiles fresh**: Report that everything is up to date. No action needed.
- **Profile has profile.md but no facts.md**: Mark as "No data collected — run nemawashi-collect first." Do not suggest re-analysis.
- **Analyzed comment exists but is malformed**: Treat as "Never Analyzed" and note the parsing issue.

## Key Principles

- **Read-only by default** — This skill only reads and reports. Re-analysis happens only when the user explicitly requests it.
- **Actionable output** — The dashboard should make it immediately clear what needs attention and why.
- **Parallel re-analysis** — When the user opts in, dispatch one agent per stale profile in parallel.

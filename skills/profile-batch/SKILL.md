---
name: profile-batch
description: Use when user wants to bulk collect, analyze, or update multiple profiles at once - runs collector and/or analyzer across all or selected profiles
---

# Profile Batch

Perform bulk profile collection and analysis across all tracked people.

## Variables

- `PROFILE_DIR` = `~/.local/share/supernemawashi/profiles`

## When to Use

- User says "update all profiles", "batch update", "re-analyze everyone"
- User says "collect everyone" or "analyze all"
- User says "update stale profiles" or "re-analyze stale ones"

## Process

### Step 1: Determine Mode

Infer the mode from the user's request:

| Mode | Trigger | What it does |
|------|---------|-------------|
| `all` | "update all", "batch update" | Run collector then analyzer for every profile |
| `collect` | "collect everyone", "batch collect" | Run collector only for every profile |
| `analyze` | "analyze everyone", "batch analyze" | Run analyzer only for every profile |
| `auto` | "update stale", "re-analyze stale" | Use profile-freshness to find Stale/Never Analyzed profiles, then run analyzer (and optionally collector) for those only |

If ambiguous, ask the user which mode they want.

### Step 2: Triage

**For `auto` mode:**
1. Invoke `profile-freshness` to get the dashboard
2. Collect the list of profiles with status `Stale` or `Never Analyzed`
3. Present the list to the user for confirmation before proceeding
4. User can select all, specific profiles, or cancel

**For `all` / `collect` / `analyze` modes:**
1. List all directories in `PROFILE_DIR/`
2. Skip directories with no `profile.md` (empty profiles)
3. Present the list and total count to the user for confirmation

### Step 3: Execute

For each target profile, run the appropriate skills sequentially:

**`all` mode:** profile-collector → profile-analyzer (per person)
**`collect` mode:** profile-collector only
**`analyze` mode:** profile-analyzer only
**`auto` mode:** profile-analyzer only (collector is optional — ask the user if they also want fresh data collection before re-analysis)

After each person completes, report progress:
> "Completed 3/8: alice (collected + analyzed)"

### Step 4: Summary

After all profiles are processed, present a summary:

```markdown
## Batch Complete

| Status | Count | Profiles |
|--------|-------|----------|
| Success | 6 | alice, bob, carol, dave, eve, frank |
| Skipped | 1 | grace (no facts.md — run collector first) |
| Error | 1 | john (collector failed — Slack MCP unavailable) |

Total: 8 profiles processed
```

## Edge Cases

- **No profiles exist**: Report that no profiles were found. Suggest running profile-discovery first.
- **All profiles fresh** (auto mode): Report that everything is up to date. No action needed.
- **MCP source unavailable during collection**: Log the error for that profile, continue with the next. Include in the summary.
- **User cancels mid-batch**: Stop processing. Report what was completed so far.

## Key Principles

- **User confirms before execution** — Always show the target list and get confirmation before starting the batch.
- **Sequential, not parallel** — Process one profile at a time to avoid MCP rate limits and keep progress clear. If the user explicitly requests parallel execution, use agent dispatch.
- **Resume-friendly** — Report progress after each profile so the user knows where things stand if interrupted.
- **Leverage existing skills** — This skill orchestrates profile-collector, profile-analyzer, and profile-freshness. It does not duplicate their logic.

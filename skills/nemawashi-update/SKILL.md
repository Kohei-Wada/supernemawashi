---
name: nemawashi-update
description: Use when user wants to refresh one or more profiles end-to-end - runs nemawashi-collect followed by nemawashi-analyze for each named target (or --all), dispatching one profile-updater agent per target with throttled parallelism.
---

# Profile Updater

End-to-end profile refresh — runs `nemawashi-collect` followed by `nemawashi-analyze` for each named target in a single invocation. The two-step pipeline (collect → analyze) is the common case; this skill is the convenience wrapper that dispatches one `profile-updater` agent per target, batched to respect MCP rate limits.

The individual skills remain available for the cases where they don't compose — re-analyzing without re-collecting, or seeding a profile for a brand-new person who needs the interactive collect dialog.

## When to Use

- User says "update X's profile" / "refresh X" / "X を update して"
- User says "update everyone" / "全員 update" / explicit `--all`
- User has multiple targets to refresh (this skill parallelizes them; invoking the two underlying skills sequentially serializes everything)

## Prerequisites

- The underlying skills' prerequisites: at least one MCP source available for `nemawashi-collect`; `skills/nemawashi-analyze/FRAMEWORKS.md` registry intact for `nemawashi-analyze`.
- For `--all`, at least one existing profile under `PROFILE_DIR/`.

## Surface

```
nemawashi-update <name>                    # single target
nemawashi-update <a> <b> <c>               # multiple targets
nemawashi-update --all                     # every profile under PROFILE_DIR
```

Empty invocation (no positional, no `--all`) → print usage and stop.

## Process

### Step 1: Parse targets

Resolve the target list:

- Positional arguments → each is one target name (matches a directory under `PROFILE_DIR/`, or a new name to be created by the nested collect step).
- `--all` → list `${PROFILE_DIR}/*/` and use each basename as a target. If the directory is empty (no profiles yet), print:
  > "No profiles under `PROFILE_DIR`; run `/supernemawashi:nemawashi-collect <name>` to seed one first."
  and stop.

`--all` is **eager** — no `"Update N people, proceed?"` confirmation. The user has full Ctrl-C to abort.

### Step 2: Dispatch profile-updater agents

For each target, build the dispatch prompt:

```
profile_name:    <slug>
profile_dir:     ${PROFILE_DIR}/<slug>/
today:           <YYYY-MM-DD>
```

Issue dispatches **in batches of 5 concurrent agents**. Wait for the batch to return before dispatching the next batch. This top-level throttle is what keeps the nested `profile-collector` dispatches under the documented MCP rate-limit batch size (the local-only `framework-analyzer` fan-out inside each profile-updater is not the bottleneck).

For a single target (`N=1`), dispatch one agent and skip the batching logic. For `N ≤ 5`, all in one batch.

### Step 3: Aggregate per-target reports

After every batch returns, collect the per-target report blocks. Each is one of:

```
<profile_name>: success
  collect: <facts_added N from M adapters>
  analyze: <produced N framework files; core pattern: "<one-line>"; contradictions: <count>>
```

```
<profile_name>: partial
  collect: <ran, no facts gathered | facts_added N from M adapters>
  analyze: <skipped | produced N framework files with K Data Gap>
```

```
<profile_name>: failed
  collect: <reason>
  analyze: skipped
```

### Step 4: Print summary

Print a final aggregated table:

```
| Target | Status | Notes |
|---|---|---|
| <name> | success | <one-line summary from the report> |
| <name> | partial | <reason> |
| <name> | failed  | <reason> |
```

Followed by a one-line totals row: `Total: N successful, M partial, K failed.`

If any target failed or was partial, suggest follow-up actions:

- `failed (collect)` → "Check MCP authentication; try `/supernemawashi:nemawashi-collect <name>` directly to see the interactive error."
- `partial (no facts)` → "No new signals from any MCP source — the target may be a stale identifier."

## Key Principles

- **Compose, don't reinvent.** This skill never duplicates collect or analyze logic; both flow through their canonical worker agents.
- **Throttle at the top.** The 5-batch cap is the only place rate limits are enforced; nested agents do not retry or back off.
- **Failures are local.** One target's failure must not block the others.
- **Eager `--all`.** Confirmation is the user's responsibility (Ctrl-C); the skill optimizes for the common "yes, just run it" path.

## Coexistence with other skills

- `nemawashi-collect` — still the right tool when you want the interactive create-a-new-profile dialog or when MCP is the only thing that needs to run.
- `nemawashi-analyze` — still the right tool for re-analysis without re-collection (cheap; no MCP calls).
- `nemawashi-discover` — runs before this skill when you don't yet know who to update. Discovery cache (#1) will short-circuit the nested collect when implemented.
- `nemawashi-check` — runs before this skill when you want to refresh only stale profiles. Pipe its output (or hand-pick) into this skill's positional args.

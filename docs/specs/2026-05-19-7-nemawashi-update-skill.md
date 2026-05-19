# `nemawashi-update` — Design Spec

**Issue:** #7
**Date:** 2026-05-19
**Status:** Approved (brainstorming)

## Goal

A convenience skill that runs the full profile refresh pipeline (`nemawashi-collect` → `nemawashi-analyze`) for one or more targets in a single invocation. Eliminates the friction of "always two skills" for the common "update this person's profile end-to-end" case without touching the underlying skills.

## Scope

**In scope:**

- New skill `skills/nemawashi-update/SKILL.md` accepting positional target names or `--all`.
- New agent `agents/profile-updater.md` that runs the full pipeline for ONE target.
- Per-target parallel dispatch, top-level throttle at 5 concurrent (so MCP rate limits in the nested collect phase are not exceeded).
- Per-target reports aggregated by the top-level skill: `success | partial(collect-only) | failed(<reason>)`.

**Out of scope (v1):**

- Modifying `nemawashi-collect` or `nemawashi-analyze`. Composition only.
- Integrating with `nemawashi-discover` (perf cache for back-to-back discover→update is #1's territory).
- Per-target user prompts. `--all` is eager — no `"Update N people, proceed?"` confirmation.
- A `--dry-run` / preview mode. Underlying skills don't have one.
- A `--analyze-only` / `--collect-only` mode. Users invoke the underlying skill directly for that case.

## Architecture

**Pattern:** top-level fan-out with throttled batching; per-target agent that composes existing primitives.

```
nemawashi-update (skill, main session)
  ├── parse targets
  ├── dispatch profile-updater (agent) × N, batched 5 at a time
  │     ├── dispatch profile-collector (agent) for this one target — MCP-heavy
  │     ├── read shared analyze inputs (facts.jsonl, profile.md, etc.)
  │     ├── dispatch framework-analyzer (agent) per FRAMEWORKS.md row — local-only
  │     └── synthesize profile.md / contradictions.md / relationship.md per OUTPUT-FORMAT.md
  └── aggregate per-target reports
```

The throttle invariant: because the top-level skill caps at 5 concurrent `profile-updater` agents, the nested `profile-collector` dispatches are also capped at 5 — matching the documented MCP rate-limit batch size. The local-only `framework-analyzer` fan-out (~6 per profile) is unconstrained; migration `03-frameworks-split` already proved 7 × 6 = 42 concurrent analyzers work fine.

## Surface

```
/nemawashi-update <name>                  # single target
/nemawashi-update <a> <b> <c>             # multiple
/nemawashi-update --all                   # everyone under PROFILE_DIR
```

Empty invocation (no positional, no `--all`) → error with usage. No interactive target picker — the skill is for explicit targets only.

Edge cases:

- `--all` on an empty `PROFILE_DIR` (no profiles exist yet) → message "No profiles under `PROFILE_DIR`; run `nemawashi-collect <name>` to seed one first." Stop without dispatching.
- A positional name that doesn't match any existing `PROFILE_DIR/<name>/` directory → `profile-updater` is still dispatched; the nested `profile-collector` creates the profile from scratch (matches `nemawashi-collect`'s create-or-update behavior).

## Agent contract (`profile-updater`)

**Input per dispatch:**

- `profile_name` — directory name under `PROFILE_DIR`
- `profile_dir` — absolute path to `PROFILE_DIR/<name>/`
- `today` — YYYY-MM-DD

**Behavior (per target):**

1. Dispatch `profile-collector` for the target. Wait. If collect surfaces a fatal error (no MCP adapters usable, target identifier unresolvable), return `failed(<reason>)` and stop.
2. Verify `facts.jsonl` exists and is non-empty after collect. If still empty → return `partial(collect ran, no facts gathered)` and stop.
3. Read shared analyze inputs: `profile.md`, `facts.jsonl`, `relationship.md` (if present).
4. Dispatch one `framework-analyzer` agent per row in `skills/nemawashi-analyze/FRAMEWORKS.md`, in parallel. Wait for all.
5. Synthesize the analyze outputs per `OUTPUT-FORMAT.md`:
   - `profile.md` — preserve manual sections, regenerate Core Pattern + Framework Summary.
   - `contradictions.md` — cross-framework synthesis.
   - `relationship.md` — Approach Strategy section, if `relationship.md` exists.
6. Return per-target report.

**Report shape:**

```
<profile_name>: <status>
  collect:  <added N facts | no new facts | failed: <reason>>
  analyze:  <produced N framework files | skipped: <reason>>
```

Where `<status>` is one of `success | partial | failed`.

## Failure handling

- A failure for one target NEVER blocks other targets — they are independent dispatches.
- Within a target, collect failure aborts the analyze phase for that target (no facts → nothing to analyze). The top-level report still surfaces the target with `failed(collect)`.
- The top-level skill prints a final aggregated table: which targets succeeded, which were partial, which failed.

## Acceptance

- `/nemawashi-update <name>` runs collect → analyze for one target, with per-phase reporting visible to the user.
- `/nemawashi-update <a> <b> <c>` dispatches three `profile-updater` agents in parallel, returns aggregated report.
- `/nemawashi-update --all` enumerates `PROFILE_DIR/*/`, dispatches one agent per target (batched 5), no confirmation prompt, aggregated report at the end.
- Underlying `nemawashi-collect` and `nemawashi-analyze` invocations remain unchanged — direct invocation paths still work.
- Failure of one target's analyze (e.g., empty `facts.jsonl`) is reported and does not block the others.
- The skill is wired into `using-supernemawashi/SKILL.md`'s skill table and routing block.

## Relationship to other issues

- Pairs with #1 (discovery cache). When the discovery cache lands, this skill's nested collects benefit transparently — no change required here.
- Pairs with #11 (`nemawashi-prune`). Both are composition skills around the existing profile lifecycle.
- Does not block, and is not blocked by, the temporal model (#41) — analyze already produces append-only jsonl as of v3.0.0.

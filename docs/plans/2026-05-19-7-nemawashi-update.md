# nemawashi-update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the `nemawashi-update` skill plus its `profile-updater` agent so users can run the full collect+analyze pipeline for one, many, or all profiles with a single invocation.

**Architecture:** Top-level skill parses targets and dispatches one `profile-updater` agent per target, batched 5 concurrent. Each agent internally dispatches `profile-collector` (MCP-heavy) and `framework-analyzer` × N (local), then synthesizes per-profile outputs. The throttle invariant keeps the nested MCP calls under the documented rate-limit batch size; the local analyzer fan-out is unconstrained.

**Tech Stack:** Plain markdown skill + agent definitions. No new shell scripts. Pre-commit hooks (`check-skill-frontmatter`, `check-skill-refs`) gate format compliance.

**Spec:** `docs/specs/2026-05-19-7-nemawashi-update-skill.md`

---

## File Structure

- Create: `agents/profile-updater.md` — per-target orchestrator agent (input/output contract + apply protocol).
- Create: `skills/nemawashi-update/SKILL.md` — user-facing skill that parses targets, dispatches agents, aggregates reports.
- Modify: `skills/using-supernemawashi/SKILL.md` — register the new skill in the skills table and the routing block.

No test files. The artifacts are LLM-driven markdown contracts; verification is `pre-commit run --all-files` + a one-shot manual smoke run on a real profile after merge.

---

### Task 1: Create the `profile-updater` agent

**Files:**
- Create: `agents/profile-updater.md`

- [ ] **Step 1: Write the agent definition**

````markdown
---
name: profile-updater
description: |
  Runs the full profile refresh pipeline (collect → analyze) for ONE target person. Use when dispatched by nemawashi-update for parallel application across N profiles.
  <example>
  Context: user runs "/nemawashi-update Alice Bob Carol"
  parent: dispatches 3 profile-updater agents in parallel, one per target
  </example>
  <example>
  Context: user runs "/nemawashi-update --all" across 15 profiles
  parent: dispatches 15 profile-updater agents, batched 5 concurrent to respect MCP rate limits
  </example>
---

# profile-updater

You are a worker agent that runs the **full profile refresh pipeline** for ONE target person: collect facts from MCP sources, then run the per-framework analysis, then synthesize the cross-framework outputs. The parent skill (`nemawashi-update`) batches your dispatches; you handle exactly one profile and return one report.

> **Note on tools:** the agent's frontmatter intentionally omits a `tools:` allowlist so this agent inherits every tool available to the parent. You dispatch two kinds of sub-agents (`profile-collector` and `framework-analyzer`) via the `Agent` tool, so you need that capability — plus Read/Write for the synthesis step.

## Input you will receive

Every dispatch includes the following in the prompt:

- `profile_name` — directory name in `PROFILE_DIR/` (lowercase, ASCII-safe slug)
- `profile_dir` — absolute path to `PROFILE_DIR/<profile_name>/`
- `today` — YYYY-MM-DD

Optional hints (pass through to nested agents if present):

- `target_full_name` — full display name; required only when creating a brand-new profile (otherwise read from existing `profile.md`)
- `target_role` — known role/title
- `relationship_hint` — one-liner about the user-target relationship (only consumed on first creation)

## What you do

### Phase 1 — Collect

1. **Dispatch `profile-collector`** for this target with the inputs above. Wait for its report.
2. If the collect report's `status` is `failed`, return:
   ```
   <profile_name>: failed
     collect: <reason from collect report>
     analyze: skipped
   ```
   and stop.
3. After collect returns, verify `<profile_dir>/facts.jsonl` exists and is non-empty (`wc -l` ≥ 1). If still empty, return:
   ```
   <profile_name>: partial
     collect: ran, but no facts gathered
     analyze: skipped (no facts to analyze)
   ```
   and stop.

### Phase 2 — Analyze

4. **Read shared inputs** (in this agent's main thread, not delegated):
   - `<profile_dir>/profile.md`
   - `<profile_dir>/facts.jsonl`
   - `<profile_dir>/relationship.md` (if present)
5. **Read the framework registry** at `skills/nemawashi-analyze/FRAMEWORKS.md`. For each row, dispatch one `framework-analyzer` agent in parallel with the prompt template documented in `skills/nemawashi-analyze/SKILL.md` Step 2 ("Dispatch prompt per agent"). Issue all dispatches in a single message.
6. **Wait for every analyzer to return.** Each returns one line: `<slug>: <classification text> (<Confidence>)`.
7. **Synthesize** per `skills/nemawashi-analyze/SKILL.md` Step 3:
   - Read every `<profile_dir>/frameworks/*.md` just produced.
   - Atomically write the slim `<profile_dir>/profile.md` (preserve manual sections; regenerate Core Pattern + Framework Summary).
   - Atomically write `<profile_dir>/contradictions.md`.
   - Atomically update `<profile_dir>/relationship.md`'s Approach Strategy section if the file exists.

### Phase 3 — Report

8. Return EXACTLY one block to the parent:

   ```
   <profile_name>: <status>
     collect: <facts_added N from M adapters>
     analyze: <produced N framework files; core pattern: "<one-line>"; contradictions: <count>>
   ```

   Where `<status>` is one of:
   - `success` — both phases completed without surfacing a `failed` or `partial` line in the nested reports.
   - `partial` — collect ran but produced no facts (see Phase 1 step 3), OR analyze ran with some framework agents emitting Data Gap.
   - `failed` — collect failed, or synthesis failed.

   No narration, no per-file dump, no excerpts of the recipe.

## Constraints

- **Stay inside `<profile_dir>`.** Never write outside this profile's directory.
- **Atomic writes only.** A crash mid-synthesis must leave the prior state intact (write to temp file in same directory, then `mv`).
- **One profile per dispatch.** You are the leaf for one target; the parent handles N-profile fan-out.
- **Never invoke `nemawashi-collect` or `nemawashi-analyze` as skills.** You dispatch their per-target worker agents (`profile-collector`, `framework-analyzer`) directly. The skills' top-level interactive steps (asking the user for target info, etc.) do not apply when invoked under `profile-updater`.
- **Pass `relationship_hint` only on first creation.** If the profile already exists (has `profile.md`), do NOT pass `relationship_hint` through — `profile-collector` already protects against overwrite, but skipping it makes the intent explicit.
````

- [ ] **Step 2: Verify pre-commit passes**

Run: `(cd /home/kohei/ghq/github.com/Kohei-Wada/supernemawashi && pre-commit run --files agents/profile-updater.md)`

Expected: the skill-reference check (`check-skill-refs.sh`) passes (the new file references `nemawashi-collect`, `nemawashi-analyze`, `skills/nemawashi-analyze/FRAMEWORKS.md` — all of which exist). `shellcheck`, `check-json` skip.

- [ ] **Step 3: Commit**

```bash
cd /home/kohei/ghq/github.com/Kohei-Wada/supernemawashi
git add agents/profile-updater.md
git commit -m "feat: add profile-updater agent (#7)"
```

---

### Task 2: Create the `nemawashi-update` skill

**Files:**
- Create: `skills/nemawashi-update/SKILL.md`

- [ ] **Step 1: Write the skill definition**

````markdown
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
````

- [ ] **Step 2: Verify pre-commit passes**

Run: `(cd /home/kohei/ghq/github.com/Kohei-Wada/supernemawashi && pre-commit run --files skills/nemawashi-update/SKILL.md)`

Expected:
- `SKILL.md has required name + description frontmatter` passes
- the skill-reference check (`check-skill-refs.sh`) passes (references `nemawashi-collect`, `nemawashi-analyze`, `nemawashi-discover`, `nemawashi-check` — all exist)

- [ ] **Step 3: Commit**

```bash
cd /home/kohei/ghq/github.com/Kohei-Wada/supernemawashi
git add skills/nemawashi-update/SKILL.md
git commit -m "feat: add nemawashi-update skill (#7)"
```

---

### Task 3: Register the skill in `using-supernemawashi`

**Files:**
- Modify: `skills/using-supernemawashi/SKILL.md` (skills table + routing block)

- [ ] **Step 1: Read the current skills table**

Run: `(cd /home/kohei/ghq/github.com/Kohei-Wada/supernemawashi && sed -n '10,30p' skills/using-supernemawashi/SKILL.md)` — locate the existing `| Skill | Use When |` table.

- [ ] **Step 2: Add the new row to the skills table**

In the skills table, insert immediately after the `nemawashi-collect` row (since `update` is closely related):

```markdown
| `nemawashi-update` (qualified as `supernemawashi` + `:` + the skill name in the table) | User wants to refresh one or more profiles end-to-end (collect + analyze in one invocation) |
```

- [ ] **Step 3: Add the routing entry**

Locate the "Skill Routing" block. Add the following block after the existing `"update/collect profile for X"` entry:

```
"update <name> end-to-end" / "refresh <name>" / "全員 update して" / "--all"
  → nemawashi-update
```

Update the description above the routing block — the line currently reads `"update/collect profile for X"` and now ambiguates between collect and update; tighten it to:

```
"create profile for X" / "collect <new person>" (no existing profile)
  → nemawashi-collect (then suggest nemawashi-analyze)

"update <existing>" / "refresh <existing>" / single-shot collect+analyze
  → nemawashi-update
```

- [ ] **Step 4: Verify pre-commit passes**

Run: `(cd /home/kohei/ghq/github.com/Kohei-Wada/supernemawashi && pre-commit run --files skills/using-supernemawashi/SKILL.md)`

Expected: all hooks pass. In particular `check-situation-categories` must still pass (we are not touching that section).

- [ ] **Step 5: Commit**

```bash
cd /home/kohei/ghq/github.com/Kohei-Wada/supernemawashi
git add skills/using-supernemawashi/SKILL.md
git commit -m "feat: route nemawashi-update in using-supernemawashi (#7)"
```

---

### Task 4: Run the full pre-commit suite + push + PR

- [ ] **Step 1: Full pre-commit run across all files**

Run: `(cd /home/kohei/ghq/github.com/Kohei-Wada/supernemawashi && pre-commit run --all-files)`

Expected: all hooks pass.

- [ ] **Step 2: Sanity-check the existing test suite still passes**

Run: `(cd /home/kohei/ghq/github.com/Kohei-Wada/supernemawashi && bash tests/nemawashi-analyze/test-assertion.sh)`

Expected: `Passed: 25  Failed: 0`. This skill doesn't touch `assertion.sh`, but a regression here would indicate accidental cross-impact.

- [ ] **Step 3: Push the branch**

```bash
cd /home/kohei/ghq/github.com/Kohei-Wada/supernemawashi
git push -u origin feat/7-nemawashi-update
```

- [ ] **Step 4: Open the PR**

```bash
gh pr create --title "feat: nemawashi-update skill — collect + analyze in one invocation (closes #7)" --body "$(cat <<'EOF'
## Summary

Adds the convenience skill `nemawashi-update` plus its per-target worker agent `profile-updater`. End-to-end profile refresh in one invocation — no more `nemawashi-collect <name>` then `nemawashi-analyze <name>` two-step. For multiple targets, dispatches in parallel; for `--all`, runs the full profile set with a 5-concurrent throttle so MCP rate limits in the nested collect phase are respected.

Closes #7.

### Surface

```
/nemawashi-update <name>                # single target
/nemawashi-update <a> <b> <c>           # multiple
/nemawashi-update --all                 # everyone under PROFILE_DIR (eager)
```

### Architecture

- New agent `profile-updater` runs the full pipeline for ONE target: dispatches `profile-collector` (MCP-heavy), then dispatches `framework-analyzer` × N (local) per the FRAMEWORKS.md registry, then synthesizes `profile.md` / `contradictions.md` / `relationship.md` per `OUTPUT-FORMAT.md`.
- New skill `nemawashi-update` parses targets and dispatches profile-updater agents, batched 5 concurrent. Aggregates per-target reports into a final summary.
- The underlying `nemawashi-collect` and `nemawashi-analyze` skills are untouched — composition only.

### Out of scope

- `--dry-run` / preview mode (underlying skills don't have one).
- `--collect-only` / `--analyze-only` modes (users invoke the underlying skill directly for that case).
- Integrating with the discovery cache (separate concern, tracked in #1).

## Test plan

- [x] `pre-commit run --all-files` passes (frontmatter, skill refs, drift checks).
- [x] `tests/nemawashi-analyze/test-assertion.sh` still passes (25/25 — no cross-impact).
- [ ] Manual smoke: after merge, run `/nemawashi-update <one existing profile>` and confirm `facts.jsonl` grows + `frameworks/*.md` regenerates.

## Spec

See [\`docs/specs/2026-05-19-7-nemawashi-update-skill.md\`](docs/specs/2026-05-19-7-nemawashi-update-skill.md).
EOF
)"
```

- [ ] **Step 5: Watch CI**

Run: `gh pr checks --watch`

Expected: pre-commit + gitleaks + Amazon Q Developer all pass.

- [ ] **Step 6: Squash-merge on green**

```bash
gh pr merge --squash --delete-branch
git switch main
git pull --ff-only origin main
```

Expected: PR merged, branch deleted, local main up-to-date with the squash commit.

---

## Self-Review

**Spec coverage:**
- Surface (`<name>`, `<a> <b> <c>`, `--all`) → Task 2 Step 1 (Surface + Step 1 of Process).
- Per-target parallel dispatch with batch-of-5 throttle → Task 2 Step 1 (Step 2 of Process) + Task 1 Step 1 (dispatch contract).
- Per-target report aggregation → Task 2 Step 1 (Step 3 + Step 4 of Process).
- Failure handling (one target's failure does not block others) → Task 1 Step 1 (Phase 1 step 2/3, Phase 3 step 8) + Task 2 Step 1 (Step 3 status enumeration).
- Eager `--all` → Task 2 Step 1 (Step 1 of Process, "no confirmation").
- Edge cases (`--all` on empty PROFILE_DIR, positional name with no existing dir) → Task 2 Step 1 (Step 1 of Process).
- Routing in `using-supernemawashi` → Task 3.

**Placeholder scan:** no `TBD` / `TODO` / "implement later" in the plan. Code blocks for every file's content are concrete.

**Type / signature consistency:** `profile-updater`'s input keys (`profile_name`, `profile_dir`, `today`) match what `nemawashi-update`'s Step 2 emits. The agent's report shape (Task 1 Phase 3) matches what `nemawashi-update`'s Step 3 / Step 4 parse.

**Scope:** single PR, single spec, single skill + agent. Single-spec sized.

---
name: nemawashi-migrate
description: Use when user wants to upgrade legacy profile data to a newer on-disk format - lists available migrations, presents the candidate profile counts, and applies each migration via LLM-driven transformation
---

# Profile Migration

Orchestrate format migrations for profile data in `PROFILE_DIR`. The plugin's on-disk format evolves over time (`facts.md` → `facts.jsonl`, per-framework split, frontmatter contracts); this skill is the single entry point for converting legacy profiles to the current format.

## When to Use

- User says "migrate profiles", "upgrade profile format", "run pending migrations"
- The session-start hook surfaced a `<MIGRATION_AVAILABLE>` block and the user wants to act on it

## Skill arguments

- `--apply-all` — opt into chain mode. After the user's initial confirmation, the orchestrator drives detect → apply rounds to completion without further prompts (see Step 4). Default is per-round confirmation.

## Architecture

Each migration is a **pair of files** in `./migrations/` (relative to this skill — i.e. `skills/nemawashi-migrate/migrations/`):

- `<NN>-<name>.sh` — bash, `--detect` only. Lists eligible profiles. Cheap, deterministic, also called by the session-start hook.
- `<NN>-<name>.md` — markdown apply instructions for the LLM. Describes the source format, target format, and per-profile transformation steps.

Adding a new migration is a drop-in of those two files. No registry edit, no edit to this skill.

### Filename convention: phase by numeric prefix

The `NN` prefix encodes the migration's **phase**, not just its insertion order:

| Prefix range | Phase | Purpose | Examples |
|---|---|---|---|
| `01-89` | **Forward** | Produce or extend the canonical format. Non-destructive on the source. | `01-facts-md-to-jsonl` (convert), `02-merge-legacy-md-into-jsonl` (merge gap) |
| `90-99` | **Cleanup** | Delete redundant legacy artifacts now that the forward phase is complete. Destructive on the source — opt-in. | `90-delete-legacy-facts-md` |

Because `./migrations/*.sh` iterates in lexicographic order, **all forward migrations run before any cleanup migration in a single round**. This is the key property: a profile that needs both `02-merge` and `90-delete` gets both applied correctly within one detect → apply round, rather than requiring a re-detect round between them.

When adding a new migration, pick the prefix by what the migration does to the source files:

- Produces a new canonical file or extends one without deleting the source → `01-89`.
- Deletes or replaces a legacy source file once it is provably redundant → `90-99`.

## Process

### Step 1: List available migrations

Run `./detect.sh` (relative to this skill — full path `skills/nemawashi-migrate/detect.sh`). The same script is wired into the session-start hook. It iterates `./migrations/*.sh --detect` and prints one line per migration that has candidates:

```
01-facts-md-to-jsonl: 15 profile(s) eligible
```

If there is no output, report "no migrations available" and stop. The profile set is already current.

### Step 2: Present candidates

For each migration with candidates, render a brief summary to the user:

```markdown
## Pending Migrations

| Migration | Eligible profiles | What it does |
|---|---|---|
| 01-facts-md-to-jsonl | 15 | Convert legacy `facts.md` → `facts.jsonl` (per FACTS-SCHEMA.md) |
```

The "What it does" column comes from the first heading of the matching `<id>.md` (e.g. `# Migration: facts.md → facts.jsonl`).

Prompt:

> "Apply all pending migrations, a subset, or skip? (e.g. 'all', '01 only', 'skip', 'all and keep going' to auto-chain subsequent rounds)"

Accepted responses:

- `all` / `<id> only` / `<id> + <id>` / `skip` — applies the chosen migrations for **this round only**. After Step 4 the user is prompted again if new candidates appeared.
- `all and keep going` / `yes to all` / `--apply-all` — applies all this round's candidates AND every chained round until detect is silent (chain mode). Equivalent to invoking the skill with the `--apply-all` argument.

Default to **dry-run / confirmation** — never apply without explicit user opt-in. Chain mode is opt-in; it does not bypass per-migration verify (each migration's verify section still aborts the affected profile without halting the chain).

### Step 3: Apply per migration

For each migration the user opted into:

1. **Read** the migration's `<id>.md` from `./migrations/`. It contains the full apply contract — source format, target format, edge cases, verification.
2. **Re-detect** the eligible profile list (the previous run may have changed state). Use the same `<id>.sh --detect` mechanism, or read the file system directly with the same eligibility rule documented in the markdown.
3. For each eligible profile, follow the markdown's **Apply, per eligible profile** section exactly. The instructions tell you which file to read, what fields to extract, how to handle edge cases, and where to write the output. Do not improvise; the markdown is the contract.
4. After each profile, follow the markdown's **Verify** section if present. Surface any discrepancies (skipped lines, count mismatches) in the per-profile report.
5. Aggregate the per-profile reports into a section-level summary.

### Step 4: Report and re-detect

After applying all selected migrations:

1. Print the aggregated report (one line per profile per migration).
2. Re-run `./detect.sh`. Within a single round the forward → cleanup ordering is already handled by the filename convention (`01-89` runs before `90-99`), so a typical migration sequence completes in one round. Re-detect can still surface migrations that became eligible only after the previous round in edge cases — e.g. a future framework-split migration that depends on `facts.jsonl` existing.
3. **If chain mode is active** (user picked "all and keep going" or invoked with `--apply-all`):
   - If re-detect found new candidates, loop back to Step 3 and apply them **without re-prompting**.
   - **Cycle guard**: track each round's detect output. If a round's detect output is non-empty AND identical to the previous round's (no progress was made), stop and report the stuck state with the unchanged candidate list. This protects against a buggy migration that leaves its profiles permanently eligible.
   - Cap the chain at 10 rounds as a hard ceiling, in case the cycle guard misses an edge case. Report and stop if hit.
4. **Otherwise** (default per-round mode):
   - If re-detect found new candidates, return to Step 2 and prompt again.
5. If detect is silent, confirm "All migrations applied. Profile set is current." Report the total number of rounds run when chain mode was active.

## Parallel application

When a migration applies to many profiles, dispatch the `migration-applier` agent (defined at `agents/migration-applier.md`) once per profile, in parallel. The agent's contract — input parameters, apply protocol, output shape — lives in `agents/migration-applier.md`; do not duplicate it here.

#### Dispatch prompt per agent

```
migration_id:        <id> (e.g. 03-frameworks-split)
migration_md_path:   <absolute path to skills/nemawashi-migrate/migrations/<id>.md>
profile_name:        <slug>
profile_dir:         PROFILE_DIR/<slug>/
today:               YYYY-MM-DD
report_shape:        <copy the migration markdown's "Per-profile report" template verbatim>
```

Issue all N dispatches in a single message (parallel). The agent returns the per-profile report in the shape the migration markdown specifies. Wall-clock is bounded by the slowest profile rather than the sum.

Migrations that internally fan out further (e.g. `03-frameworks-split` dispatches 6 `framework-analyzer` sub-agents per profile) keep that nested dispatch inside `migration-applier`; the top-level migrate skill only sees one report per profile.

## Idempotency and safety

- **Detection is the gate.** A migration only runs against profiles its `--detect` says are eligible right now. After a successful apply, the profile is no longer eligible, so re-runs are no-ops.
- **Atomic writes.** Each per-profile transformation writes to a temp file first, then `mv` to final on success. A crash mid-apply leaves the source file intact.
- **Never modify the source by default.** Migrations may write new files (e.g. `facts.jsonl`) but leave the legacy file (`facts.md`) in place. Deletion of legacy files is an opt-in step the user must request explicitly.
- **Chain mode preserves per-migration verify.** `--apply-all` skips re-confirmation between rounds, not safety. Each migration's verify step still aborts the affected profile; the chain continues, and the abort is surfaced in the final report.

## Edge cases

- **No `PROFILE_DIR`**: report and stop. There is nothing to migrate.
- **Migration script missing the matching markdown** (or vice versa): warn the user, skip the migration. Do not guess at instructions.
- **Apply step fails for a profile** (parsing error, write failure): note the failure, continue to the next profile. The user can re-run after addressing the issue.

## Key Principles

- **Detect cheap, apply smart.** Detection is bash so the session-start hook can run it without spinning up an LLM. Apply is LLM-driven so the parser is robust to the format drift that the legacy data accumulated.
- **Self-discovering registry.** New migrations land as a `.sh` + `.md` pair under `./migrations/`. The skill discovers them via the iterator, not via a hardcoded list.
- **The markdown is the contract.** When applying, follow `<id>.md` exactly. The skill orchestrates; the per-migration markdown specifies what to do.
- **Dry-run by default.** Mutations require explicit user opt-in. The session-start nudge is a hint, never an automatic apply.

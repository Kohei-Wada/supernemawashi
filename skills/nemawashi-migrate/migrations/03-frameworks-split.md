---
id: 03-frameworks-split
detect: 03-frameworks-split.sh
---

# Migration: Split monolithic profile.md into per-framework files

Prior to v3.0.0, `nemawashi-analyze` wrote a single monolithic `profile.md` containing every framework's classification, evidence, and DO/DON'T rules. v3.0.0 splits this so each framework lives in its own file at `frameworks/<slug>.md`, with `profile.md` becoming a slim index (Core Pattern + summary table).

This migration brings legacy profiles up to the new layout. It is a **forward-phase** migration (prefix `01-89`): the work is "produce the new per-framework files and slim down profile.md", non-destructive on the underlying facts. The cleanup phase nothing is needed — this migration writes the canonical new state directly.

## Source state

A profile is eligible when:

- `profile.md` exists, and
- `frameworks/` is missing OR has no `*.md` files.

Detection is performed by `03-frameworks-split.sh`.

## Apply, per eligible profile

The migration is essentially **"re-run `nemawashi-analyze` for this profile under the new flow"** — the facts are the source of truth, the analysis is derived from them.

Follow the `nemawashi-analyze` SKILL.md exactly (the v3.0.0 split-flow version). Specifically:

1. **Read shared inputs** — `profile.md`, `facts.jsonl`, `facts.md` (if present), `relationship.md` (if present). Note the analysis date in the existing `<!-- analyzed: ... -->` comment so you can decide whether to skip (already up-to-date) or run.
2. **Preserve the manual sections** of `profile.md` — Basic Info, Communication Patterns, Active Channels, Work Patterns. Anything else outside the auto-generated blocks. Do not lose those across migration; copy them through to the slim profile.md.
3. **Dispatch one agent per framework** (see `nemawashi-analyze` Step 2 for the prompt template). The agents run in parallel and each writes one `PROFILE_DIR/<name>/frameworks/<slug>.md`. The framework definitions live under `skills/nemawashi-analyze/frameworks/`.
4. **Wait for all agents**, then **synthesize**:
   - Write the slim `profile.md` (Core Pattern + Framework Summary table + preserved manual sections) per `OUTPUT-FORMAT.md`.
   - Write `contradictions.md` cross-framework analysis. If `contradictions.md` exists from the prior monolithic flow, replace it (the new cross-framework synthesis subsumes the old).
   - Update `relationship.md` "Approach Strategy" section if it exists.
5. **Atomic writes** — temp file + `mv` for every file. A crash leaves the prior monolithic profile.md intact so the migration can be re-run.

The old `profile.md`'s Framework Classifications table and Communication Strategy block are **not** preserved in the slim profile.md — that content moves into the per-framework files via the new analysis. The migration is not a textual rewrite; it is a re-analysis that produces the new layout from facts.

## Verify, per eligible profile

After writing:

- `frameworks/` directory exists in the profile.
- It contains one `<slug>.md` file per tier-1 framework defined in [`skills/nemawashi-analyze/FRAMEWORKS.md`](../../nemawashi-analyze/FRAMEWORKS.md). Tier-2 frameworks may be skipped if the agent emitted a Data Gap.
- Each `frameworks/<slug>.md` has the required frontmatter fields: `framework`, `classification`, `confidence`, `last_updated`.
- `profile.md`'s `## Framework Summary` table has one row per produced framework file with a link to the file.
- The manual sections of `profile.md` (Basic Info, Communication Patterns, Active Channels, Work Patterns) are preserved verbatim from the pre-migration state.

If verification fails (a framework file missing, frontmatter malformed, manual section lost): **abort this profile** and surface the discrepancy. Do not retry automatically — let the user decide whether to re-run.

## Per-profile report

On success:

```
<profile-name>: split into <N> framework files; profile.md slimmed (manual sections preserved)
```

On verification failure:

```
<profile-name>: FAILED — <reason>
  frameworks_produced=<list>
  missing=<list>
  preserved_manual_sections=<yes|no>
```

## Idempotency

After a successful apply, `frameworks/` contains files, so the profile is no longer eligible (the detect script requires the directory to be empty or missing). Re-running is a no-op. To re-analyze, the user invokes `nemawashi-analyze <name>` directly — the migration is one-shot.

## Cost note

This migration dispatches 6 LLM agents per profile (one per framework) plus 1 synthesis pass. For N profiles, expect roughly 7N LLM calls. The agents are parallelizable per profile; profiles can also be processed in parallel by the orchestrator (see `nemawashi-migrate` "Parallel application"), so wall-clock cost scales with N rather than 7N.

## Not in scope

- Preserving the prior `profile.md` as a backup. The migration overwrites in place after producing the new files. Users wanting a backup should snapshot `PROFILE_DIR/` before running.
- Per-framework version history (see issue #13). The synthesis pass replaces every framework file atomically; prior versions are lost.

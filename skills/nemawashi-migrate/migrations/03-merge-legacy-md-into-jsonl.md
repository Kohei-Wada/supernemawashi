---
id: 03-merge-legacy-md-into-jsonl
detect: 03-merge-legacy-md-into-jsonl.sh
---

# Migration: Merge legacy facts.md into facts.jsonl

Some profiles end up with both `facts.md` and `facts.jsonl` where the two files cover different date ranges — typically because a `nemawashi-collect` run produced the jsonl AFTER an existing md, with no overlap. The `02-delete-legacy-facts-md` migration correctly refuses to delete in this state (the md contains data the jsonl doesn't cover), so the profile is stuck with two files that together hold the full history.

This migration brings the jsonl up to coverage by merging the missing md entries into it. Once merged, `02-delete-legacy-facts-md` will safely remove the now-redundant md on the next round.

## Source state

A profile is eligible when:

- `facts.md` exists, and
- `facts.jsonl` exists, and
- the md's date range is not fully covered by the jsonl's date range — i.e. `min(jsonl) > min(md)` OR `max(jsonl) < max(md)`.

Detection is performed by `03-merge-legacy-md-into-jsonl.sh`.

## Apply, per eligible profile

1. **Read** both files.
2. **Parse the md** entries — for each fact bullet (`^- \[YYYY-MM(-DD)?\] ...`), extract date / source / channel / url / content per the same rules as the `01-facts-md-to-jsonl` contract (five source-tag placement variants tolerated). Preserve date precision (`YYYY-MM-DD` or `YYYY-MM`) as it appears.
3. **Parse the jsonl** entries — for each record, note `(date, source, content)`.
4. **For each md entry, decide whether it is already represented in the jsonl.** The match heuristic, in order:
   - **date + source match** → strong signal of duplicate. Compare content for semantic similarity; if the two refer to the same observable behavior, treat as duplicate and skip.
   - **date + source mismatch** → almost certainly a new entry; mark for append.
   - **Ambiguous** (e.g. multiple md entries with the same date and source, partial overlap with jsonl entries on that date) → **prefer append over drop**. A slightly redundant entry is reversible by hand-editing; a silently dropped real fact is not.
5. **Append unmatched md entries** to `facts.jsonl` as JSONL records (one per line) per the schema in `skills/nemawashi-collect/FACTS-SCHEMA.md`. Preserve the date precision from the md.
6. **Atomic write**: build the merged jsonl into a temp file in the same directory, then `mv` it to `facts.jsonl` on success.
7. **Do not delete `facts.md` here.** The chained `02-delete-legacy-facts-md` migration handles deletion on the next detect round, now that the jsonl covers the full range. Keeping the responsibilities separated lets the user audit the merged jsonl before allowing 02 to discard the source.

## Verify

After writing:

- `new_jsonl_count = old_jsonl_count + appended_count` (a simple addition check; large discrepancies indicate a parse bug).
- `min(new_jsonl_dates) <= min(md_dates)` AND `max(new_jsonl_dates) >= max(md_dates)`. If either inequality still fails, surface in the report — do not pretend success.

## Per-profile report

On success:

```
<profile-name>: merged <N> entries (jsonl was <M>, now <M+N>; md had <K> entries; dedup dropped <K-N>)
```

On verification still failing post-merge:

```
<profile-name>: PARTIAL — merge ran but coverage still incomplete
  new_jsonl=<...>, md range=<min>..<max>, jsonl range=<min>..<max>
```

## Why this is a separate migration

01's eligibility is "md exists AND jsonl does not" — the simple convert path. Profiles where jsonl already exists (from a `nemawashi-collect` run, or a partial migration) are in a different state and need different logic: not convert, but merge. Keeping each migration single-responsibility lets the self-discovering registry's chain capability handle complex states by composition:

```
03-merge → makes 02 viable for these profiles
02-delete → cleans up the now-redundant md
```

No special-casing in either. Just two single-purpose migrations the orchestrator chains across detect rounds.

## Risks and mitigations

- **Over-dedup** (dropping a real fact because it looks similar to an existing jsonl record): mitigated by the "prefer append over drop" rule. Cost of a duplicate is low; cost of a missing fact is high.
- **Under-dedup** (treating same fact written in two voices as distinct): possible but acceptable. The jsonl is the source for downstream analysis; dedup can happen there if it matters.
- **Date precision mismatch** (md says `2026-03`, jsonl has `2026-03-15` for what is plausibly the same event): treat as distinct unless content is clearly identical. Erring toward append again.

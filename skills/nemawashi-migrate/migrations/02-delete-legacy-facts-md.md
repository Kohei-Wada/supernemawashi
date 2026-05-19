---
id: 02-delete-legacy-facts-md
detect: 02-delete-legacy-facts-md.sh
---

# Migration: Delete legacy facts.md

After `01-facts-md-to-jsonl` produces `facts.jsonl`, the original `facts.md` is redundant — its content is also in the jsonl. This migration removes the redundant copy after re-verifying content fidelity.

Splitting cleanup from convert makes the destructive action opt-in at the orchestrator level. A user who wants to keep `facts.md` for any reason can simply decline this migration when prompted.

## Source state

A profile is eligible when **both** files exist:

- `<profile-dir>/facts.md`
- `<profile-dir>/facts.jsonl`

Detection is performed by `02-delete-legacy-facts-md.sh`.

## Apply, per eligible profile

1. **Count** fact entries in `facts.md` — lines matching `^- \[[0-9]{4}-[0-9]{2}(-[0-9]{2})?\]`. Call this `md_count`.
2. **Count** records in `facts.jsonl` — non-empty lines. Call this `jsonl_count`.
3. **Verify (1)**: `jsonl_count >= md_count`. The jsonl may have extra entries from collect runs that ran after the original migration, but it must never have fewer than the md once a migration has happened. If `jsonl_count < md_count`, **abort this profile** and surface the discrepancy. Do not delete.
4. **Verify (2)** (spot-check date range): parse all dates from `facts.jsonl` (the `date` field of each record) and from `facts.md` (the leading `[YYYY-MM(-DD)?]` of each bullet). Confirm:
   - `min(jsonl dates) <= min(md dates)`
   - `max(jsonl dates) >= max(md dates)`
   If either inequality fails, **abort this profile** and surface the discrepancy. Do not delete.
5. **If both verifications pass**, delete `facts.md`.

## Per-profile report

On success:

```
<profile-name>: facts.md removed (jsonl had <jsonl_count> records, md had <md_count>)
```

On verification failure:

```
<profile-name>: SKIPPED — <reason>
  md_count=<N>, jsonl_count=<M>
  date_range_md=<min> .. <max>
  date_range_jsonl=<min> .. <max>
```

## Why two verifications

The count check catches the simple case (someone wrote a partial jsonl by mistake). The date-range check catches a subtler case: jsonl that's the same length as md but was somehow re-generated from a different source (e.g. a partial re-collect that touched only one fragment). For 17 profiles the cost is negligible; for safety it is worth it.

## Idempotency

After a successful apply, `facts.md` is gone, so the profile is no longer eligible (detection requires both files). Re-running is a no-op.

## Not in scope

- Restoring a deleted `facts.md` from the jsonl. The jsonl is now the source of truth; the md was a redundant copy of derived content. If the user needs the markdown view back, `nemawashi-show <name> facts` renders the jsonl in markdown bullets.
- Trash-can semantics. Deletion is permanent. Users who want a safety net should rely on their own backup workflow before running this migration.

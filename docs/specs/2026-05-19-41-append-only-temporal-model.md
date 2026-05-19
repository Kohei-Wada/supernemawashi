# Append-only temporal model for framework analysis — Design Spec

**Issue:** #41
**Date:** 2026-05-19
**Status:** Approved (brainstorming)

## Goal

Replace destructive overwrite of per-framework analysis output with an append-only assertion log, so prior analyses survive on disk and time-travel queries (`--as-of`, `--history`) become first-class. Supersedes #13 (sidecar `profile.history.jsonl`) and obsoletes the `_archive/` stop-gap from #40.

## Scope

**In scope (v1):**

- The six `frameworks/<slug>.md` files per profile become event-sourced: each analyze pass appends one assertion to `frameworks/<slug>.jsonl`, and the `.md` is regenerated as the current snapshot view.

**Out of scope (v1) — explicitly deferred:**

- `relationship.md` Approach Strategy section — separate follow-up issue. Narrower impact (11/19 profiles use it), and the v1 framework pattern needs to prove itself first.
- `contradictions.md` — small, low-loss, regenerated. Stays as-is.
- `profile.md` Core Pattern / Framework Summary — derived from current framework state, stays regenerated.
- `facts.jsonl` — already append-only.
- Cross-profile aggregation tools.
- `nemawashi-diff` skill (easy follow-up).
- `nemawashi-revert` skill (easy follow-up).
- Fact-ID foreign keys from evidence — facts.jsonl has no `id` field today and adding one is its own migration.

## Architecture

**Pattern:** event sourcing with snapshot cache.

```
PROFILE_DIR/<name>/
  profile.md                                regenerated (synthesis snapshot)
  contradictions.md                         regenerated (unchanged)
  relationship.md                           unchanged (v1)
  facts.jsonl                               unchanged
  frameworks/
    thomas-kilmann-tki.md                   regenerated (current-view snapshot, derived from .jsonl)
    thomas-kilmann-tki.jsonl                NEW — append-only assertion log, source of truth
    (...one .md + one .jsonl per framework)
```

- The `.jsonl` is the **source of truth** for that framework's analysis over time.
- The `.md` is a **derived snapshot** of the latest assertion. It's a read cache so existing consumers (`nemawashi-reply`, `nemawashi-show`) don't need to change.
- On every analyze pass: append one assertion to the `.jsonl`, then regenerate the `.md` from that latest entry.
- `_archive/` directories from #40 become redundant and are removed by migration.

### Why sidecar (Approach A) over JSONL-primary (Approach B)

| | A (sidecar) | B (JSONL-primary) |
|---|---|---|
| Consumer (`nemawashi-reply`, `nemawashi-show`) changes | none | every read site rewritten |
| Migration cost | trivial — 1 assertion per existing .md | trivial for data, large for code |
| `--as-of` query | reads jsonl + folds | reads jsonl + folds |
| Disk usage | 2x per framework | 1x per framework |

Approach A buys the temporal model without forcing a consumer rewrite. Approach B is cleaner long-term but doesn't deliver more user-visible value for the cost. Choose A.

## Data model

### Assertion entry

One JSON object per line in `frameworks/<slug>.jsonl`. No prologue, no comments — pure JSONL.

```jsonl
{
  "asserted_at": "2026-05-19T09:53:39Z",
  "framework": "thomas-kilmann-tki",
  "classification": "Collaborating primary, Competing when defending priorities/pace",
  "classification_detail": "Default mode is Collaborating: builds on others' input, proposes alternatives, and asks clarifying questions to co-construct solutions. Shifts to Competing when his priorities or work pace are threatened — sets firm boundaries with direct, assertive language to protect focus.",
  "confidence": "Confirmed",
  "facts_snapshot_count": 7,
  "evidence": [
    {
      "date": "2026-03-27",
      "source": "slack",
      "quote": "プロセスは頭にあるのでやります。ただ今はちょっとまってください",
      "signal_tag": "TKI:competing",
      "reasoning": "explicit refusal to be interrupted; high assertiveness, low cooperativeness"
    }
  ],
  "rules": {
    "requesting": {
      "do": [
        {"text": "Bring context and options, then invite him to co-shape", "signal_tag": "TKI:collaborating"}
      ],
      "dont": [
        {"text": "Drop a fully decided plan with no room for input", "signal_tag": "TKI:collaborating"}
      ]
    },
    "conflict":   { "do": [...], "dont": [...] },
    "reporting":  { "do": [...], "dont": [...] },
    "routine":    { "do": [...], "dont": [...] }
  },
  "data_gap_reason": null
}
```

### Field definitions

| Field | Type | Required | Meaning |
|---|---|---|---|
| `asserted_at` | ISO-8601 timestamp (UTC, second precision) | yes | When this assertion was written. Acts as the entry's identity. Sort key for the log. |
| `framework` | string | yes | Framework slug. Redundant with the filename but enables `grep -h '"framework":"tki"' frameworks/*.jsonl` across profiles. |
| `classification` | string | yes | One-line classification text. Matches the current `classification:` frontmatter field in `<slug>.md`. |
| `classification_detail` | string | yes | 1-3 sentence expansion of the classification — the prose that appears under `## Classification` in the .md body today. |
| `confidence` | enum: `Confirmed`/`Hypothesis`/`Data Gap` | yes | Same enum as today. |
| `facts_snapshot_count` | integer | yes | How many facts were in `facts.jsonl` when this assertion was written. Useful for "this analysis was based on N facts" diagnostics. |
| `evidence` | array of `{date, source, quote, signal_tag, reasoning}` | yes (may be empty for Data Gap) | Self-contained — no foreign key into facts.jsonl. Mirrors today's `## Evidence` bullets. |
| `rules` | object keyed by 4 situation categories | yes (omitted as `{}` for Data Gap) | Each situation has `do` and `dont` arrays of `{text, signal_tag}` objects. Replaces today's `## Rules` markdown sections. |
| `data_gap_reason` | string \| null | yes | Non-null when `confidence == "Data Gap"`. Captures today's `## Data Gap` section content. Null otherwise. |

### Identity & collisions

- **Identity** = `asserted_at` (ISO timestamp). Same-second collisions are vanishingly rare; if they occur it's a programming bug worth investigating, not a feature to silently handle.
- **No UUID, no hash.** ISO timestamps are human-readable, sort lexically the same way they sort chronologically, and `grep` works.

### Retraction model

**Latest-wins (implicit supersession).** No retract entries.

- Read = "latest assertion per `framework` slug per profile" (which, since each `<slug>.jsonl` is one framework, simplifies to "last line of the file").
- "When did this classification change?" derives trivially from the previous assertion's `asserted_at`.
- The information loss vs. explicit-retract is "this assertion was actively wrong" vs "this assertion was superseded by newer data". That distinction is rarely meaningful for supernemawashi and isn't worth the bookkeeping cost.

### Reaffirm entries

**Not in v1.** When re-analyze produces the same classification, write a new full assertion. Yes this duplicates content, but it preserves "this was checked on date X" without introducing a new entry type. JSONL is cheap; clarity is expensive.

If the same-classification clutter ever becomes a problem, we can add a `{"type":"reaffirm","at":"...","of":"<prior asserted_at>"}` shape as a follow-up — but only after data shows it matters.

## Read paths

### Latest view (default `nemawashi-show`)

The `.md` file is the cache. Read it directly. No fold.

### `--as-of YYYY-MM-DD`

```
for slug in frameworks/*.jsonl:
  scan slug from beginning, keep last entry where asserted_at <= date
  if entry exists: render to markdown view, print
  else: print "no analysis as of <date>"
```

Render-to-markdown uses the same template that produces today's `frameworks/<slug>.md`. The render is deterministic and pure — same assertion → same markdown.

### `--history` (per framework)

```
for each entry in frameworks/<slug>.jsonl:
  print "<asserted_at>: <classification> (<confidence>)"
```

Pure log dump. The full diff between any two entries is then a single `jq` join.

## Write path (analyze)

The `framework-analyzer` agent today writes to `frameworks/<slug>.md` atomically. New flow:

1. Agent computes the new analysis (unchanged).
2. Agent serializes the assertion as one JSONL line and **appends** to `frameworks/<slug>.jsonl`.
3. Agent regenerates `frameworks/<slug>.md` from the just-written assertion (deterministic markdown render).

Both writes happen inside the agent (single-agent atomicity). The orchestrator does not coordinate writes across the two files.

**Atomicity strategy:** the assertion is the source of truth. If the `.md` regen fails mid-write, the .md is briefly stale but the .jsonl is consistent. A subsequent regenerate-only pass (`nemawashi-show --refresh-cache <slug>`, future skill) can rebuild .md from .jsonl any time.

**Pre-archive (#40) becomes obsolete.** The orchestrator no longer pre-archives outputs to `_archive/` — the `.jsonl` is the archive. Migration removes `_archive/` directories.

## Migration

Per profile, for each `frameworks/<slug>.md` that already exists:

1. Read frontmatter (`framework`, `classification`, `confidence`, `last_updated`) and body (Classification text, Evidence bullets, Rules sections, Data Gap reason if any).
2. Construct one assertion with `asserted_at = <last_updated>T00:00:00Z` (use the documented date, not migration time).
3. Write that one entry to `frameworks/<slug>.jsonl`.
4. Leave the .md as-is (it's now the cached current view, byte-for-byte identical).
5. Delete `frameworks/_archive/` and the top-level `<name>/_archive/` directories entirely. **Prior versions held there are discarded.**

The temporal-model log starts at the current state — older analyses preserved in `_archive/` by #40 are intentionally not backfilled. Rationale: the `_archive/` data is incomplete (only profiles re-analyzed since #40 landed have any), the dates are coarse (one entry per analyze run, no intermediate state), and the cost of writing a parser for the archived markdown is not paid back by what we'd recover. Start the log from "now" and accept that history before #41 lands is lost.

**Migration registration:** add `04-frameworks-temporal-model` under `skills/nemawashi-migrate/migrations/`. Detection: `frameworks/<slug>.md` exists AND `frameworks/<slug>.jsonl` does NOT exist.

## Consumer impact

- `nemawashi-analyze` orchestrator + `framework-analyzer` agent: write to both .jsonl and .md (described above). Remove the #40 pre-archive Step 1.5.
- `nemawashi-reply` / `nemawashi-show` (default view): unchanged. Read `.md` as today.
- `nemawashi-show --as-of` / `--history`: new flags, implemented in `nemawashi-show`. Read `.jsonl` + fold.
- `nemawashi-check`: unchanged for v1. Could later factor in `.jsonl` line count as a "this framework has been re-analyzed N times" signal.
- `nemawashi-migrate`: gains the new migration registration.

## Acceptance

- Running `nemawashi-analyze` twice on a profile, with a 30-day gap and at least one classification change, produces:
  - `frameworks/<slug>.jsonl` with 2 lines (no retract entry, latest-wins).
  - `frameworks/<slug>.md` reflecting the second assertion.
- `nemawashi-show <name> --as-of <date-between-runs>` reconstructs the framework view from the first assertion.
- `nemawashi-show <name> <slug> --history` prints both classifications with their `asserted_at`.
- Existing profiles, after running the v1 migration, have `frameworks/<slug>.jsonl` files with one entry each and intact `.md` files.
- `_archive/` directories are removed by the migration.
- All existing pre-commit hooks pass without changes.

## Open follow-ups (deferred to separate issues)

- Apply the same model to `relationship.md` Approach Strategy.
- `nemawashi-diff <name> <date-a> <date-b>` skill.
- `nemawashi-revert <name> <slug>` skill (write a new assertion equal to a prior one).
- Fact-ID foreign keys (depends on facts.jsonl gaining an `id` field — its own migration).
- Reaffirm entry shape if same-classification clutter becomes painful.

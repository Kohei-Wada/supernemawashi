# Facts Schema

Facts about a profiled person are stored as **JSON Lines** (JSONL) at `<profile-dir>/facts.jsonl`. One JSON object per line, one observable behavior per record, appended as collection happens.

This file is the canonical schema. Producers (the adapters) emit records that conform to it; consumers (nemawashi-analyze, nemawashi-check, nemawashi-show) parse it.

## Record format

```jsonl
{"date":"2026-03-28","source":"slack","content":"<observable behavior>","url":"https://acme.slack.com/archives/C123/p456","channel":"#engineering"}
```

### Required fields

| Field     | Type   | Description                                                                                         |
|-----------|--------|-----------------------------------------------------------------------------------------------------|
| `date`    | string | When the behavior occurred. `YYYY-MM-DD` for day precision, `YYYY-MM` when only the month is known. |
| `source`  | string | The adapter's `output_tag` (`slack` / `gmail` / `calendar` / `github` / `manual`).                  |
| `content` | string | One observable behavior — what they said or did. No psychological interpretation (that's analyze's job). |

### Optional fields

| Field           | Type     | When to include                                                                                  |
|-----------------|----------|--------------------------------------------------------------------------------------------------|
| `url`           | string   | Permalink to the underlying message / event when one is constructible.                           |
| `channel`       | string   | Slack channel name (with leading `#`). Slack-specific.                                           |
| `repository`    | string   | GitHub `owner/repo`. GitHub-specific.                                                            |
| `meeting_title` | string   | Calendar event title. Calendar-specific; only include when it doesn't reveal confidential info.  |
| `participants`  | string[] | Other people involved in the interaction (handles / emails).                                     |
| `tags`          | string[] | Free-form labels callers want to attach (e.g. `["delegation","follow-up"]`).                     |

Adapters may add their own optional fields — keep names lowercase and namespaced to the source when ambiguous (e.g. `slack_thread_ts`, `github_review_state`).

## Date precision

The `date` field carries its own precision via the string length:

- `2026-03-28` — day precision (10 chars).
- `2026-03`    — month precision (7 chars).

Consumers should treat both as valid; the producer chose the level of certainty it could justify.

## Why JSONL (not JSON array, not Markdown)

- **Append-friendly.** Adapters can `>> facts.jsonl` instead of read-modify-write of the entire file.
- **Per-line robustness.** A single malformed record doesn't break parsing of the rest.
- **LLM-stable.** Each line is independent — no trailing commas or unclosed `]` to lose across long emissions.
- **Git-friendly.** One fact = one line, so diffs are minimal and per-fact.
- **Cheap counting.** `wc -l facts.jsonl` is the fact count.

## Legacy format (`facts.md`)

Profiles created before this schema landed have a `facts.md` file with one entry per line in the form:

```
- [YYYY-MM-DD] [source] <observable behavior> (url)
```

…with several minor variants in source-tag position. Consumers MUST read both `facts.jsonl` and `facts.md` if either exists and merge entries chronologically. Producers SHOULD write new entries to `facts.jsonl` only — do not touch `facts.md` once it exists. A future migration step will fold legacy `facts.md` files into `facts.jsonl`.

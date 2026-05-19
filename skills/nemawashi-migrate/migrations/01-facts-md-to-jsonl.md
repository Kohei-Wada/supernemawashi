---
id: 01-facts-md-to-jsonl
detect: 01-facts-md-to-jsonl.sh
---

# Migration: facts.md → facts.jsonl

Convert the legacy markdown bullet-list `facts.md` produced before #9 to the structured `facts.jsonl` defined in `skills/nemawashi-collect/FACTS-SCHEMA.md`.

The detection part (`01-facts-md-to-jsonl.sh --detect`) is a cheap state check: a profile is eligible iff it has `facts.md` and no `facts.jsonl`. The apply part below is LLM-driven so the parser can absorb the format drift that the legacy file accumulated over time.

## Source format

`facts.md` consists of YAML frontmatter, an optional `# Facts` header, monthly `## YYYY-MM` group headers, and bullet entries. Each entry starts with a date in brackets and ends with the observable content. Five source-tag placement variants have been observed across existing profiles — the parser must tolerate all of them:

1. **Position-2 bracket**: `- [YYYY-MM-DD] [slack] content (https://...)`
2. **Trailing bracket**: `- [YYYY-MM-DD] content [slack]`
3. **With channel suffix**: `- [YYYY-MM-DD] [slack: #channel-name] content (https://...)`
4. **Markdown-link source**: `- [YYYY-MM-DD] [Slack #channel](https://...) content`
5. **Trailing with channel**: `- [YYYY-MM] content [slack: #channel]`

Dates are either day-precision (`YYYY-MM-DD`) or month-only (`YYYY-MM`); preserve whichever the source used.

Source values seen in practice: `slack`, `gmail`, `calendar`, `github`, `slack_profile`, `manual`. Normalize the source to lowercase. Treat `slack_profile` as `slack`.

## Target format

One JSON object per line in `facts.jsonl`. Required fields: `date`, `source`, `content`. Optional fields: `url`, `channel`, plus the adapter-specific fields listed in `FACTS-SCHEMA.md` if you can derive them from the legacy text.

## Apply, per eligible profile

1. Read the profile's existing `facts.md`.
2. Walk the file line by line. Skip frontmatter delimiters (`---`), frontmatter fields (`person:`, `last_updated:`), section headers (`#`, `##`, `###`), and blank lines.
3. For each line that matches `^- \[YYYY-MM(-DD)?\] ...`, extract:
   - **date** — the leading bracketed string, kept as-is (day- or month-precision).
   - **source** — the source token, lowercased. Try the five patterns above in order; the first that fits wins.
   - **channel** (optional) — the part after `:` inside the source bracket, or after `#` inside the markdown-link source.
   - **url** (optional) — any trailing `(https://...)` segment, or the URL inside a markdown-link source.
   - **content** — everything else, with the source/url/channel fragments removed and surrounding whitespace trimmed.
4. If a line cannot be matched against any of the five patterns, **skip it and record a note** in the per-profile report. Do not crash; do not invent missing fields. Note the line number and the raw line so the user can fix it manually if needed.
5. Emit one JSONL record per parsed line, in the order they appear in the source. Use a JSON encoder (e.g. `jq -c -n --arg ...`) to handle escapes correctly; do not hand-build JSON strings.
6. Write atomically: build the output into a temp file in the same directory, then `mv` it to `facts.jsonl` on success. Do not delete `facts.md` in this step — the redundant copy is removed by the chained `02-delete-legacy-facts-md` migration, which the orchestrator picks up on the next detect round.

## Verify, per eligible profile

After writing each profile's `facts.jsonl`:

- The line count of `facts.jsonl` plus the count of skipped lines should equal the count of `^- \[` lines in the original `facts.md`. Any mismatch is a parser bug — surface it.
- A spot-check: the first and last entries of `facts.jsonl` should match the first and last bullet entries of `facts.md` in date and source.

## Report per profile

After completing each profile, emit one line in this shape:

```
<profile-name>: <N> migrated, <M> skipped (date range: <oldest> .. <newest>)
```

If `M > 0`, also list the skipped raw lines under that report so the user can decide whether to hand-fix.

## Idempotency

Re-running the apply on a profile that already has `facts.jsonl` is undefined — but detection guarantees this never happens, because the eligibility rule requires the absence of `facts.jsonl`. The orchestrator should re-run detection between applies if it intends to fan out across many profiles.

## Source identifiers note

`facts.md` legitimately contains real internal names (colleagues, channels, customer projects) — that is the whole point of profile data. The target `facts.jsonl` lives in `~/.local/share/supernemawashi/profiles/<name>/` which is gitignored and never enters any repo. Writing real identifiers to `facts.jsonl` is correct and expected; the same content was already on disk in `facts.md`.

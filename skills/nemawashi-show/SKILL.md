---
name: nemawashi-show
description: Use when user wants to view, show, list, or display profile data for one or more people - read-only display of profiles stored in PROFILE_DIR
---

# Profile Viewer

Display profile data so the user can quickly review what's been collected and analyzed about a person, or see who has been profiled.

## When to Use

- User says "show profile for X", "view X's profile", "Xを見せて", "Xのprofile"
- User says "list profiles", "who do I have profiles for?", "profile一覧", "誰のprofileある?"
- User wants a specific section: "X's DO/DON'T", "Xのfacts", "Xの矛盾", "X's contradictions"
- User wants to spot-check after running `nemawashi-collect` or `nemawashi-analyze`

**Not for:**
- Editing → `nemawashi-collect` (creates/updates raw data) or `nemawashi-analyze` (regenerates analysis)
- Staleness triage → `nemawashi-check`
- Crafting replies → `nemawashi-reply`

## Process

### Step 1: Parse the Request

Determine the operation from the user's phrasing:

| Operation | Trigger | Target |
|-----------|---------|--------|
| **List** | no name, or "list" / "一覧" / "誰がいる" | all profiles |
| **Person** | name only, or "show X" / "X見せて" | full profile for one person |
| **Section** | name + section keyword | one section for one person |

Section keywords (case-insensitive):

| Keyword | Target |
|---------|--------|
| `profile` / no keyword | `profile.md` (default) |
| `relationship` / `関係` | `relationship.md` |
| `facts` / `事実` | `facts.jsonl` + `facts.md` (merged, see below) |
| `contradictions` / `矛盾` | `contradictions.md` |
| `basic` / `info` | `## Basic Info` section of `profile.md` |
| `communication` / `話し方` | `## Communication Patterns` section of `profile.md` |
| `work` / `仕事` | `## Work Patterns` section of `profile.md` |
| `core` / `pattern` / `synthesis` | `## Core Pattern` section of `profile.md` |
| `summary` / `frameworks` / `分析` | `## Framework Summary` section of `profile.md` |
| `defense` / `防衛` | `frameworks/defense-mechanisms.md` |
| `tki` / `conflict-mode` / `競合` | `frameworks/thomas-kilmann-tki.md` |
| `ta` / `ego` / `エゴ` | `frameworks/transactional-analysis-ta.md` |
| `motivators` / `motivation` / `動機` | `frameworks/core-motivators.md` |
| `biases` / `cognitive` / `バイアス` | `frameworks/cognitive-biases.md` |
| `attachment` / `愛着` | `frameworks/attachment-style.md` |
| `do/don't` / `strategy` / `rules` / `戦略` | Aggregated **Rules** section across all `frameworks/*.md`, grouped by situation category. See Aggregated rules view below. |

### Step 2: Resolve the Person (when applicable)

The common case is "user typed an exact directory name" — go straight to the target file. Only fall back to fuzzy resolution when the direct read misses.

1. **Direct read** — attempt to read the target file at `PROFILE_DIR/<name>/<file>` immediately (e.g. `PROFILE_DIR/<name>/profile.md` for a person operation, `PROFILE_DIR/<name>/relationship.md` for `<name> relationship`, etc.). If the read succeeds, you have resolved the person in **one tool call** — proceed to Step 3.
2. **On read failure** (file or directory doesn't exist), fall back to fuzzy resolution:
   1. List directories in `PROFILE_DIR/` (ignore `README.md` and any non-directory entries).
   2. **Exact match** (case-insensitive) → use it.
   3. **Prefix match** → use it.
   4. **Substring match** → if exactly one, use it. If multiple, list candidates and ask which.
   5. **No match** → report "No profile for '<name>'. Did you mean: <closest>?" or suggest running `nemawashi-collect` if there are no close matches.

The direct-read path is the happy path: typed name → exact-match → one tool call. The fuzzy path is for typos, partial names, and missing profiles.

### Step 3: Execute

#### List operation

1. For each directory in `PROFILE_DIR/`:
   - Read frontmatter from `profile.md` (`name`, `role`, `last_updated`).
   - Read the `<!-- analyzed: YYYY-MM-DD, facts_count: N -->` comment if present.
   - Count current facts: non-empty lines in `facts.jsonl` (if present) + lines in `facts.md` matching `^- \[[0-9]{4}-[0-9]{2}(-[0-9]{2})?\]` (if present). Sum both — profiles mid-migration may have content in both files.
   - Note presence of `contradictions.md` and whether it has content beyond the header.
2. Display as a table:

```markdown
| Person | Role | Last Analyzed | Facts | Contradictions |
|--------|------|---------------|-------|----------------|
| alice | Acme Corp Eng | 2026-05-16 | 47 | 12 |
| bob | (n/a) | never | 23 | — |
```

3. After the table, list short hints:
   > Use `show <name>` to view a full profile, or `<name> facts` / `<name> DO/DON'T` for sections.

#### Person operation

1. Read `profile.md` and render it as-is. Do NOT summarize or paraphrase — the user wants to see the actual content.
2. After `profile.md`, append a short footer:
   > Also available: `<name> relationship`, `<name> facts`, `<name> contradictions`, `<name> do/don't`, `<name> <framework-slug>`.
3. If `profile.md` is missing but fact data exists (`facts.jsonl` and/or `facts.md`), render the facts using the same merged view as the section operation below, and note "No analyzed profile yet — run `nemawashi-analyze` for <name>."

#### Section operation

1. If the section maps to a single file (`relationship.md` / `contradictions.md` / `frameworks/<slug>.md`): render the whole file. For framework files, also print a one-line footer pointing back: `Summary in profile.md → ## Framework Summary`.
2. If the section is `facts`: read both `facts.jsonl` (if present) and `facts.md` (if present) and render a merged chronological view:
   - For each `facts.jsonl` record, format as: `- [YYYY-MM-DD] [<source>] <content> (<url>)` — omit the URL block if absent. Channel/repository/meeting_title go in parentheses after content when present.
   - For each `facts.md` line, render as-is (already in markdown bullet form).
   - Sort the merged list by date descending.
3. If the section maps to a `## <heading>` inside `profile.md`: extract lines from that `## <heading>` up to (but not including) the next `## ` heading. Render that block.
4. If the section is `do/don't` / `strategy` / `rules` (the aggregated rules view): see Aggregated rules view below.
5. If the section doesn't exist in the file or framework file is missing: report "Section '<name>' not found in <person>'s profile."

#### Aggregated rules view

When the user asks for `do/don't` / `strategy` / `rules`, gather rules from every `frameworks/<slug>.md` and present them grouped by situation category. This is the cross-framework rollup of what used to live in `profile.md → ## Communication Strategy`:

1. List `PROFILE_DIR/<person>/frameworks/*.md`. If the directory is missing or empty, report "No framework analysis yet — run `nemawashi-analyze <person>`." and stop.
2. For each situation in the canonical order defined in [using-supernemawashi → Situation Categories](../using-supernemawashi/SKILL.md#situation-categories), render a section. Under each, list every framework that has a non-trivial rule for that situation:
   ```markdown
   ### When Requesting

   **Defense Mechanisms** (Confirmed)
   - DO: <rule> [signal: <tag>]
   - DON'T: <rule> [signal: <tag>]

   **Conflict Mode (TKI)** (Confirmed)
   - DO: ...
   - DON'T: ...
   ```
   Skip a framework's block under a situation if its rules are only the `(no framework-specific rule for this situation)` placeholder.
3. If the user passed an extra word matching one of the situations (e.g. `<name> do/don't conflict`), filter to that one situation only.

Optional filter: `<name> do/don't <framework-slug>` restricts to a single framework's rules across all situations (functionally equivalent to opening `frameworks/<slug>.md`, but rendered situation-major rather than file-as-written).

### Step 4: Handle Empty / Missing States

- **No profiles at all**: "No profiles found in `PROFILE_DIR/`. Run `nemawashi-collect` or `nemawashi-discover` to start."
- **Profile dir exists but is empty**: same as above for that person.
- **Neither `facts.jsonl` nor `facts.md` is present**: facts count = 0.
- **`contradictions.md` has only a header (no entries)**: report "—" in the list view; in section view, render it as-is so the user sees it's empty.

## Output Style

- **Render markdown as-is.** Profiles are written in markdown — display them directly so the user sees the source.
- **No paraphrasing or summarization.** This skill is a read tool, not an analysis tool. If the user wants analysis, route them to `nemawashi-analyze`.
- **Quote the path** at the top so the user can `vim` it if they want to edit:
  ```
  📄 ~/.local/share/supernemawashi/profiles/alice/profile.md
  ```
- **Keep footer hints short.** One line max.

## Edge Cases

- Profile name contains spaces or non-ASCII: use exact-match path resolution; do not URL-encode.
- User asks for a profile that exists but `profile.md` is missing (only fact data — `facts.jsonl` and/or `facts.md`): render the merged facts view and suggest running `nemawashi-analyze`.
- User asks for a section that doesn't exist (e.g., `alice strategy` when there's no Communication Strategy yet): report missing and suggest running `nemawashi-analyze`.
- Ambiguous fuzzy match: list candidates and ask. Do not guess.

## Time-travel flags (#41)

After #41 lands, each `frameworks/<slug>.md` is a derived snapshot of the latest assertion in `frameworks/<slug>.jsonl`. Two new flags let the user query past states.

### `nemawashi-show <name> --as-of YYYY-MM-DD`

Reconstructs the per-framework view as it was on that date. For each framework slug in the profile:

```bash
ASSERTION=<skill-root>/../nemawashi-analyze/assertion.sh
DEF=<plugin-root>/skills/nemawashi-analyze/frameworks/<slug>.md
JSONL=PROFILE_DIR/<name>/frameworks/<slug>.jsonl

entry=$(bash "$ASSERTION" fold "$JSONL" --as-of YYYY-MM-DD)
if [ -n "$entry" ]; then
  bash "$ASSERTION" render "$entry" "$DEF"
else
  echo "<slug>: no analysis as of YYYY-MM-DD"
fi
```

Render each framework's output in the same shape as the default `nemawashi-show <name>` view, then synthesize a brief banner noting the as-of date.

If a framework's `.jsonl` does not exist (the profile predates #41 and migration `04-frameworks-temporal-model` has not run), fall back to reading `.md` directly and note the limitation in the output.

### `nemawashi-show <name> <slug> --history`

Prints the chronological assertion log for one framework. Useful for spotting when a classification changed.

```bash
ASSERTION=<skill-root>/../nemawashi-analyze/assertion.sh
bash "$ASSERTION" history PROFILE_DIR/<name>/frameworks/<slug>.jsonl
```

Output is one line per assertion: `<asserted_at>: <classification> (<confidence>)`.

For a diff between two specific dates, the user can compose `fold` + `render` themselves:

```bash
DATE_A=2026-03-01
DATE_B=2026-05-01
diff \
  <(bash "$ASSERTION" render "$(bash "$ASSERTION" fold "$JSONL" --as-of $DATE_A)" "$DEF") \
  <(bash "$ASSERTION" render "$(bash "$ASSERTION" fold "$JSONL" --as-of $DATE_B)" "$DEF")
```

A dedicated `nemawashi-diff` skill is on the roadmap (see the spec's "Open follow-ups") but out of scope for #41.

## Key Principles

- **Read-only.** Never write or modify profile files. If the user wants to change something, route them to the appropriate skill.
- **No interpretation.** Show the data as written. The user is the analyst here — they want to see their own notes, not your summary of them.
- **Fast — direct-read first.** Person and section operations should resolve in **one tool call** when the user typed an exact name. Read the target file directly; only fall back to `ls PROFILE_DIR/` + fuzzy match when the direct read misses. Don't over-engineer.

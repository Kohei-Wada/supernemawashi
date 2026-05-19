# #41 Append-only temporal model — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the assertion-log temporal model per `docs/specs/2026-05-19-41-append-only-temporal-model.md`. Each analyze pass appends one assertion to `frameworks/<slug>.jsonl`; `frameworks/<slug>.md` is regenerated as the cached current view. `nemawashi-show` gains `--as-of` and `--history` flags.

**Architecture:** Sidecar JSONL (source of truth) + regenerated .md (snapshot view). A new `assertion.sh` helper handles append / render / fold / history as deterministic operations. The framework-analyzer agent emits JSON and calls `assertion.sh` for I/O. Migration converts each existing `.md` to a single initial assertion and deletes `_archive/` directories from #40.

**Tech Stack:** Bash + `jq` (already a project dependency per `scripts/bump-version.sh`). LLM-driven SKILL.md updates for orchestrator, show, and the migration apply. Pure functions tested via bash assertion script under `tests/nemawashi-analyze/`.

---

## File Structure

- **Create**: `skills/nemawashi-analyze/assertion.sh` — append / render / render-to-file / fold / history subcommands.
- **Create**: `tests/nemawashi-analyze/test-assertion.sh` — TDD test cases.
- **Create**: `skills/nemawashi-migrate/migrations/04-frameworks-temporal-model.sh` — detect (eligible = `.md` exists, `.jsonl` absent).
- **Create**: `skills/nemawashi-migrate/migrations/04-frameworks-temporal-model.md` — LLM apply instructions.
- **Modify**: `skills/nemawashi-analyze/OUTPUT-FORMAT.md` — add the JSONL assertion schema; note that .md is now a derived snapshot.
- **Modify**: `agents/framework-analyzer.md` — new write contract (append .jsonl, render .md).
- **Modify**: `skills/nemawashi-analyze/SKILL.md` — remove Step 1.5 (#40 pre-archive obsolete).
- **Modify**: `skills/nemawashi-show/SKILL.md` — add `--as-of` and `--history` flags.
- **Delete**: `skills/nemawashi-analyze/archive.sh` and `tests/nemawashi-analyze/test-archive.sh` — obsolete once Step 1.5 is removed and `_archive/` is migrated away.

---

## Task 1: `assertion.sh` helper + tests

The foundational unit. All other tasks depend on this.

**Files:**
- Create: `skills/nemawashi-analyze/assertion.sh`
- Create: `tests/nemawashi-analyze/test-assertion.sh`

### Subcommand surface

```
assertion.sh append <jsonl-path> <json-string>
  - Validates json (required fields present, confidence in enum), appends as one line.
  - Idempotent on EOF newline normalization.

assertion.sh render <json-string> <framework-definition-path>
  - Emits markdown body (with frontmatter) to stdout.
  - Reads framework definition file to look up the output_label for the header.

assertion.sh render-to-file <jsonl-path> <md-path> <framework-definition-path>
  - Reads the latest line of jsonl, calls render, writes to md atomically (temp + mv).

assertion.sh fold <jsonl-path> [--as-of YYYY-MM-DD]
  - With no flag: emits the last line.
  - With --as-of: emits the last line where asserted_at <= <date>T23:59:59Z.
  - If no entry matches, exit 0 with empty output (caller decides).

assertion.sh history <jsonl-path>
  - For each line in order, prints "<asserted_at>: <classification> (<confidence>)" to stdout.
```

### Step 1.1: Write the failing test script

- [ ] Create `tests/nemawashi-analyze/test-assertion.sh`:

```bash
#!/usr/bin/env bash
# test-assertion.sh — self-contained tests for assertion.sh
# Run: bash tests/nemawashi-analyze/test-assertion.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ASSERTION="$REPO_ROOT/skills/nemawashi-analyze/assertion.sh"
[ -x "$ASSERTION" ] || { echo "assertion.sh not executable: $ASSERTION" >&2; exit 1; }

# Locate a real framework definition file for render tests (needs output_label).
FRAMEWORK_DEF="$REPO_ROOT/skills/nemawashi-analyze/frameworks/thomas-kilmann-tki.md"
[ -f "$FRAMEWORK_DEF" ] || { echo "framework def missing: $FRAMEWORK_DEF" >&2; exit 1; }

PASS=0
FAIL=0

assert_eq() {
  if [ "$2" = "$3" ]; then
    printf "PASS  %s\n" "$1"
    PASS=$((PASS + 1))
  else
    printf "FAIL  %s\n        expected: %s\n        actual:   %s\n" "$1" "$2" "$3"
    FAIL=$((FAIL + 1))
  fi
}
assert_contains() {
  # assert_contains <label> <haystack> <needle>
  if echo "$2" | grep -qF "$3"; then
    printf "PASS  %s\n" "$1"
    PASS=$((PASS + 1))
  else
    printf "FAIL  %s\n        expected to contain: %s\n        actual:\n%s\n" "$1" "$3" "$2"
    FAIL=$((FAIL + 1))
  fi
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SAMPLE_JSON='{"asserted_at":"2026-05-19T09:53:39Z","framework":"thomas-kilmann-tki","classification":"Collaborating primary","classification_detail":"Default mode is Collaborating.","confidence":"Confirmed","facts_snapshot_count":7,"evidence":[{"date":"2026-03-27","source":"slack","quote":"sample quote","signal_tag":"TKI:collaborating","reasoning":"sample reasoning"}],"rules":{"requesting":{"do":[{"text":"sample do","signal_tag":"TKI:collaborating"}],"dont":[]},"conflict":{"do":[],"dont":[]},"reporting":{"do":[],"dont":[]},"routine":{"do":[],"dont":[]}},"data_gap_reason":null}'

# --- append
JSONL="$TMP/case1.jsonl"
"$ASSERTION" append "$JSONL" "$SAMPLE_JSON"
LINES=$(wc -l < "$JSONL")
assert_eq "append: file has 1 line after first append" "1" "$LINES"

"$ASSERTION" append "$JSONL" "$SAMPLE_JSON"
LINES=$(wc -l < "$JSONL")
assert_eq "append: file has 2 lines after second append" "2" "$LINES"

# --- append rejects invalid json
set +e
"$ASSERTION" append "$JSONL" "not json" 2>/dev/null
RC=$?
set -e
assert_eq "append: rejects non-JSON input (exit non-zero)" "true" "$( [ "$RC" -ne 0 ] && echo true || echo false )"

# --- append rejects missing required field
set +e
"$ASSERTION" append "$JSONL" '{"framework":"x"}' 2>/dev/null
RC=$?
set -e
assert_eq "append: rejects JSON missing required field (exit non-zero)" "true" "$( [ "$RC" -ne 0 ] && echo true || echo false )"

# --- render produces a parseable markdown body
RENDERED=$("$ASSERTION" render "$SAMPLE_JSON" "$FRAMEWORK_DEF")
assert_contains "render: frontmatter framework slug" "$RENDERED" "framework: thomas-kilmann-tki"
assert_contains "render: frontmatter classification" "$RENDERED" "classification: Collaborating primary"
assert_contains "render: frontmatter confidence" "$RENDERED" "confidence: Confirmed"
assert_contains "render: frontmatter last_updated derives from asserted_at" "$RENDERED" "last_updated: 2026-05-19"
assert_contains "render: body has Classification section" "$RENDERED" "## Classification"
assert_contains "render: body has classification_detail" "$RENDERED" "Default mode is Collaborating."
assert_contains "render: body has Evidence section" "$RENDERED" "## Evidence"
assert_contains "render: evidence bullet has date+source" "$RENDERED" "[2026-03-27] [slack]"
assert_contains "render: body has Rules section" "$RENDERED" "## Rules"
assert_contains "render: When Requesting subsection" "$RENDERED" "### When Requesting"

# --- render-to-file: writes the latest assertion to md
JSONL2="$TMP/case2.jsonl"
"$ASSERTION" append "$JSONL2" "$SAMPLE_JSON"
NEWER_JSON='{"asserted_at":"2026-06-01T12:00:00Z","framework":"thomas-kilmann-tki","classification":"Avoiding now","classification_detail":"Updated.","confidence":"Hypothesis","facts_snapshot_count":10,"evidence":[],"rules":{"requesting":{"do":[],"dont":[]},"conflict":{"do":[],"dont":[]},"reporting":{"do":[],"dont":[]},"routine":{"do":[],"dont":[]}},"data_gap_reason":null}'
"$ASSERTION" append "$JSONL2" "$NEWER_JSON"
MD2="$TMP/case2.md"
"$ASSERTION" render-to-file "$JSONL2" "$MD2" "$FRAMEWORK_DEF"
assert_contains "render-to-file: uses latest line (Avoiding now)" "$(cat "$MD2")" "classification: Avoiding now"
assert_contains "render-to-file: uses latest line (Hypothesis)" "$(cat "$MD2")" "confidence: Hypothesis"

# --- fold: default returns last line
LAST=$("$ASSERTION" fold "$JSONL2")
LAST_AT=$(echo "$LAST" | jq -r '.asserted_at')
assert_eq "fold: default returns latest entry" "2026-06-01T12:00:00Z" "$LAST_AT"

# --- fold: --as-of picks earlier entry
PICK=$("$ASSERTION" fold "$JSONL2" --as-of 2026-05-20)
PICK_AT=$(echo "$PICK" | jq -r '.asserted_at')
assert_eq "fold: --as-of=2026-05-20 picks 2026-05-19 entry" "2026-05-19T09:53:39Z" "$PICK_AT"

# --- fold: --as-of before any entry returns empty
EARLY=$("$ASSERTION" fold "$JSONL2" --as-of 2026-01-01)
assert_eq "fold: --as-of before any entry returns empty" "" "$EARLY"

# --- history: lists entries chronologically
HIST=$("$ASSERTION" history "$JSONL2")
LINE1=$(echo "$HIST" | sed -n '1p')
LINE2=$(echo "$HIST" | sed -n '2p')
assert_contains "history: line 1 has older asserted_at" "$LINE1" "2026-05-19T09:53:39Z"
assert_contains "history: line 2 has newer asserted_at" "$LINE2" "2026-06-01T12:00:00Z"
assert_contains "history: line 1 has classification" "$LINE1" "Collaborating primary"
assert_contains "history: line 2 has confidence" "$LINE2" "Hypothesis"

# --- Data Gap variant: rules can be empty {}
DATAGAP_JSON='{"asserted_at":"2026-05-19T09:53:39Z","framework":"thomas-kilmann-tki","classification":"Data Gap","classification_detail":"Insufficient signals.","confidence":"Data Gap","facts_snapshot_count":2,"evidence":[],"rules":{"requesting":{"do":[],"dont":[]},"conflict":{"do":[],"dont":[]},"reporting":{"do":[],"dont":[]},"routine":{"do":[],"dont":[]}},"data_gap_reason":"Need more signals from stress contexts."}'
JSONL3="$TMP/case3.jsonl"
"$ASSERTION" append "$JSONL3" "$DATAGAP_JSON"
RENDERED_DG=$("$ASSERTION" render "$DATAGAP_JSON" "$FRAMEWORK_DEF")
assert_contains "render Data Gap: has Data Gap section" "$RENDERED_DG" "## Data Gap"
assert_contains "render Data Gap: includes data_gap_reason text" "$RENDERED_DG" "Need more signals from stress contexts."

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] Make executable:

```bash
chmod +x tests/nemawashi-analyze/test-assertion.sh
```

### Step 1.2: Verify test fails (no assertion.sh yet)

- [ ] Run:

```bash
bash tests/nemawashi-analyze/test-assertion.sh
```

Expected: `assertion.sh not executable: ...` and exit 1.

### Step 1.3: Implement `assertion.sh`

- [ ] Create `skills/nemawashi-analyze/assertion.sh`:

```bash
#!/usr/bin/env bash
# assertion.sh — append-only assertion log helper for framework analysis.
#
# Subcommands:
#   append <jsonl-path> <json-string>
#     Validates JSON + required fields, appends one line.
#
#   render <json-string> <framework-definition-path>
#     Emits markdown body (frontmatter + sections) to stdout.
#
#   render-to-file <jsonl-path> <md-path> <framework-definition-path>
#     Reads the latest assertion from <jsonl-path>, renders, writes atomically.
#
#   fold <jsonl-path> [--as-of YYYY-MM-DD]
#     Default: emits last line.
#     --as-of: emits last entry where asserted_at <= <date>T23:59:59Z.
#     Empty result if no entry matches.
#
#   history <jsonl-path>
#     Prints "<asserted_at>: <classification> (<confidence>)" per line, in order.
set -euo pipefail

REQUIRED_FIELDS="asserted_at framework classification classification_detail confidence facts_snapshot_count evidence rules data_gap_reason"

usage() {
  sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'
}

sub_append() {
  local jsonl="${1:-}" payload="${2:-}"
  [ -n "$jsonl" ] && [ -n "$payload" ] || { usage >&2; exit 2; }
  echo "$payload" | jq -e . >/dev/null || { echo "append: invalid JSON" >&2; exit 1; }
  local f
  for f in $REQUIRED_FIELDS; do
    echo "$payload" | jq -e "has(\"$f\")" >/dev/null \
      || { echo "append: missing required field: $f" >&2; exit 1; }
  done
  # Compact to single line, append.
  echo "$payload" | jq -c . >> "$jsonl"
}

# Extract output_label from a framework definition file's YAML frontmatter.
fetch_output_label() {
  local def="$1"
  awk '
    NR==1 && $0=="---" { in_fm=1; next }
    in_fm && $0=="---" { exit }
    in_fm && /^output_label:[[:space:]]*/ {
      sub(/^output_label:[[:space:]]*/, "")
      sub(/^"/, ""); sub(/"$/, "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$def"
}

sub_render() {
  local payload="${1:-}" def="${2:-}"
  [ -n "$payload" ] && [ -n "$def" ] || { usage >&2; exit 2; }
  local label
  label=$(fetch_output_label "$def")
  [ -n "$label" ] || { echo "render: output_label missing in $def" >&2; exit 1; }

  local last_updated
  last_updated=$(echo "$payload" | jq -r '.asserted_at' | cut -c1-10)

  local framework classification classification_detail confidence confidence_lower
  framework=$(echo "$payload" | jq -r '.framework')
  classification=$(echo "$payload" | jq -r '.classification')
  classification_detail=$(echo "$payload" | jq -r '.classification_detail')
  confidence=$(echo "$payload" | jq -r '.confidence')
  confidence_lower=$(echo "$confidence" | tr '[:upper:]' '[:lower:]')

  printf '%s\n' "---"
  printf 'framework: %s\n' "$framework"
  printf 'classification: %s\n' "$classification"
  printf 'confidence: %s\n' "$confidence"
  printf 'last_updated: %s\n' "$last_updated"
  printf '%s\n' "---"
  printf '\n'
  printf '# %s\n\n' "$label"
  printf '## Classification\n'
  printf '%s\n\n' "$classification_detail"

  # Evidence section (omit for Data Gap with empty evidence)
  local ev_count
  ev_count=$(echo "$payload" | jq '.evidence | length')
  if [ "$ev_count" -gt 0 ]; then
    printf '## Evidence\n'
    echo "$payload" | jq -r '.evidence[] | "- [\(.date)] [\(.source)] \(.quote) → \(.reasoning) [signal: \(.signal_tag)]"'
    printf '\n'
  fi

  if [ "$confidence_lower" = "data gap" ]; then
    local reason
    reason=$(echo "$payload" | jq -r '.data_gap_reason // ""')
    printf '## Data Gap\n%s\n' "$reason"
    return 0
  fi

  printf '## Rules\n\n'
  for situation_key in requesting conflict reporting routine; do
    local heading
    case "$situation_key" in
      requesting) heading="When Requesting" ;;
      conflict)   heading="During Conflict" ;;
      reporting)  heading="When Reporting" ;;
      routine)    heading="Routine Collaboration" ;;
    esac
    printf '### %s\n' "$heading"
    printf '**DO:**\n'
    echo "$payload" | jq -r ".rules.${situation_key}.do[]? | \"- \(.text) [signal: \(.signal_tag)]\""
    printf '\n**DON'\''T:**\n'
    echo "$payload" | jq -r ".rules.${situation_key}.dont[]? | \"- \(.text) [signal: \(.signal_tag)]\""
    printf '\n'
  done
}

sub_render_to_file() {
  local jsonl="${1:-}" md="${2:-}" def="${3:-}"
  [ -n "$jsonl" ] && [ -n "$md" ] && [ -n "$def" ] || { usage >&2; exit 2; }
  [ -s "$jsonl" ] || { echo "render-to-file: empty jsonl: $jsonl" >&2; exit 1; }
  local last_line
  last_line=$(tail -n 1 "$jsonl")
  local tmp
  tmp=$(mktemp "${md}.XXXXXX")
  sub_render "$last_line" "$def" > "$tmp"
  mv "$tmp" "$md"
}

sub_fold() {
  local jsonl="${1:-}"
  [ -n "$jsonl" ] || { usage >&2; exit 2; }
  shift
  local as_of=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --as-of) as_of="${2:-}"; shift 2 ;;
      *) usage >&2; exit 2 ;;
    esac
  done
  [ -s "$jsonl" ] || exit 0

  if [ -z "$as_of" ]; then
    tail -n 1 "$jsonl"
    return 0
  fi

  case "$as_of" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) echo "fold: --as-of must be YYYY-MM-DD" >&2; exit 2 ;;
  esac

  local cutoff="${as_of}T23:59:59Z"
  jq -c --arg cutoff "$cutoff" 'select(.asserted_at <= $cutoff)' "$jsonl" | tail -n 1
}

sub_history() {
  local jsonl="${1:-}"
  [ -n "$jsonl" ] || { usage >&2; exit 2; }
  [ -s "$jsonl" ] || exit 0
  jq -r '"\(.asserted_at): \(.classification) (\(.confidence))"' "$jsonl"
}

cmd="${1:-}"
[ -n "$cmd" ] || { usage >&2; exit 2; }
shift
case "$cmd" in
  append)         sub_append "$@" ;;
  render)         sub_render "$@" ;;
  render-to-file) sub_render_to_file "$@" ;;
  fold)           sub_fold "$@" ;;
  history)        sub_history "$@" ;;
  *) usage >&2; exit 2 ;;
esac
```

- [ ] Make executable:

```bash
chmod +x skills/nemawashi-analyze/assertion.sh
```

### Step 1.4: Run test, verify green

- [ ] Run:

```bash
bash tests/nemawashi-analyze/test-assertion.sh
```

Expected: all assertions pass. Exit 0.

If any fail, fix the implementation in `assertion.sh` to match the test expectations. Do NOT relax the test to pass — the test encodes the contract.

### Step 1.5: shellcheck

- [ ] Run:

```bash
pre-commit run shellcheck --files skills/nemawashi-analyze/assertion.sh tests/nemawashi-analyze/test-assertion.sh
```

Expected: Passed.

### Step 1.6: Commit Task 1

- [ ] Stage and commit:

```bash
git add skills/nemawashi-analyze/assertion.sh tests/nemawashi-analyze/test-assertion.sh
git commit -m "$(cat <<'EOF'
feat(analyze): add assertion.sh helper for #41 temporal model

Pure-function helper with subcommands:
- append: validates JSON + required fields, appends one JSONL line
- render: emits markdown body for frameworks/<slug>.md from a JSON assertion
- render-to-file: latest entry of jsonl → markdown, atomic write
- fold: latest entry, optionally filtered by --as-of YYYY-MM-DD
- history: chronological "asserted_at: classification (confidence)" dump

All operations are deterministic. assertion.sh has no I/O on PROFILE_DIR
beyond the paths it's handed. The framework-analyzer agent calls
append + render-to-file; nemawashi-show calls fold + history.

Refs #41.
EOF
)"
```

---

## Task 2: OUTPUT-FORMAT.md schema update

**Files:**
- Modify: `skills/nemawashi-analyze/OUTPUT-FORMAT.md`

### Step 2.1: Read current OUTPUT-FORMAT.md

- [ ] Read `skills/nemawashi-analyze/OUTPUT-FORMAT.md` to locate the `frameworks/<slug>.md` section.

### Step 2.2: Add JSONL schema section

- [ ] Edit `skills/nemawashi-analyze/OUTPUT-FORMAT.md`. After the `frameworks/<slug>.md` section, insert:

```markdown
## frameworks/&lt;slug&gt;.jsonl (source of truth, append-only)

Each line is one assertion — a complete framework analysis at a point in time. New lines are appended on every re-analysis; old lines are never modified. The latest line per file is the current state; `nemawashi-show --as-of YYYY-MM-DD` folds the log to reconstruct the framework view at any past date.

```jsonl
{"asserted_at":"YYYY-MM-DDTHH:MM:SSZ","framework":"<slug>","classification":"<one-line>","classification_detail":"<1-3 sentences>","confidence":"Confirmed|Hypothesis|Data Gap","facts_snapshot_count":N,"evidence":[{"date":"YYYY-MM-DD","source":"<slack|gmail|...>","quote":"<verbatim>","signal_tag":"<framework>:<tag>","reasoning":"<analysis>"}],"rules":{"requesting":{"do":[{"text":"...","signal_tag":"..."}],"dont":[...]},"conflict":{"do":[],"dont":[]},"reporting":{"do":[],"dont":[]},"routine":{"do":[],"dont":[]}},"data_gap_reason":null}
```

| Field | Required | Description |
|---|---|---|
| `asserted_at` | yes | ISO-8601 UTC timestamp, second precision. Identity. |
| `framework` | yes | Slug. Redundant with filename, useful for cross-profile grep. |
| `classification` | yes | One-line summary (matches frontmatter `classification:` in the rendered .md). |
| `classification_detail` | yes | 1-3 sentence expansion (renders under `## Classification`). |
| `confidence` | yes | `Confirmed` / `Hypothesis` / `Data Gap`. |
| `facts_snapshot_count` | yes | How many facts were in facts.jsonl when this was written. Diagnostic. |
| `evidence` | yes | Array of `{date, source, quote, signal_tag, reasoning}`. May be empty for Data Gap. |
| `rules` | yes | Object keyed by 4 situations: `requesting`, `conflict`, `reporting`, `routine`. Each has `do` and `dont` arrays. Empty arrays when not applicable. |
| `data_gap_reason` | yes | String when `confidence == "Data Gap"`, null otherwise. |

**Read paths:**
- Default view (`nemawashi-show <name>`, `nemawashi-reply`): read `.md` (the cached current snapshot).
- Past view: `nemawashi-show <name> --as-of YYYY-MM-DD` → folds `.jsonl` via `assertion.sh fold`.
- History: `nemawashi-show <name> <slug> --history` → `assertion.sh history`.

**Write path:** the framework-analyzer agent calls `assertion.sh append` (jsonl), then `assertion.sh render-to-file` (md). Both writes are inside the agent's invocation.

**Retraction**: latest-wins, no explicit retract entries. "When did classification X stop being current?" = the next entry's `asserted_at`.

See the design spec: `docs/specs/2026-05-19-41-append-only-temporal-model.md`.
```

### Step 2.3: Mark .md as derived

- [ ] In the existing `## frameworks/<slug>.md` section, prepend a note:

```markdown
**Note (post-#41):** This file is now a **derived snapshot** of the latest assertion in `frameworks/<slug>.jsonl`. The .jsonl is the source of truth; the .md is regenerated by `assertion.sh render-to-file` on every analyze pass. Hand-edits to .md will be overwritten on the next run.
```

### Step 2.4: Commit Task 2

- [ ] Stage and commit:

```bash
git add skills/nemawashi-analyze/OUTPUT-FORMAT.md
git commit -m "$(cat <<'EOF'
docs(analyze): document JSONL assertion schema (#41)

Adds the frameworks/<slug>.jsonl section to OUTPUT-FORMAT.md and marks
the .md section as a derived snapshot.

Refs #41.
EOF
)"
```

---

## Task 3: `framework-analyzer` agent: write both .jsonl and .md

**Files:**
- Modify: `agents/framework-analyzer.md`

### Step 3.1: Read current contract

- [ ] Read `agents/framework-analyzer.md`, especially the "What you do" list (Step 8 = atomic write to .md) and the "Constraints" section.

### Step 3.2: Replace Step 8 with the new write contract

- [ ] Edit `agents/framework-analyzer.md`. Replace the existing Step 8 ("Write the output file atomically (temp file in the same dir, then `mv`)") and the Markdown template that follows with:

```markdown
8. **Construct the assertion as a JSON object** with this shape:

   ```json
   {
     "asserted_at": "<today as ISO-8601 UTC, second precision — e.g. 2026-05-19T09:53:39Z>",
     "framework": "<framework_slug>",
     "classification": "<one-line classification text>",
     "classification_detail": "<1-3 sentences expanding the classification>",
     "confidence": "Confirmed | Hypothesis | Data Gap",
     "facts_snapshot_count": <integer: count of facts in facts.jsonl you analyzed against>,
     "evidence": [
       {
         "date": "YYYY-MM-DD",
         "source": "<slack|gmail|calendar|github|manual|...>",
         "quote": "<verbatim quote or paraphrased observation>",
         "signal_tag": "<framework>:<tag>",
         "reasoning": "<short explanation of why this evidence supports the classification>"
       }
     ],
     "rules": {
       "requesting": {
         "do":   [{"text": "<rule>", "signal_tag": "<framework>:<tag>"}],
         "dont": [{"text": "<rule>", "signal_tag": "<framework>:<tag>"}]
       },
       "conflict":  { "do": [...], "dont": [...] },
       "reporting": { "do": [...], "dont": [...] },
       "routine":   { "do": [...], "dont": [...] }
     },
     "data_gap_reason": null
   }
   ```

   For **Data Gap** results: `evidence` may be empty; each `rules.<situation>.do` and `.dont` is `[]`; `data_gap_reason` is a string explaining why insufficient evidence.

9. **Append + render** via the helper at `skills/nemawashi-analyze/assertion.sh`. The orchestrator passes you the `assertion_sh` path; if not, derive it as a sibling of the framework definition's directory.

   - Save the JSON to a temp file (e.g. `/tmp/<slug>.assertion.<pid>.json`) to avoid shell-escaping pitfalls.
   - Append: `bash <assertion_sh> append <profile_dir>/frameworks/<slug>.jsonl "$(cat /tmp/<slug>.assertion.<pid>.json)"`
   - Render: `bash <assertion_sh> render-to-file <profile_dir>/frameworks/<slug>.jsonl <output_path> <framework_definition_path>`
   - Clean up the temp file.

   Both writes are your responsibility. Idempotence belongs to the parent — if a profile didn't need re-analysis, the parent shouldn't have dispatched.
```

### Step 3.3: Update Constraints

- [ ] Edit `agents/framework-analyzer.md`. Under `## Constraints`, replace the "Never write outside `<output_path>`" bullet and the "Orchestrator pre-archives" bullet (added in #40, now obsolete) with:

```markdown
- **You write two files for your slug:** `<output_path>` (the .md) and its `.jsonl` sibling. Never write any other file.
- **Append is the source of truth.** If render-to-file fails after append succeeds, the next analyze pass for this slug will regenerate the .md from the latest entry — do not retry render on its own.
```

Remove the existing line: `- **Orchestrator pre-archives the previous output.** Before dispatching you, `nemawashi-analyze` moves any pre-existing `<output_path>` to `<dir>/_archive/<stem>.<date>.<ext>`. You always write into a clean target. Do NOT invoke the archive step yourself.`

(The pre-archive step is removed in Task 4 because the .jsonl is the archive.)

### Step 3.4: Add assertion_sh to dispatch input

- [ ] In the `## Input you will receive` section, after the `output_path` line, add:

```markdown
- `assertion_sh` — absolute path to `skills/nemawashi-analyze/assertion.sh`
```

### Step 3.5: Commit Task 3

- [ ] Stage and commit:

```bash
git add agents/framework-analyzer.md
git commit -m "$(cat <<'EOF'
feat(agents): framework-analyzer writes JSONL + renders .md (#41)

The agent now emits a JSON assertion and calls assertion.sh to:
1. Append the assertion to frameworks/<slug>.jsonl (source of truth)
2. Render-to-file the .md (derived snapshot, atomic write)

Removes the #40 "orchestrator pre-archives" constraint — the .jsonl
log makes _archive/ obsolete.

Refs #41.
EOF
)"
```

---

## Task 4: `nemawashi-analyze` SKILL.md: remove Step 1.5

**Files:**
- Modify: `skills/nemawashi-analyze/SKILL.md`

### Step 4.1: Remove Step 1.5 wholesale

- [ ] Edit `skills/nemawashi-analyze/SKILL.md`. Delete the entire `### Step 1.5: Archive existing output files` block (from the heading through the closing paragraph that mentions `contradictions.md`). Step 2 follows Step 1 directly again.

### Step 4.2: Add `assertion_sh` to the dispatch prompt

- [ ] Edit the `#### Dispatch prompt per agent` block. After the `output_path:` line, add:

```markdown
assertion_sh:                <absolute path to skills/nemawashi-analyze/assertion.sh>
```

### Step 4.3: Update Key Principles

- [ ] Edit `skills/nemawashi-analyze/SKILL.md`. Under `## Key Principles`, replace the bullet that says "Archive before overwrite" with:

```markdown
- **Append-only assertion log.** Prior versions of each `frameworks/<slug>.md` are preserved in `frameworks/<slug>.jsonl` (one assertion per analyze pass, append-only). The .md is regenerated from the latest assertion on every run. Time-travel via `nemawashi-show --as-of YYYY-MM-DD`.
```

### Step 4.4: Commit Task 4

- [ ] Stage and commit:

```bash
git add skills/nemawashi-analyze/SKILL.md
git commit -m "$(cat <<'EOF'
feat(analyze): remove pre-archive Step 1.5; pass assertion.sh to agents (#41)

The pre-archive step (#40) is obsolete — frameworks/<slug>.jsonl is the
new archive. Drop the step and update Key Principles. The dispatch
prompt now passes assertion.sh's path so each framework-analyzer agent
can append + render.

Refs #41.
EOF
)"
```

---

## Task 5: `nemawashi-show` SKILL.md: add --as-of and --history

**Files:**
- Modify: `skills/nemawashi-show/SKILL.md`

### Step 5.1: Read current SKILL.md to locate the right insertion point

- [ ] Read `skills/nemawashi-show/SKILL.md`. Identify the section that documents the supported invocation forms.

### Step 5.2: Document the new flags

- [ ] Edit `skills/nemawashi-show/SKILL.md`. Add a new section after the existing usage docs:

```markdown
## Time-travel flags (#41)

### `nemawashi-show <name> --as-of YYYY-MM-DD`

Reconstructs the per-framework view as it was on a past date. For each `PROFILE_DIR/<name>/frameworks/<slug>.jsonl`:

```bash
ASSERTION=<skill-root>/../nemawashi-analyze/assertion.sh
for jsonl in PROFILE_DIR/<name>/frameworks/*.jsonl; do
  slug=$(basename "$jsonl" .jsonl)
  def=<this-marketplace>/nemawashi-analyze/frameworks/$slug.md
  entry=$(bash "$ASSERTION" fold "$jsonl" --as-of YYYY-MM-DD)
  if [ -n "$entry" ]; then
    bash "$ASSERTION" render "$entry" "$def"
  else
    echo "$slug: no analysis as of YYYY-MM-DD"
  fi
done
```

Render the framework outputs in the same shape as today's `nemawashi-show <name>` view.

If a framework's `.jsonl` does not exist (profile has not been migrated to the temporal model yet), fall back to reading `.md` directly and note the limitation in the output.

### `nemawashi-show <name> <slug> --history`

Prints the chronological assertion log for one framework:

```bash
ASSERTION=<skill-root>/../nemawashi-analyze/assertion.sh
bash "$ASSERTION" history PROFILE_DIR/<name>/frameworks/<slug>.jsonl
```

Output is one line per assertion: `<asserted_at>: <classification> (<confidence>)`.

For a diff between two specific dates, the user can:

```bash
DATE_A=2026-03-01
DATE_B=2026-05-01
diff \
  <(bash "$ASSERTION" render "$(bash "$ASSERTION" fold "$jsonl" --as-of $DATE_A)" "$def") \
  <(bash "$ASSERTION" render "$(bash "$ASSERTION" fold "$jsonl" --as-of $DATE_B)" "$def")
```

A dedicated `nemawashi-diff` skill is on the roadmap but out of scope for this work — see the spec's "Open follow-ups".
```

### Step 5.3: Commit Task 5

- [ ] Stage and commit:

```bash
git add skills/nemawashi-show/SKILL.md
git commit -m "$(cat <<'EOF'
feat(show): add --as-of and --history time-travel flags (#41)

nemawashi-show <name> --as-of YYYY-MM-DD reconstructs the framework
view at a past date by folding frameworks/<slug>.jsonl.

nemawashi-show <name> <slug> --history prints the chronological
assertion log for one framework.

Both consume assertion.sh from the nemawashi-analyze skill directory.

Refs #41.
EOF
)"
```

---

## Task 6: Migration `04-frameworks-temporal-model`

**Files:**
- Create: `skills/nemawashi-migrate/migrations/04-frameworks-temporal-model.sh`
- Create: `skills/nemawashi-migrate/migrations/04-frameworks-temporal-model.md`

### Step 6.1: Create the detect script

- [ ] Create `skills/nemawashi-migrate/migrations/04-frameworks-temporal-model.sh`:

```bash
#!/usr/bin/env bash
# shellcheck disable=SC1091
# 04-frameworks-temporal-model.sh — Detect profiles eligible for the
# frameworks/<slug>.md → frameworks/<slug>.jsonl temporal-model migration.
#
# A profile is eligible if at least one of its frameworks/<slug>.md has no
# corresponding frameworks/<slug>.jsonl. The apply phase (LLM-driven,
# instructions in the matching .md) reads each .md, writes an initial
# assertion to its .jsonl, and deletes any _archive/ directories left over
# from #40.
#
# Usage:
#   04-frameworks-temporal-model.sh --detect

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

is_eligible() {
  local dir="$1"
  local f
  for f in "$dir"frameworks/*.md; do
    [ -f "$f" ] || continue
    local slug
    slug=$(basename "$f" .md)
    if [ ! -f "${dir}frameworks/${slug}.jsonl" ]; then
      return 0
    fi
  done
  return 1
}

migration_main "04-frameworks-temporal-model" is_eligible "$@"
```

- [ ] Make executable:

```bash
chmod +x skills/nemawashi-migrate/migrations/04-frameworks-temporal-model.sh
```

### Step 6.2: Verify detect runs against a real profile dir

- [ ] Run:

```bash
bash skills/nemawashi-migrate/migrations/04-frameworks-temporal-model.sh --detect
```

Expected output (with 19 profiles, none yet migrated): `04-frameworks-temporal-model: 19 profile(s) eligible`.

If it says fewer or zero, walk through `is_eligible` against one profile to debug.

### Step 6.3: Create the apply markdown

- [ ] Create `skills/nemawashi-migrate/migrations/04-frameworks-temporal-model.md`:

```markdown
---
id: 04-frameworks-temporal-model
detect: 04-frameworks-temporal-model.sh
---

# Migration: frameworks/<slug>.md → frameworks/<slug>.jsonl (temporal model)

Convert each existing per-framework markdown analysis into one initial JSONL assertion entry, then delete the `_archive/` directories that #40 created. The .md stays in place — it becomes the cached current view, regenerated by `assertion.sh render-to-file` on every subsequent analyze.

The detection part is bash (`04-frameworks-temporal-model.sh --detect`). The apply below is LLM-driven so it tolerates the format drift accumulated in legacy .md files.

## Source format

Each `frameworks/<slug>.md` has YAML frontmatter and a body. Frontmatter fields:

- `framework: <slug>`
- `classification: <one-line>`
- `confidence: Confirmed | Hypothesis | Data Gap`
- `last_updated: YYYY-MM-DD`

Body sections (Confirmed / Hypothesis variant):

- `# <output_label>` — the framework display name.
- `## Classification` — 1-3 sentences expanding the frontmatter classification.
- `## Evidence` — bullets shaped roughly `- [YYYY-MM-DD] [source] <quote> → <reasoning> [signal: <tag>]`.
- `## Rules` with sub-sections `### When Requesting`, `### During Conflict`, `### When Reporting`, `### Routine Collaboration`. Each has `**DO:**` and `**DON'T:**` bullet lists.

Body sections (Data Gap variant):

- `# <output_label>`
- `## Classification` — the explanation of insufficient signals.
- `## Evidence` — may be empty or have ambiguous bullets.
- `## Data Gap` (no `## Rules`) — text describing what's missing and what would unblock classification.

## Target format

One JSONL line per `frameworks/<slug>.md`, written to `frameworks/<slug>.jsonl`, matching the schema in `skills/nemawashi-analyze/OUTPUT-FORMAT.md` (the new "frameworks/<slug>.jsonl" section).

## Apply, per eligible profile

For each `frameworks/<slug>.md` that does NOT already have a sibling `<slug>.jsonl`:

1. **Read the .md.** Parse the frontmatter and the body sections enumerated above.
2. **Build the JSON object** matching the assertion schema:
   - `asserted_at`: `<last_updated frontmatter value>T00:00:00Z`.
   - `framework`: from frontmatter (must equal the filename slug — if not, surface and skip).
   - `classification`: from frontmatter `classification:`.
   - `classification_detail`: the prose under `## Classification`.
   - `confidence`: from frontmatter.
   - `facts_snapshot_count`: parse from `profile.md`'s `<!-- analyzed: YYYY-MM-DD, facts_count: N -->` comment. If absent, set to `0`.
   - `evidence`: array of `{date, source, quote, signal_tag, reasoning}`. Tolerate the existing bullet variants; if a bullet can't be parsed, record it in the per-profile report and skip that single bullet (do not crash).
   - `rules`: object keyed by `requesting / conflict / reporting / routine`. Each value `{do: [...], dont: [...]}` of `{text, signal_tag}`. For Data Gap variants, all four are `{do: [], dont: []}`.
   - `data_gap_reason`: text under `## Data Gap` for the Data Gap variant; `null` otherwise.
3. **Append via assertion.sh**:
   ```
   bash skills/nemawashi-analyze/assertion.sh append <profile_dir>/frameworks/<slug>.jsonl "$(cat /tmp/<slug>.<pid>.json)"
   ```
   Use a temp file for the JSON to avoid shell-escape issues; clean up after.
4. **Verify**: `bash skills/nemawashi-analyze/assertion.sh fold <jsonl>` should return the just-written entry. Spot-check that `last_updated` in the frontmatter equals the date part of `asserted_at`.
5. **Do NOT rewrite the .md.** It is intentionally left as-is — it becomes the cached current view until the next analyze regenerates it. (If the migration round-tripped the .md, it might differ in whitespace / phrasing, which would confuse `git diff`-style audits.)

After all `<slug>.md` files for a profile are processed:

6. **Delete `_archive/` directories created by #40** (if any):
   - `rm -rf <profile_dir>/_archive`
   - `rm -rf <profile_dir>/frameworks/_archive`
   These directories hold pre-archived copies that are no longer needed — the .jsonl is the new archive. The spec deliberately discards them rather than backfilling.

## Verify, per eligible profile

After conversion:

- Every `frameworks/<slug>.md` in the profile has a sibling `frameworks/<slug>.jsonl` with exactly 1 line.
- Re-running `04-frameworks-temporal-model.sh --detect` against this profile should no longer report it as eligible.
- `_archive/` directories are gone from both `<profile_dir>/` and `<profile_dir>/frameworks/`.

## Out of scope

- Backfilling assertions from `_archive/` content. Old `.md` snapshots in `_archive/` are discarded — the migration starts the temporal log from "now".
- Updating `profile.md` Core Pattern or `contradictions.md`. Those are regenerated on next `nemawashi-analyze`; nothing to migrate.
- Updating `relationship.md` (deferred to a separate issue — see spec "Open follow-ups").
```

### Step 6.4: Commit Task 6

- [ ] Stage and commit:

```bash
git add skills/nemawashi-migrate/migrations/04-frameworks-temporal-model.sh \
        skills/nemawashi-migrate/migrations/04-frameworks-temporal-model.md
git commit -m "$(cat <<'EOF'
feat(migrate): add 04-frameworks-temporal-model migration (#41)

Detects profiles with a frameworks/<slug>.md but no matching <slug>.jsonl.
Apply is LLM-driven: for each .md, parse into the new assertion schema,
append via assertion.sh, leave the .md intact, and delete _archive/
directories left over from #40.

Refs #41.
EOF
)"
```

---

## Task 7: Delete obsolete #40 stop-gap

**Files:**
- Delete: `skills/nemawashi-analyze/archive.sh`
- Delete: `tests/nemawashi-analyze/test-archive.sh`

The pre-archive step was a stop-gap until #41 landed. With this PR shipping the temporal model and the migration removing existing `_archive/` directories, the helper is dead code.

### Step 7.1: Remove the files

- [ ] Run:

```bash
git rm skills/nemawashi-analyze/archive.sh tests/nemawashi-analyze/test-archive.sh
```

### Step 7.2: Verify no remaining references

- [ ] Run:

```bash
grep -rn "archive.sh" --include='*.md' --include='*.sh' --include='*.yaml' . 2>/dev/null | grep -v ".git/" | grep -v "_archive"
```

Expected: empty (no references to `archive.sh` anywhere). If any remain, fix them.

### Step 7.3: Commit Task 7

- [ ] Commit:

```bash
git commit -m "$(cat <<'EOF'
chore: remove obsolete archive.sh stop-gap (#41)

The pre-archive step from #40 is replaced by the append-only assertion
log. Migration 04-frameworks-temporal-model deletes the _archive/
directories left over from #40 on each profile.

Refs #41.
EOF
)"
```

---

## Task 8: End-to-end smoke test

**Files:** none.

### Step 8.1: Pick a copy of a real profile

- [ ] Run:

```bash
TMP=$(mktemp -d)
SRC="$HOME/.local/share/supernemawashi/profiles/kimishima"
[ -d "$SRC" ] || { echo "no real profile available; skip"; exit 0; }
cp -r "$SRC" "$TMP/"
PROF="$TMP/kimishima"
ls -la "$PROF/frameworks/"
```

Expected: 6 framework `.md` files, no `.jsonl`.

### Step 8.2: Verify detect reports eligibility

- [ ] Run (override PROFILE_DIR to point at the temp copy):

```bash
PROFILE_DIR="$TMP" bash skills/nemawashi-migrate/migrations/04-frameworks-temporal-model.sh --detect
```

Expected: `04-frameworks-temporal-model: 1 profile(s) eligible`.

### Step 8.3: Run the migration apply manually

The migration is LLM-driven, so we exercise it ourselves: for one framework, read the .md, build the JSON, and call `assertion.sh append`.

- [ ] Pick `thomas-kilmann-tki.md`:

```bash
SLUG=thomas-kilmann-tki
MD="$PROF/frameworks/$SLUG.md"
JSONL="$PROF/frameworks/$SLUG.jsonl"
DEF="skills/nemawashi-analyze/frameworks/$SLUG.md"

# Build a minimal valid assertion derived from the .md frontmatter. We use the
# documented last_updated as asserted_at. evidence/rules left empty for this
# smoke (we're testing plumbing, not the full LLM-driven parse).
LAST_UPDATED=$(awk '/^last_updated:/{print $2; exit}' "$MD")
CLASSIFICATION=$(awk -F': ' '/^classification:/{$1=""; sub(/^ /, ""); print; exit}' "$MD")
CONFIDENCE=$(awk -F': ' '/^confidence:/{$1=""; sub(/^ /, ""); print; exit}' "$MD")

JSON=$(jq -n \
  --arg at "${LAST_UPDATED}T00:00:00Z" \
  --arg slug "$SLUG" \
  --arg cl "$CLASSIFICATION" \
  --arg conf "$CONFIDENCE" \
  '{
    asserted_at: $at,
    framework: $slug,
    classification: $cl,
    classification_detail: "Smoke test — body prose not parsed.",
    confidence: $conf,
    facts_snapshot_count: 7,
    evidence: [],
    rules: {
      requesting: {do: [], dont: []},
      conflict:   {do: [], dont: []},
      reporting:  {do: [], dont: []},
      routine:    {do: [], dont: []}
    },
    data_gap_reason: null
  }')

bash skills/nemawashi-analyze/assertion.sh append "$JSONL" "$JSON"
wc -l "$JSONL"
```

Expected: `1 <path>` — one line in the new .jsonl.

### Step 8.4: Verify fold and history

- [ ] Run:

```bash
bash skills/nemawashi-analyze/assertion.sh fold "$JSONL" | jq -r .classification
# Expected: the classification text from the .md.

bash skills/nemawashi-analyze/assertion.sh history "$JSONL"
# Expected: one line "<asserted_at>: <classification> (<confidence>)".

bash skills/nemawashi-analyze/assertion.sh fold "$JSONL" --as-of 2020-01-01
# Expected: empty output.
```

### Step 8.5: Verify render-to-file

- [ ] Run:

```bash
TMP_MD="$TMP/render.md"
bash skills/nemawashi-analyze/assertion.sh render-to-file "$JSONL" "$TMP_MD" "$DEF"
head -20 "$TMP_MD"
```

Expected: a `frameworks/<slug>.md` shape — frontmatter (framework, classification, confidence, last_updated) + `# Conflict Mode (TKI)` header + `## Classification` body.

### Step 8.6: Cleanup smoke artifacts

- [ ] Run:

```bash
rm -rf "$TMP"
```

No commit for this task — smoke verification only.

---

## Self-Review Checklist

- [ ] **Spec coverage**:
  - Coarse granularity (1 assertion = whole framework) → schema in Task 1/2, agent contract in Task 3.
  - Latest-wins (no retract) → `fold` defaults to last line; no retract subcommand.
  - frameworks/<slug>.jsonl as source of truth → Task 2 doc.
  - Sidecar .md regenerated → render-to-file in Task 1, called by agent in Task 3.
  - ISO timestamp identity → Task 1 (.asserted_at validation), Task 3 (agent emits ISO).
  - Self-contained evidence (no fact-ID FK) → schema in Task 1/2.
  - Migration discards _archive/ → Task 6 step 6, Task 7 deletes archive.sh.
  - `--as-of` and `--history` read paths → Task 5.
- [ ] **Placeholder scan**: every step has code or exact command. No TBD/TODO.
- [ ] **Type consistency**: subcommand names match between Task 1 implementation and Tasks 3, 5, 6 usage.
- [ ] **Out-of-scope items from spec are absent**: no relationship.md temporal treatment, no nemawashi-diff / nemawashi-revert, no fact-ID FK migration, no reaffirm entry.

---

## Done When

- [ ] Task 1: `assertion.sh` + tests pass.
- [ ] Task 2: OUTPUT-FORMAT.md documents the JSONL schema.
- [ ] Task 3: framework-analyzer.md describes the new write contract.
- [ ] Task 4: nemawashi-analyze SKILL.md has Step 1.5 removed and Key Principles updated.
- [ ] Task 5: nemawashi-show SKILL.md documents `--as-of` and `--history`.
- [ ] Task 6: migration files exist and detect returns expected count.
- [ ] Task 7: archive.sh + test-archive.sh removed; no dangling references.
- [ ] Task 8: smoke test on a real profile copy demonstrates the round trip.
- [ ] All commits on branch `feat/41-append-only-temporal-model`.
- [ ] `pre-commit run --all-files` passes.

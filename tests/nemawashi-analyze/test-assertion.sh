#!/usr/bin/env bash
# test-assertion.sh — self-contained tests for skills/nemawashi-analyze/assertion.sh
# Run: bash tests/nemawashi-analyze/test-assertion.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ASSERTION="$REPO_ROOT/skills/nemawashi-analyze/assertion.sh"
[ -x "$ASSERTION" ] || { echo "assertion.sh not executable: $ASSERTION" >&2; exit 1; }

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

# --- Data Gap variant: rules can be empty, data_gap_reason in body
DATAGAP_JSON='{"asserted_at":"2026-05-19T09:53:39Z","framework":"thomas-kilmann-tki","classification":"Data Gap","classification_detail":"Insufficient signals.","confidence":"Data Gap","facts_snapshot_count":2,"evidence":[],"rules":{"requesting":{"do":[],"dont":[]},"conflict":{"do":[],"dont":[]},"reporting":{"do":[],"dont":[]},"routine":{"do":[],"dont":[]}},"data_gap_reason":"Need more signals from stress contexts."}'
JSONL3="$TMP/case3.jsonl"
"$ASSERTION" append "$JSONL3" "$DATAGAP_JSON"
RENDERED_DG=$("$ASSERTION" render "$DATAGAP_JSON" "$FRAMEWORK_DEF")
assert_contains "render Data Gap: has Data Gap section" "$RENDERED_DG" "## Data Gap"
assert_contains "render Data Gap: includes data_gap_reason text" "$RENDERED_DG" "Need more signals from stress contexts."

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]

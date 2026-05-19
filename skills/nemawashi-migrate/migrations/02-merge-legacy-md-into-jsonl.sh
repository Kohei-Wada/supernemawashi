#!/usr/bin/env bash
# shellcheck disable=SC1091
# 02-merge-legacy-md-into-jsonl.sh — Detect profiles where the legacy
# facts.md covers dates the new facts.jsonl does not.
#
# This is the "coverage gap" case: a profile has both files, but the
# jsonl was produced by a `nemawashi-collect` run on a later date window,
# so the md still holds earlier (or later) facts that aren't reflected
# in the jsonl. 90-delete-legacy-facts-md (cleanup phase) correctly
# refuses to delete in this state. 02 closes the gap by merging the
# missing md entries into the jsonl; 90 then picks up the cleaned state
# in the same round.
#
# Usage:
#   02-merge-legacy-md-into-jsonl.sh --detect

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../../lib/migration.sh"

is_eligible() {
  local dir="$1"
  local md="$dir/facts.md"
  local jsonl="$dir/facts.jsonl"
  [ -f "$md" ] || return 1
  [ -f "$jsonl" ] || return 1

  # Lex-compare aligns with chronological for YYYY-MM[-DD].
  local md_dates jsonl_dates md_min md_max jsonl_min jsonl_max
  md_dates=$(extract_md_dates "$md")
  [ -n "$md_dates" ] || return 1
  jsonl_dates=$(extract_jsonl_dates "$jsonl")
  [ -n "$jsonl_dates" ] || return 1

  md_min=$(printf '%s\n' "$md_dates"    | sort    | head -1)
  md_max=$(printf '%s\n' "$md_dates"    | sort -r | head -1)
  jsonl_min=$(printf '%s\n' "$jsonl_dates" | sort    | head -1)
  jsonl_max=$(printf '%s\n' "$jsonl_dates" | sort -r | head -1)

  # Eligible if md has entries outside jsonl's range.
  [[ "$jsonl_min" > "$md_min" || "$jsonl_max" < "$md_max" ]]
}

migration_main "02-merge-legacy-md-into-jsonl" is_eligible "$@"

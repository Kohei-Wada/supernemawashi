#!/usr/bin/env bash
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

PROFILE_DIR="${PROFILE_DIR:-$HOME/.local/share/supernemawashi/profiles}"
MIGRATION_ID="02-merge-legacy-md-into-jsonl"

mode=""
for arg in "$@"; do
  case "$arg" in
    --detect) mode="detect" ;;
    *)
      echo "Usage: $0 --detect" >&2
      exit 2
      ;;
  esac
done

[ "$mode" = "detect" ] || { echo "Usage: $0 --detect" >&2; exit 2; }
[ -d "$PROFILE_DIR" ] || exit 0

count=0
for dir in "$PROFILE_DIR"/*/; do
  [ -d "$dir" ] || continue
  md="$dir/facts.md"
  jsonl="$dir/facts.jsonl"
  [ -f "$md" ] || continue
  [ -f "$jsonl" ] || continue

  # Extract dates (lex-compare aligns with chronological for YYYY-MM[-DD]).
  md_dates=$(grep -oE '^- \[[0-9]{4}-[0-9]{2}(-[0-9]{2})?\]' "$md" 2>/dev/null \
             | grep -oE '[0-9]{4}-[0-9]{2}(-[0-9]{2})?')
  [ -z "$md_dates" ] && continue
  md_min=$(printf '%s\n' "$md_dates" | sort     | head -1)
  md_max=$(printf '%s\n' "$md_dates" | sort -r  | head -1)

  jsonl_dates=$(grep -oE '"date"[[:space:]]*:[[:space:]]*"[0-9]{4}-[0-9]{2}(-[0-9]{2})?"' "$jsonl" 2>/dev/null \
                | grep -oE '[0-9]{4}-[0-9]{2}(-[0-9]{2})?')
  [ -z "$jsonl_dates" ] && continue
  jsonl_min=$(printf '%s\n' "$jsonl_dates" | sort     | head -1)
  jsonl_max=$(printf '%s\n' "$jsonl_dates" | sort -r  | head -1)

  # Eligible if md has entries outside jsonl's range.
  if [[ "$jsonl_min" > "$md_min" || "$jsonl_max" < "$md_max" ]]; then
    count=$((count + 1))
  fi
done

if [ "$count" -gt 0 ]; then
  printf "%s: %d profile(s) eligible\n" "$MIGRATION_ID" "$count"
fi

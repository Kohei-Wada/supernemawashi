#!/usr/bin/env bash
# 02-delete-legacy-facts-md.sh — Detect profiles where facts.md is now
# redundant (i.e. facts.jsonl already exists alongside).
#
# This is the cleanup step that follows 01-facts-md-to-jsonl. Splitting it
# from the convert step makes the destructive action (file deletion) opt-in
# at the orchestrator level rather than baked into the converter. The
# nemawashi-migrate skill chains them: after 01 produces facts.jsonl for a
# profile, that profile becomes eligible for 02 in the next detect pass.
#
# Usage:
#   02-delete-legacy-facts-md.sh --detect   Print one line if N>0 profiles
#                                            eligible; silent otherwise.

set -uo pipefail

PROFILE_DIR="${PROFILE_DIR:-$HOME/.local/share/supernemawashi/profiles}"
MIGRATION_ID="02-delete-legacy-facts-md"

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
  if [ -f "$dir/facts.md" ] && [ -f "$dir/facts.jsonl" ]; then
    count=$((count + 1))
  fi
done

if [ "$count" -gt 0 ]; then
  printf "%s: %d profile(s) eligible\n" "$MIGRATION_ID" "$count"
fi

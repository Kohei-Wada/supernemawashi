#!/usr/bin/env bash
# 90-delete-legacy-facts-md.sh — Detect profiles where facts.md is now
# redundant (i.e. facts.jsonl already exists alongside).
#
# This is a cleanup-phase migration (filename prefix 90-99). It runs
# AFTER all forward-phase migrations (01-89) have produced or extended
# the canonical facts.jsonl, at which point the legacy facts.md can be
# safely retired. Splitting destructive cleanup from forward conversion
# means each migration is single-responsibility, and the filename
# convention orders apply correctly within a single round.
#
# Usage:
#   90-delete-legacy-facts-md.sh --detect   Print one line if N>0 profiles
#                                            eligible; silent otherwise.

set -uo pipefail

PROFILE_DIR="${PROFILE_DIR:-$HOME/.local/share/supernemawashi/profiles}"
MIGRATION_ID="90-delete-legacy-facts-md"

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

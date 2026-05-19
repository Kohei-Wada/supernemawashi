#!/usr/bin/env bash
# 01-facts-md-to-jsonl.sh — Detect profiles eligible for the facts.md → facts.jsonl migration.
#
# Detection is deterministic and read-only: a profile is eligible if it has
# `facts.md` and no `facts.jsonl`. The actual conversion is performed by the
# LLM following `01-facts-md-to-jsonl.md` (kept in this directory). Splitting
# detection (cheap, deterministic, used by the session-start hook) from apply
# (LLM-driven, robust to format drift) means a new source-tag variant in
# facts.md only requires updating the markdown apply notes — not patching
# bash regex.
#
# Usage:
#   01-facts-md-to-jsonl.sh --detect   Print one line if N>0 profiles eligible; silent otherwise.

set -uo pipefail

PROFILE_DIR="${PROFILE_DIR:-$HOME/.local/share/supernemawashi/profiles}"
MIGRATION_ID="01-facts-md-to-jsonl"

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
  if [ -f "$dir/facts.md" ] && [ ! -f "$dir/facts.jsonl" ]; then
    count=$((count + 1))
  fi
done

if [ "$count" -gt 0 ]; then
  printf "%s: %d profile(s) eligible\n" "$MIGRATION_ID" "$count"
fi

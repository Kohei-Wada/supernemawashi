#!/usr/bin/env bash
# 03-frameworks-split.sh — Detect profiles produced under the monolithic
# profile.md schema (no per-framework files under frameworks/) and mark
# them for re-analysis via the split flow introduced in v3.0.0.
#
# A profile is eligible when:
#   - profile.md exists, AND
#   - frameworks/ is missing OR contains no *.md files.
#
# Forward-phase migration (prefix 01-89). Non-destructive on the source
# profile.md until the apply step rewrites it.

set -uo pipefail

PROFILE_DIR="${PROFILE_DIR:-$HOME/.local/share/supernemawashi/profiles}"
MIGRATION_ID="03-frameworks-split"

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
  [ -f "$dir/profile.md" ] || continue

  # Eligible if frameworks/ is missing, or exists but has no *.md files.
  if [ ! -d "$dir/frameworks" ]; then
    count=$((count + 1))
    continue
  fi
  shopt -s nullglob
  framework_files=("$dir/frameworks"/*.md)
  shopt -u nullglob
  if [ "${#framework_files[@]}" -eq 0 ]; then
    count=$((count + 1))
  fi
done

if [ "$count" -gt 0 ]; then
  printf "%s: %d profile(s) eligible\n" "$MIGRATION_ID" "$count"
fi

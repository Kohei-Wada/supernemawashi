#!/usr/bin/env bash
# archive.sh — move an analysis-generated file to a dated _archive sibling.
#
# Invoked by nemawashi-analyze before any output write to preserve the prior
# version on the filesystem. Idempotent on missing inputs.
#
# Usage: archive.sh <file-path>
#
# Behavior:
#   - If <file-path> does not exist: exit 0 silently (no-op).
#   - Date for archive name: `last_updated:` from YAML frontmatter at the top
#     of the file. Falls back to file mtime if missing/unparseable.
#   - Archive target: <dir>/_archive/<stem>.<date>.<ext>
#   - On collision: <stem>.<date>.1.<ext>, .2.<ext>, ... up to .9.
#     Past .9 -> exit 1.
set -euo pipefail

src="${1:-}"
[ -n "$src" ] || { echo "Usage: $0 <file-path>" >&2; exit 2; }
[ -f "$src" ] || exit 0

src_dir=$(dirname "$src")
src_base=$(basename "$src")

# Split basename into stem + extension. Last dot wins; no dot -> no extension.
case "$src_base" in
  *.*) stem="${src_base%.*}"; ext=".${src_base##*.}" ;;
  *)   stem="$src_base";     ext="" ;;
esac

# Extract last_updated date from frontmatter. The frontmatter is a fenced
# `---`...`---` block at the very top of the file. Stop scanning at the closing
# fence so we don't pick up a `last_updated:` line that happens to appear in
# the body.
date=$(awk '
  NR == 1 && $0 != "---" { exit }
  NR == 1 { in_fm = 1; next }
  in_fm && $0 == "---"  { exit }
  in_fm && /^last_updated:[[:space:]]*/ {
    sub(/^last_updated:[[:space:]]*/, "")
    sub(/[[:space:]]+$/, "")
    print
    exit
  }
' "$src")

# Validate YYYY-MM-DD. Anything else -> fall back to mtime.
case "$date" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
  *) date=$(date -r "$src" +%Y-%m-%d) ;;
esac

archive_dir="$src_dir/_archive"
mkdir -p "$archive_dir"

target="$archive_dir/${stem}.${date}${ext}"
if [ -e "$target" ]; then
  found=""
  for n in 1 2 3 4 5 6 7 8 9; do
    candidate="$archive_dir/${stem}.${date}.${n}${ext}"
    if [ ! -e "$candidate" ]; then
      target="$candidate"
      found="yes"
      break
    fi
  done
  [ -n "$found" ] || {
    echo "archive.sh: too many same-day archives for $src (>9)" >&2
    exit 1
  }
fi

mv "$src" "$target"
printf "archived: %s -> %s\n" "$src" "$target"

#!/usr/bin/env bash
# check-frameworks.sh — Verify the framework registry in
# skills/nemawashi-analyze/FRAMEWORKS.md and the actual definition files
# under skills/nemawashi-analyze/frameworks/ agree on:
#
#   - the set of slugs (no extras on either side)
#   - the display name (registry "Display name" column == frontmatter
#     `output_label` of the matching definition file)
#   - the tier (registry "Tier" column == frontmatter `tier`)
#
# Renaming a framework in just the registry (or just a definition file)
# will fail this check with a diff of what disagrees.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

REGISTRY="skills/nemawashi-analyze/FRAMEWORKS.md"
DEFS_DIR="skills/nemawashi-analyze/frameworks"

# Extract registry rows: slug<TAB>display<TAB>tier. The table row format is:
#   | `slug` | Display Name | N |
# Skip the header row and the separator row.
registry_rows=$(awk -F'|' '
  /^\| `[a-z][a-z0-9-]*` \|/ {
    slug = $2; gsub(/[ `]/, "", slug)
    display = $3; gsub(/^ +| +$/, "", display)
    tier = $4; gsub(/[ ]/, "", tier)
    print slug "\t" display "\t" tier
  }
' "$REGISTRY" | sort)

if [ -z "$registry_rows" ]; then
  echo "check-frameworks: no rows parsed from $REGISTRY" >&2
  exit 1
fi

# Extract definition file rows: slug<TAB>output_label<TAB>tier.
definition_rows=$(
  for def in "$DEFS_DIR"/*.md; do
    [ -f "$def" ] || continue
    slug=$(basename "$def" .md)
    output_label=$(awk '/^output_label:/ { sub(/^output_label:[ ]*/, ""); print; exit }' "$def")
    tier=$(awk '/^tier:/ { sub(/^tier:[ ]*/, ""); print; exit }' "$def")
    printf '%s\t%s\t%s\n' "$slug" "$output_label" "$tier"
  done | sort
)

if [ "$registry_rows" != "$definition_rows" ]; then
  echo "check-frameworks: registry and definitions disagree" >&2
  echo "" >&2
  echo "--- $REGISTRY (slug / display / tier)" >&2
  echo "$registry_rows" >&2
  echo "" >&2
  echo "--- $DEFS_DIR/*.md (slug / output_label / tier)" >&2
  echo "$definition_rows" >&2
  echo "" >&2
  echo "Diff:" >&2
  diff <(echo "$registry_rows") <(echo "$definition_rows") >&2 || true
  exit 1
fi

exit 0

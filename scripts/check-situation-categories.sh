#!/usr/bin/env bash
# check-situation-categories.sh — Verify that the 4 Situation Category names
# defined canonically in skills/using-supernemawashi/SKILL.md still appear
# verbatim in any code that hardcodes them.
#
# The categories are defined in prose at exactly one location per #48; all
# other prose locations reference that section by link. Machine code (e.g.
# skills/nemawashi-analyze/assertion.sh) still needs the literal strings to
# render section headings, so we verify alignment instead of forcing a
# string-table extraction layer that bash would make ugly.
#
# If using-supernemawashi/SKILL.md renames a category but assertion.sh is
# missed, this check fails loudly with the missing string.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

CANONICAL="skills/using-supernemawashi/SKILL.md"
CONSUMERS=(
  "skills/nemawashi-analyze/assertion.sh"
)

# Extract the 4 category labels from the "## Situation Categories" section
# of the canonical file. Format expected:
#   1. **When Requesting** — ...
#   2. **During Conflict** — ...
#   3. **When Reporting** — ...
#   4. **Routine Collaboration** — ...
mapfile -t categories < <(
  awk '
    /^## Situation Categories$/ { in_section = 1; next }
    in_section && /^## / { in_section = 0 }
    in_section && match($0, /\*\*([^*]+)\*\*/, m) { print m[1] }
  ' "$CANONICAL"
)

if [ "${#categories[@]}" -ne 4 ]; then
  echo "check-situation-categories: expected 4 categories in $CANONICAL, found ${#categories[@]}" >&2
  printf '  %s\n' "${categories[@]}" >&2
  exit 1
fi

fail=0
for consumer in "${CONSUMERS[@]}"; do
  for category in "${categories[@]}"; do
    if ! grep -qF "$category" "$consumer"; then
      echo "check-situation-categories: '$category' missing from $consumer" >&2
      fail=1
    fi
  done
done

exit "$fail"

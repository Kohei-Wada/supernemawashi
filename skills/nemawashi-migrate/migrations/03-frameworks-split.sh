#!/usr/bin/env bash
# shellcheck disable=SC1091
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

is_eligible() {
  local dir="$1"
  [ -f "$dir/profile.md" ] || return 1

  # Eligible if frameworks/ is missing, or exists but has no *.md files.
  [ -d "$dir/frameworks" ] || return 0

  local files
  shopt -s nullglob
  files=("$dir/frameworks"/*.md)
  shopt -u nullglob
  [ "${#files[@]}" -eq 0 ]
}

migration_main "03-frameworks-split" is_eligible "$@"

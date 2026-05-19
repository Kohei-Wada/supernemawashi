#!/usr/bin/env bash
# shellcheck disable=SC1091
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../../lib/migration.sh"

is_eligible() {
  local dir="$1"
  [ -f "$dir/facts.md" ] && [ -f "$dir/facts.jsonl" ]
}

migration_main "90-delete-legacy-facts-md" is_eligible "$@"

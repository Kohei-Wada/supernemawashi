#!/usr/bin/env bash
# detect.sh — Iterate this skill's migrations/*.sh in --detect mode.
#
# Aggregates the output of each migration's self-reported eligibility check.
# Each migration prints exactly one line on stdout when it has work to do
# (format: "<migration-id>: N profile(s) eligible") and stays silent when
# it does not. This script forwards all such lines and exits 0.
#
# Used by:
#   - hooks/session-start (to decide whether to surface a nudge)
#   - skills/nemawashi-migrate (to list candidates before apply)
#
# Adding a new migration: drop a `.sh` + `.md` pair in `./migrations/`.
# No edit to this iterator.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIGRATIONS_DIR="${SCRIPT_DIR}/migrations"

[ -d "$MIGRATIONS_DIR" ] || exit 0

for migration in "$MIGRATIONS_DIR"/*.sh; do
  [ -f "$migration" ] || continue
  [ -x "$migration" ] || continue
  "$migration" --detect 2>/dev/null || true
done

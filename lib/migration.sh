#!/usr/bin/env bash
# lib/migration.sh — shared helpers for migration scripts and the
# `nemawashi-check` freshness scanner.
#
# Sourced from `skills/nemawashi-migrate/migrations/*.sh` and
# `skills/nemawashi-check/check.sh`. Not executable on its own.
#
# Helpers:
#   - PROFILE_DIR              — env-overridable path to the profile dir
#   - extract_md_dates <file>  — YYYY-MM(-DD)? dates from facts.md bullets
#   - extract_jsonl_dates <f>  — YYYY-MM(-DD)? dates from facts.jsonl records
#   - migration_main <id> <predicate-fn> [args...]
#       Parses --detect, iterates PROFILE_DIR/*/, calls predicate-fn per dir,
#       prints "<id>: N profile(s) eligible" if N > 0.

PROFILE_DIR="${PROFILE_DIR:-$HOME/.local/share/supernemawashi/profiles}"

# Extract YYYY-MM(-DD)? dates from facts.md bullets of the form `- [YYYY-MM(-DD)?]`.
extract_md_dates() {
  grep -oE '^- \[[0-9]{4}-[0-9]{2}(-[0-9]{2})?\]' "$1" 2>/dev/null \
    | grep -oE '[0-9]{4}-[0-9]{2}(-[0-9]{2})?'
}

# Extract YYYY-MM(-DD)? dates from facts.jsonl records (the `"date":"..."` field).
extract_jsonl_dates() {
  grep -oE '"date"[[:space:]]*:[[:space:]]*"[0-9]{4}-[0-9]{2}(-[0-9]{2})?"' "$1" 2>/dev/null \
    | grep -oE '[0-9]{4}-[0-9]{2}(-[0-9]{2})?'
}

# Standard --detect harness shared by every migration.
#
# Usage: migration_main <migration_id> <predicate_fn> "$@"
#
# - <predicate_fn> is a shell function name; it receives one arg (the
#   absolute path to a profile directory, with trailing slash) and returns
#   0 if that profile is eligible for this migration, non-zero otherwise.
# - The remaining "$@" must include `--detect`. Any other argument is an
#   error (exits 2 with a usage message).
migration_main() {
  local migration_id="$1"
  local predicate="$2"
  shift 2

  local mode=""
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

  local count=0
  local dir
  for dir in "$PROFILE_DIR"/*/; do
    [ -d "$dir" ] || continue
    if "$predicate" "$dir"; then
      count=$((count + 1))
    fi
  done

  if [ "$count" -gt 0 ]; then
    printf "%s: %d profile(s) eligible\n" "$migration_id" "$count"
  fi
}

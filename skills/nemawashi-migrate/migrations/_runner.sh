#!/usr/bin/env bash
# shellcheck disable=SC1091
# _runner.sh — the --detect harness shared by every migration script.
#
# Sourced (not executed) by every `NN-*.sh` migration in this directory.
# The leading underscore + non-executable mode tell `detect.sh` and any
# future tooling to skip this file.
#
# Sourcing convention:
#
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   . "$SCRIPT_DIR/_runner.sh"
#
# Re-exports (via lib/facts.sh): PROFILE_DIR, extract_md_dates, extract_jsonl_dates.
#
# Defines:
#   - migration_main <id> <predicate-fn> [args...]
#       Parses --detect, iterates PROFILE_DIR/*/, calls predicate-fn per dir,
#       prints "<id>: N profile(s) eligible" if N > 0.

_RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_RUNNER_DIR/../../../lib/facts.sh"

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

#!/usr/bin/env bash
# shellcheck disable=SC1091
# 04-frameworks-temporal-model.sh — Detect profiles eligible for the
# frameworks/<slug>.md → frameworks/<slug>.jsonl temporal-model migration (#41).
#
# A profile is eligible if at least one of its frameworks/<slug>.md has no
# corresponding frameworks/<slug>.jsonl. The apply phase (LLM-driven,
# instructions in the matching .md) reads each .md, writes an initial
# assertion to its .jsonl, and deletes any _archive/ directories left over
# from #40.
#
# Usage:
#   04-frameworks-temporal-model.sh --detect

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_runner.sh"

is_eligible() {
  local dir="$1"
  local f slug
  for f in "${dir}frameworks/"*.md; do
    [ -f "$f" ] || continue
    slug=$(basename "$f" .md)
    if [ ! -f "${dir}frameworks/${slug}.jsonl" ]; then
      return 0
    fi
  done
  return 1
}

migration_main "04-frameworks-temporal-model" is_eligible "$@"

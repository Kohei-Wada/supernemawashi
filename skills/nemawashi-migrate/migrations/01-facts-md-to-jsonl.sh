#!/usr/bin/env bash
# shellcheck disable=SC1091
# 01-facts-md-to-jsonl.sh — Detect profiles eligible for the facts.md → facts.jsonl migration.
#
# Detection is deterministic and read-only: a profile is eligible if it has
# `facts.md` and no `facts.jsonl`. The actual conversion is performed by the
# LLM following `01-facts-md-to-jsonl.md` (kept in this directory). Splitting
# detection (cheap, deterministic, used by the session-start hook) from apply
# (LLM-driven, robust to format drift) means a new source-tag variant in
# facts.md only requires updating the markdown apply notes — not patching
# bash regex.
#
# Usage:
#   01-facts-md-to-jsonl.sh --detect   Print one line if N>0 profiles eligible; silent otherwise.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/_lib.sh"

is_eligible() {
  local dir="$1"
  [ -f "$dir/facts.md" ] && [ ! -f "$dir/facts.jsonl" ]
}

migration_main "01-facts-md-to-jsonl" is_eligible "$@"

#!/usr/bin/env bash
# lib/facts.sh — primitives for reading profile fact data.
#
# Sourced by `skills/nemawashi-check/check.sh` and (transitively, via
# `skills/nemawashi-migrate/migrations/_runner.sh`) by every migration.
# Not executable on its own.
#
# Helpers:
#   - PROFILE_DIR              — env-overridable path to the profile dir
#   - extract_md_dates <file>  — YYYY-MM(-DD)? dates from facts.md bullets
#   - extract_jsonl_dates <f>  — YYYY-MM(-DD)? dates from facts.jsonl records

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

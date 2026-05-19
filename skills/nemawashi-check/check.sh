#!/usr/bin/env bash
# shellcheck disable=SC1091
# nemawashi-check.sh — Check freshness and subject-activity across all profiles
# Usage: nemawashi-check.sh [profiles_dir]
# Output: TSV with columns:
#   name, analyzed_date, days_ago, analyzed_facts, current_facts,
#   latest_fact_date, inactivity_days, analysis_status, activity_status
#
# Fact data lives in two possible files (dual-read during legacy → jsonl migration):
#   facts.jsonl: one JSON record per line (newer profiles)
#   facts.md:    `- [YYYY-MM-DD] [source] ...` or `- [YYYY-MM] ...` (legacy)
# Both files may coexist for a profile mid-migration — counts and dates merge across both.
#
# Classifications:
#   analysis_status: never_analyzed | stale | fresh | no_data
#   activity_status: active (<30d) | inactive (30-90d) | dormant (>90d) | unknown (no facts)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../nemawashi-migrate/migrations/_lib.sh"

PROFILES_DIR="${1:-$HOME/.local/share/supernemawashi/profiles}"
TODAY=$(date +%Y-%m-%d)
TODAY_EPOCH=$(date -d "$TODAY" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$TODAY" +%s)
STALE_DAYS=7
INACTIVE_DAYS=30
DORMANT_DAYS=90

if [ ! -d "$PROFILES_DIR" ]; then
  echo "Error: profiles directory not found: $PROFILES_DIR" >&2
  exit 1
fi

# Header
printf "name\tanalyzed_date\tdays_ago\tanalyzed_facts\tcurrent_facts\tlatest_fact_date\tinactivity_days\tanalysis_status\tactivity_status\n"

for dir in "$PROFILES_DIR"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  profile="$dir/profile.md"
  facts_md="$dir/facts.md"
  facts_jsonl="$dir/facts.jsonl"

  # Parse analyzed comment from profile.md
  analyzed_date="never"
  analyzed_facts=0
  if [ -f "$profile" ]; then
    local_date=$(grep -oE '<!-- analyzed: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$profile" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
    local_facts=$(grep -oE 'facts_count: [0-9]+' "$profile" 2>/dev/null | grep -oE '[0-9]+' | head -1)
    [ -n "$local_date" ] && analyzed_date="$local_date"
    [ -n "$local_facts" ] && analyzed_facts="$local_facts"
  fi

  # Count current facts: facts.jsonl (one record per non-empty line) + facts.md (bullet entries with day- or month-precision dates).
  current_facts=0
  if [ -f "$facts_jsonl" ]; then
    jsonl_count=$(grep -cE '^[^[:space:]]' "$facts_jsonl" 2>/dev/null || true)
    [ -z "$jsonl_count" ] && jsonl_count=0
    current_facts=$((current_facts + jsonl_count))
  fi
  if [ -f "$facts_md" ]; then
    md_count=$(extract_md_dates "$facts_md" | wc -l)
    [ -z "$md_count" ] && md_count=0
    current_facts=$((current_facts + md_count))
  fi

  # Determine the latest fact date across both files. We pull every date string,
  # sort descending; ASCII puts `2026-03` before `2026-03-01`, so reverse-sort
  # makes day-precision dates win ties with their own month — desired behavior.
  latest_fact_date="-"
  {
    [ -f "$facts_jsonl" ] && extract_jsonl_dates "$facts_jsonl"
    [ -f "$facts_md" ]    && extract_md_dates "$facts_md"
  } > /tmp/nwc_dates.$$ 2>/dev/null || true
  if [ -s /tmp/nwc_dates.$$ ]; then
    latest_fact_date=$(sort -r /tmp/nwc_dates.$$ | head -1)
  fi
  rm -f /tmp/nwc_dates.$$

  # Inactivity days = TODAY minus latest_fact_date. Month-precision dates are
  # normalized to the first day of that month before arithmetic.
  inactivity_days="-"
  if [ "$latest_fact_date" != "-" ]; then
    norm_date="$latest_fact_date"
    if [ ${#norm_date} -eq 7 ]; then norm_date="${norm_date}-01"; fi
    fact_epoch=$(date -d "$norm_date" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$norm_date" +%s 2>/dev/null || echo "0")
    if [ "$fact_epoch" -gt 0 ]; then
      inactivity_days=$(( (TODAY_EPOCH - fact_epoch) / 86400 ))
    fi
  fi

  # Analysis status (existing semantics, kept as-is).
  days_ago="-"
  analysis_status="never_analyzed"
  if [ "$analyzed_date" != "never" ]; then
    analyzed_epoch=$(date -d "$analyzed_date" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$analyzed_date" +%s 2>/dev/null || echo "0")
    if [ "$analyzed_epoch" -gt 0 ]; then
      days_ago=$(( (TODAY_EPOCH - analyzed_epoch) / 86400 ))
      if [ "$days_ago" -gt "$STALE_DAYS" ] || [ "$current_facts" -gt "$analyzed_facts" ]; then
        analysis_status="stale"
      else
        analysis_status="fresh"
      fi
    fi
  fi

  # No fact data at all
  if [ ! -f "$facts_md" ] && [ ! -f "$facts_jsonl" ] && [ "$analyzed_date" = "never" ]; then
    analysis_status="no_data"
  fi

  # Activity status (new axis): bucket by how long since the latest fact.
  if [ "$inactivity_days" = "-" ]; then
    activity_status="unknown"
  elif [ "$inactivity_days" -lt "$INACTIVE_DAYS" ]; then
    activity_status="active"
  elif [ "$inactivity_days" -lt "$DORMANT_DAYS" ]; then
    activity_status="inactive"
  else
    activity_status="dormant"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$name" "$analyzed_date" "$days_ago" "$analyzed_facts" "$current_facts" \
    "$latest_fact_date" "$inactivity_days" "$analysis_status" "$activity_status"
done

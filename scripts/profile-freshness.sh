#!/usr/bin/env bash
# profile-freshness.sh — Check analysis staleness across all profiles
# Usage: profile-freshness.sh [profiles_dir]
# Output: TSV with columns: name, analyzed_date, days_ago, analyzed_facts, current_facts, status
#
# Standard facts.md entry format:
#   - [YYYY-MM-DD] [source] Description text (url)

set -uo pipefail

PROFILES_DIR="${1:-$HOME/.local/share/supernemawashi/profiles}"
TODAY=$(date +%Y-%m-%d)
TODAY_EPOCH=$(date -d "$TODAY" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$TODAY" +%s)
STALE_DAYS=7

if [ ! -d "$PROFILES_DIR" ]; then
  echo "Error: profiles directory not found: $PROFILES_DIR" >&2
  exit 1
fi

# Header
printf "name\tanalyzed_date\tdays_ago\tanalyzed_facts\tcurrent_facts\tstatus\n"

for dir in "$PROFILES_DIR"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  profile="$dir/profile.md"
  facts="$dir/facts.md"

  # Parse analyzed comment from profile.md
  analyzed_date="never"
  analyzed_facts=0
  if [ -f "$profile" ]; then
    local_date=$(grep -oE '<!-- analyzed: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$profile" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
    local_facts=$(grep -oE 'facts_count: [0-9]+' "$profile" 2>/dev/null | grep -oE '[0-9]+' | head -1)
    [ -n "$local_date" ] && analyzed_date="$local_date"
    [ -n "$local_facts" ] && analyzed_facts="$local_facts"
  fi

  # Count current facts entries using standard format: - [YYYY-MM-DD] [source]
  current_facts=0
  if [ -f "$facts" ]; then
    current_facts=$(grep -cE '^- \[[0-9]{4}-[0-9]{2}-[0-9]{2}\] \[' "$facts" 2>/dev/null || true)
    [ -z "$current_facts" ] && current_facts=0
  fi

  # Calculate days ago and determine status
  days_ago="-"
  status="never_analyzed"
  if [ "$analyzed_date" != "never" ]; then
    analyzed_epoch=$(date -d "$analyzed_date" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$analyzed_date" +%s 2>/dev/null || echo "0")
    if [ "$analyzed_epoch" -gt 0 ]; then
      days_ago=$(( (TODAY_EPOCH - analyzed_epoch) / 86400 ))
      if [ "$days_ago" -gt "$STALE_DAYS" ] || [ "$current_facts" -gt "$analyzed_facts" ]; then
        status="stale"
      else
        status="fresh"
      fi
    fi
  fi

  # No facts.md at all
  if [ ! -f "$facts" ] && [ "$analyzed_date" = "never" ]; then
    status="no_data"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$name" "$analyzed_date" "$days_ago" "$analyzed_facts" "$current_facts" "$status"
done

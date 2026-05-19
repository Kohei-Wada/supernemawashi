#!/usr/bin/env bash
# assertion.sh — append-only assertion log helper for framework analysis.
#
# Subcommands:
#   append <jsonl-path> <json-string>
#     Validates JSON + required fields, appends one line.
#
#   render <json-string> <framework-definition-path>
#     Emits markdown body (frontmatter + sections) to stdout.
#
#   render-to-file <jsonl-path> <md-path> <framework-definition-path>
#     Reads the latest assertion from <jsonl-path>, renders, writes atomically.
#
#   fold <jsonl-path> [--as-of YYYY-MM-DD]
#     Default: emits last line.
#     --as-of: emits last entry where asserted_at <= <date>T23:59:59Z.
#     Empty output if no entry matches.
#
#   history <jsonl-path>
#     Prints "<asserted_at>: <classification> (<confidence>)" per line, in order.
set -euo pipefail

REQUIRED_FIELDS="asserted_at framework classification classification_detail confidence facts_snapshot_count evidence rules data_gap_reason"

usage() {
  sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'
}

sub_append() {
  local jsonl="${1:-}" payload="${2:-}"
  if [ -z "$jsonl" ] || [ -z "$payload" ]; then usage >&2; exit 2; fi
  echo "$payload" | jq -e . >/dev/null 2>&1 || { echo "append: invalid JSON" >&2; exit 1; }
  local f
  for f in $REQUIRED_FIELDS; do
    echo "$payload" | jq -e "has(\"$f\")" >/dev/null \
      || { echo "append: missing required field: $f" >&2; exit 1; }
  done
  echo "$payload" | jq -c . >> "$jsonl"
}

fetch_output_label() {
  local def="$1"
  awk '
    NR==1 && $0=="---" { in_fm=1; next }
    in_fm && $0=="---" { exit }
    in_fm && /^output_label:[[:space:]]*/ {
      sub(/^output_label:[[:space:]]*/, "")
      sub(/^"/, ""); sub(/"$/, "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$def"
}

sub_render() {
  local payload="${1:-}" def="${2:-}"
  if [ -z "$payload" ] || [ -z "$def" ]; then usage >&2; exit 2; fi
  local label
  label=$(fetch_output_label "$def")
  [ -n "$label" ] || { echo "render: output_label missing in $def" >&2; exit 1; }

  local last_updated
  last_updated=$(echo "$payload" | jq -r '.asserted_at' | cut -c1-10)

  local framework classification classification_detail confidence confidence_lower
  framework=$(echo "$payload" | jq -r '.framework')
  classification=$(echo "$payload" | jq -r '.classification')
  classification_detail=$(echo "$payload" | jq -r '.classification_detail')
  confidence=$(echo "$payload" | jq -r '.confidence')
  confidence_lower=$(echo "$confidence" | tr '[:upper:]' '[:lower:]')

  printf '%s\n' "---"
  printf 'framework: %s\n' "$framework"
  printf 'classification: %s\n' "$classification"
  printf 'confidence: %s\n' "$confidence"
  printf 'last_updated: %s\n' "$last_updated"
  printf '%s\n' "---"
  printf '\n'
  printf '# %s\n\n' "$label"
  printf '## Classification\n'
  printf '%s\n\n' "$classification_detail"

  local ev_count
  ev_count=$(echo "$payload" | jq '.evidence | length')
  if [ "$ev_count" -gt 0 ]; then
    printf '## Evidence\n'
    echo "$payload" | jq -r '.evidence[] | "- [\(.date)] [\(.source)] \(.quote) → \(.reasoning) [signal: \(.signal_tag)]"'
    printf '\n'
  fi

  if [ "$confidence_lower" = "data gap" ]; then
    local reason
    reason=$(echo "$payload" | jq -r '.data_gap_reason // ""')
    printf '## Data Gap\n%s\n' "$reason"
    return 0
  fi

  printf '## Rules\n\n'
  local situation_key heading
  for situation_key in requesting conflict reporting routine; do
    case "$situation_key" in
      requesting) heading="When Requesting" ;;
      conflict)   heading="During Conflict" ;;
      reporting)  heading="When Reporting" ;;
      routine)    heading="Routine Collaboration" ;;
    esac
    printf '### %s\n' "$heading"
    printf '**DO:**\n'
    echo "$payload" | jq -r ".rules.${situation_key}.do[]? | \"- \(.text) [signal: \(.signal_tag)]\""
    printf "\n**DON'T:**\n"
    echo "$payload" | jq -r ".rules.${situation_key}.dont[]? | \"- \(.text) [signal: \(.signal_tag)]\""
    printf '\n'
  done
}

sub_render_to_file() {
  local jsonl="${1:-}" md="${2:-}" def="${3:-}"
  if [ -z "$jsonl" ] || [ -z "$md" ] || [ -z "$def" ]; then usage >&2; exit 2; fi
  [ -s "$jsonl" ] || { echo "render-to-file: empty jsonl: $jsonl" >&2; exit 1; }
  local last_line
  last_line=$(tail -n 1 "$jsonl")
  local tmp
  tmp=$(mktemp "${md}.XXXXXX")
  sub_render "$last_line" "$def" > "$tmp"
  mv "$tmp" "$md"
}

sub_fold() {
  local jsonl="${1:-}"
  [ -n "$jsonl" ] || { usage >&2; exit 2; }
  shift
  local as_of=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --as-of) as_of="${2:-}"; shift 2 ;;
      *) usage >&2; exit 2 ;;
    esac
  done
  [ -s "$jsonl" ] || exit 0

  if [ -z "$as_of" ]; then
    tail -n 1 "$jsonl"
    return 0
  fi

  case "$as_of" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) echo "fold: --as-of must be YYYY-MM-DD" >&2; exit 2 ;;
  esac

  local cutoff="${as_of}T23:59:59Z"
  jq -c --arg cutoff "$cutoff" 'select(.asserted_at <= $cutoff)' "$jsonl" | tail -n 1
}

sub_history() {
  local jsonl="${1:-}"
  [ -n "$jsonl" ] || { usage >&2; exit 2; }
  [ -s "$jsonl" ] || exit 0
  jq -r '"\(.asserted_at): \(.classification) (\(.confidence))"' "$jsonl"
}

cmd="${1:-}"
[ -n "$cmd" ] || { usage >&2; exit 2; }
shift
case "$cmd" in
  append)         sub_append "$@" ;;
  render)         sub_render "$@" ;;
  render-to-file) sub_render_to_file "$@" ;;
  fold)           sub_fold "$@" ;;
  history)        sub_history "$@" ;;
  *) usage >&2; exit 2 ;;
esac

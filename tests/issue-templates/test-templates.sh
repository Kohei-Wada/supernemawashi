#!/usr/bin/env bash
# test-templates.sh — verify .github/ISSUE_TEMPLATE/ files conform to the
# house-style spine.
# Run: bash tests/issue-templates/test-templates.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_DIR="$REPO_ROOT/.github/ISSUE_TEMPLATE"

PASS=0
FAIL=0

assert() {
  # assert <label> <condition: true|false>
  if [ "$2" = "true" ]; then
    printf "PASS  %s\n" "$1"
    PASS=$((PASS + 1))
  else
    printf "FAIL  %s\n" "$1"
    FAIL=$((FAIL + 1))
  fi
}

require_frontmatter_field() {
  local file="$1" field="$2"
  if awk -v fld="$field" '
    NR==1 && $0=="---" { in_fm=1; next }
    in_fm && $0=="---" { exit 1 }
    in_fm && $0 ~ "^" fld ":" { exit 0 }
  ' "$file"; then echo "true"; else echo "false"; fi
}

require_section_heading() {
  local file="$1" heading="$2"
  if grep -qxF "$heading" "$file"; then echo "true"; else echo "false"; fi
}

for tmpl in feature_request.md chore.md bug_report.md; do
  path="$TEMPLATE_DIR/$tmpl"
  if [ -f "$path" ]; then
    assert "exists: $tmpl" "true"
  else
    assert "exists: $tmpl" "false"
    continue
  fi

  for field in name about title labels; do
    assert "$tmpl: frontmatter has $field" "$(require_frontmatter_field "$path" "$field")"
  done

  for section in "## Context" "## Proposal" "## Acceptance" "## Out of scope" "## Relationship to other issues"; do
    assert "$tmpl: body has '$section'" "$(require_section_heading "$path" "$section")"
  done
done

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]

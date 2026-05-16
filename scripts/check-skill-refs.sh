#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

skills=$(find skills -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -u)

refs=$(grep -rhoE 'supernemawashi:[a-z][a-z0-9-]*' \
  --include='*.md' --include='*.json' --include='*.sh' \
  --exclude-dir=.git . 2>/dev/null \
  | sed 's/^supernemawashi://' \
  | sort -u || true)

fail=0
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  if ! grep -qx "$ref" <<<"$skills"; then
    echo "Unknown skill reference: supernemawashi:$ref" >&2
    fail=1
  fi
done <<<"$refs"

exit $fail

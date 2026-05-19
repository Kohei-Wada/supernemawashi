#!/usr/bin/env bash
# check-no-internal-names.sh — Block staged additions that match terms in a
# per-user denylist of internal identifiers.
#
# Reads .local/denylist.txt (gitignored, so the list itself never enters the
# public history). If the file is absent, the hook is a silent no-op so it
# does not block contributors who have not opted in.
#
# Denylist format:
#   - one term per line
#   - lines starting with # are comments
#   - blank lines are ignored
#   - matching is case-insensitive

set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

DENYLIST=".local/denylist.txt"
[ -f "$DENYLIST" ] || exit 0

# Collect non-empty, non-comment terms.
terms=$(sed -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' "$DENYLIST" \
        | grep -vE '^(#|$)' \
        | paste -sd'|' -)
[ -z "$terms" ] && exit 0

# Look at staged additions only. `--unified=0` strips context lines; the
# remaining `+` lines (minus the `+++` file headers) are the new content.
matches=$(git diff --cached --unified=0 \
          | grep -E '^\+' \
          | grep -vE '^\+\+\+ ' \
          | grep -inE "($terms)" \
          || true)

if [ -n "$matches" ]; then
  echo "❌ Staged additions matched the local denylist ($DENYLIST):" >&2
  echo "" >&2
  printf '%s\n' "$matches" >&2
  echo "" >&2
  echo "Edit the offending lines, or remove a term from $DENYLIST if it is" >&2
  echo "over-aggressive." >&2
  exit 1
fi

exit 0

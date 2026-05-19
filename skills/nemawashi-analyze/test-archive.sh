#!/usr/bin/env bash
# test-archive.sh — self-contained test for archive.sh.
# Run: bash skills/nemawashi-analyze/test-archive.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHIVE="$SCRIPT_DIR/archive.sh"
[ -x "$ARCHIVE" ] || { echo "archive.sh not executable: $ARCHIVE" >&2; exit 1; }

PASS=0
FAIL=0

assert_eq() {
  # assert_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf "PASS  %s\n" "$1"
    PASS=$((PASS + 1))
  else
    printf "FAIL  %s\n        expected: %s\n        actual:   %s\n" "$1" "$2" "$3"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  if [ -f "$2" ]; then
    printf "PASS  %s\n" "$1"
    PASS=$((PASS + 1))
  else
    printf "FAIL  %s\n        missing file: %s\n" "$1" "$2"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_absent() {
  if [ ! -e "$2" ]; then
    printf "PASS  %s\n" "$1"
    PASS=$((PASS + 1))
  else
    printf "FAIL  %s\n        unexpected file: %s\n" "$1" "$2"
    FAIL=$((FAIL + 1))
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- Case 1: file with last_updated frontmatter is archived under that date.
mkdir -p "$TMP/case1"
cat > "$TMP/case1/profile.md" <<'EOF'
---
name: Alice
last_updated: 2026-03-28
---

# Alice
EOF
"$ARCHIVE" "$TMP/case1/profile.md" >/dev/null
assert_file_exists "case1: archive copy in _archive with frontmatter date" \
  "$TMP/case1/_archive/profile.2026-03-28.md"
assert_file_absent "case1: source file removed after archive" \
  "$TMP/case1/profile.md"

# --- Case 2: file without last_updated → uses mtime as fallback.
mkdir -p "$TMP/case2"
echo "no frontmatter" > "$TMP/case2/notes.md"
touch -d "2025-12-01" "$TMP/case2/notes.md"
"$ARCHIVE" "$TMP/case2/notes.md" >/dev/null
assert_file_exists "case2: mtime fallback for missing last_updated" \
  "$TMP/case2/_archive/notes.2025-12-01.md"

# --- Case 3: same-date collision → suffix .1, .2.
mkdir -p "$TMP/case3"
cat > "$TMP/case3/profile.md" <<'EOF'
---
last_updated: 2026-05-19
---
v1
EOF
"$ARCHIVE" "$TMP/case3/profile.md" >/dev/null
cat > "$TMP/case3/profile.md" <<'EOF'
---
last_updated: 2026-05-19
---
v2
EOF
"$ARCHIVE" "$TMP/case3/profile.md" >/dev/null
cat > "$TMP/case3/profile.md" <<'EOF'
---
last_updated: 2026-05-19
---
v3
EOF
"$ARCHIVE" "$TMP/case3/profile.md" >/dev/null
assert_file_exists "case3: first archive at unsuffixed path" \
  "$TMP/case3/_archive/profile.2026-05-19.md"
assert_file_exists "case3: second archive at .1" \
  "$TMP/case3/_archive/profile.2026-05-19.1.md"
assert_file_exists "case3: third archive at .2" \
  "$TMP/case3/_archive/profile.2026-05-19.2.md"

# --- Case 4: non-existent source → silent no-op, exit 0.
set +e
"$ARCHIVE" "$TMP/case4/does-not-exist.md" >/dev/null
RC=$?
set -e
assert_eq "case4: nonexistent file exits 0 silently" "0" "$RC"

# --- Case 5: file inside subdir (frameworks/) → archive next to it.
mkdir -p "$TMP/case5/frameworks"
cat > "$TMP/case5/frameworks/tki.md" <<'EOF'
---
framework: thomas-kilmann-tki
last_updated: 2026-04-15
---
EOF
"$ARCHIVE" "$TMP/case5/frameworks/tki.md" >/dev/null
assert_file_exists "case5: subdir file archived in sibling _archive/" \
  "$TMP/case5/frameworks/_archive/tki.2026-04-15.md"

# --- Case 6: archive preserves file content (byte-identical copy).
mkdir -p "$TMP/case6"
cat > "$TMP/case6/profile.md" <<'EOF'
---
last_updated: 2026-01-01
---
exact bytes preserved
EOF
EXPECTED_HASH=$(sha256sum "$TMP/case6/profile.md" | awk '{print $1}')
"$ARCHIVE" "$TMP/case6/profile.md" >/dev/null
ACTUAL_HASH=$(sha256sum "$TMP/case6/_archive/profile.2026-01-01.md" | awk '{print $1}')
assert_eq "case6: archived file is byte-identical to source" "$EXPECTED_HASH" "$ACTUAL_HASH"

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]

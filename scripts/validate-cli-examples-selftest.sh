#!/usr/bin/env bash
#
# Proves the CLI-example gate REJECTS, including the multi-line and
# duplicate-flag cases, and stays silent on correct examples.
#
# The way this gate would decay is by reverting to a per-line grep: that passes
# every multi-line command (the flag is simply on another line) while still
# looking like it works, and multi-line is the dominant form in these skills.
# So the fixture holds one of each shape and this test pins the count.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

GATE=./scripts/validate-cli-examples.sh
FIXTURE=scripts/__fixtures__/kpis-create-no-scope.md
EXPECTED_MISSING=2
EXPECTED_DUPLICATE=1
log=$(mktemp); trap 'rm -f "$log"' EXIT

echo "=== self-test: the CLI-example gate must REJECT $FIXTURE ==="

if "$GATE" "$FIXTURE" >"$log" 2>&1; then
  echo "FAIL: the gate ACCEPTED examples that omit the required --scope."
  sed 's/^/      /' "$log"; exit 1
fi

# Count the REPORT lines only, not the GitHub annotations. Under
# GITHUB_ACTIONS the gate also emits `::error ...::MISSING --scope ...` for
# each finding, so a bare `grep -c MISSING` doubles every count — and does so
# ONLY in CI, which is exactly where this test is load-bearing. That is how
# this self-test passed locally and failed on the first CI run.
miss=$(grep -cE '^ +MISSING \(near' "$log" || true)
dup=$(grep -cE '^ +DUPLICATE \(near' "$log" || true)

if [ "$miss" -ne "$EXPECTED_MISSING" ]; then
  echo "FAIL: caught $miss missing-scope example(s), expected $EXPECTED_MISSING."
  echo "      If it caught 1, the gate is matching per LINE again and the"
  echo "      multi-line form slipped through — that is the dominant form here."
  sed 's/^/      /' "$log"; exit 1
fi
if [ "$dup" -ne "$EXPECTED_DUPLICATE" ]; then
  echo "FAIL: caught $dup duplicate-scope example(s), expected $EXPECTED_DUPLICATE."
  sed 's/^/      /' "$log"; exit 1
fi
echo "  OK: rejected $miss missing and $dup duplicate, across single- and multi-line forms"

# And it must not fire on the two correct examples in the same file — if it did,
# the count above would be 4, so this is already proved. State it explicitly so
# a future edit to the fixture cannot quietly drop the positive cases.
if [ "$(grep -cE '^ +(MISSING|DUPLICATE) \(near' "$log")" -ne 3 ]; then
  echo "FAIL: the gate flagged one of the two CORRECT examples."
  sed 's/^/      /' "$log"; exit 1
fi
echo "  OK: silent on the correct single-line and continuation forms"

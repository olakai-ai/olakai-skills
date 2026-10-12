#!/usr/bin/env bash
#
# Proves the argument-substitution gate REJECTS, and rejects the non-obvious
# spellings too.
#
# The failure mode to guard against is a narrowed pattern: someone decides a
# fenced code block or an inline `$0` is inert (it is not — measured), carves
# an exception, and the gate goes quiet on the spellings most likely to appear
# in a skill full of worked examples. So the fixture puts each spelling on its
# own line and this test requires the gate to catch EVERY one.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

GATE=./scripts/validate-arg-substitution.sh
FIXTURE=scripts/__fixtures__/unescaped-dollar-digit.md
EXPECTED=4   # bare prose, inline code span, table row, fenced block
log=$(mktemp)
trap 'rm -f "$log"' EXIT

echo "=== self-test: the argument-substitution gate must REJECT $FIXTURE ==="

if "$GATE" "$FIXTURE" >"$log" 2>&1; then
  echo "FAIL: the gate ACCEPTED a file full of unescaped \$<digit>."
  sed 's/^/      /' "$log"
  exit 1
fi

got=$(grep -cE '^        line ' "$log" || true)
if [ "$got" -ne "$EXPECTED" ]; then
  echo "FAIL: the gate reported $got occurrence(s), expected $EXPECTED."
  echo "      If it found fewer, the pattern was narrowed — most likely by"
  echo "      exempting code spans or fenced blocks, which ARE substituted."
  echo "      If more, the escaped amounts or \$AGENT_ID are being flagged."
  sed 's/^/      /' "$log"
  exit 1
fi
echo "  OK: rejected, catching all $EXPECTED spellings"

# ...and it must stay SILENT on the escaped forms the sweep produced, plus
# non-digit dollars. Without this half, the way to make the gate "pass" is to
# broaden the pattern until every corrected skill fails, and nothing catches it.
SAFE=scripts/__fixtures__/escaped-dollar-digit.md
if ! "$GATE" "$SAFE" >"$log" 2>&1; then
  echo "FAIL: the gate REJECTED $SAFE, which contains only safe spellings."
  echo "      The pattern is too broad — it is flagging \\\$ escapes or a"
  echo "      non-digit \$ like \$AGENT_ID. Narrow it, do not edit the fixture."
  sed 's/^/      /' "$log"
  exit 1
fi
echo "  OK: silent on escaped amounts, \$AGENT_ID and \$ 50"

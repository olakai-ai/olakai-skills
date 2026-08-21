#!/usr/bin/env bash
#
# Proves that `validate-tune-safety.sh` REJECTS as well as accepts.
#
# A validator made of greps degrades in one direction: patterns get loosened to
# stop them failing, until the script passes anything. The first version of it
# had already reached that state — it matched bare tokens, and a reviewer's
# 25-line gutted SKILL.md, ending in an instruction to apply edits immediately
# without asking, passed all 25 checks.
#
# So the gate has a gate. This runs the validator against a checked-in fixture
# of exactly that shape and fails if it comes back clean.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

FIXTURE="scripts/__fixtures__/gutted-skill.md"

echo "=== self-test: the validator must REJECT $FIXTURE ==="

if ./scripts/validate-tune-safety.sh "$FIXTURE" >/tmp/tune-safety-selftest.log 2>&1; then
  echo "FAIL: the validator PASSED a file with every safety rule stripped."
  echo "      It is no longer gating anything. Tighten the patterns in"
  echo "      scripts/validate-tune-safety.sh — do not weaken this self-test."
  exit 1
fi

failures=$(grep -c '^FAIL' /tmp/tune-safety-selftest.log || true)
echo "  OK: rejected, with $failures failing checks"

# A single failing check would technically "reject", but it would also mean the
# other patterns had gone slack. Require the rejection to be emphatic.
if [ "$failures" -lt 20 ]; then
  echo "FAIL: only $failures checks caught the gutted fixture (expected >= 20)."
  echo "      The patterns have drifted toward matching bare tokens again."
  exit 1
fi

echo "  OK: the rejection is broad, not incidental"

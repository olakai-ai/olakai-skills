#!/usr/bin/env bash
#
# Proves `validate-descriptions.sh` MEASURES, in both directions.
#
# A length gate does not go slack the way a grep-based one does. It drifts its
# ARITHMETIC: someone reaches for `wc -c`, or folds a `>` scalar with
# `tr '\n' ' '`, or forgets clip chomping — and the number is quietly wrong by
# one, or by eighty. The gate still looks like it works. It just gates the wrong
# thing, and the honest-looking number it prints is what gets cited.
#
# So the fixtures straddle the cap by ONE character and the expected lengths are
# asserted EXACTLY. A folding bug moves the number and fails this test whichever
# way it moves. Do not relax an assertion to make it pass; fix the folding.
#
# Lengths are asserted through the gate's `--lengths` mode, not by grepping its
# FAIL/WARN/OK prose. The first version grepped the WARN wording, so it only
# worked while the fixtures happened to sit above the warn line: raising the
# warn threshold made it fail — while printing the correct number — and blame
# the folding. A gate that red-lights correct code with a false explanation is
# the same sin as one that green-lights what it should reject, facing the other
# way.
#
# This caught a real error: the two `|` literal descriptions in this repo were
# reported to be 1836 and 1341 characters. They are 1877 and 1474. Two
# independent implementations (this gate, and Ruby's libyaml-backed YAML
# loader) agree on all thirteen skills; the earlier figures were measured by
# hand and were wrong for exactly the two literal blocks.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

GATE=./scripts/validate-descriptions.sh
F=scripts/__fixtures__
status=0
log=$(mktemp)
trap 'rm -f "$log"' EXIT

# <fixture> <expected-length> [expected-style]
expect_pass() {
  local fx="$F/$1" want="$2" style="${3:-}"
  if ! "$GATE" "$fx" >"$log" 2>&1; then
    echo "FAIL: the gate REJECTED $fx, which is at or under the cap."
    sed 's/^/      /' "$log"
    status=1
    return
  fi
  local got
  got=$("$GATE" --lengths "$fx" | cut -f2)
  if [ "$got" != "$want" ]; then
    echo "FAIL: $fx measured $got characters, expected $want."
    echo "      The block-scalar folding is wrong — characters vs bytes, the"
    echo "      \`>\` fold, or chomping. Fix the folding, not this number."
    status=1
    return
  fi
  if [ -n "$style" ]; then
    local got_style
    got_style=$("$GATE" --lengths "$fx" | cut -f3)
    if [ "$got_style" != "$style" ]; then
      echo "FAIL: $fx parsed as style '$got_style', expected '$style'."
      status=1
      return
    fi
  fi
  echo "  OK: $1 accepted, measured at exactly $want${style:+ ($style)}"
}

# <fixture> <substring the failure must contain>
expect_fail() {
  local fx="$F/$1" want="$2"
  if "$GATE" "$fx" >"$log" 2>&1; then
    echo "FAIL: the gate ACCEPTED $fx, which it exists to reject."
    sed 's/^/      /' "$log"
    status=1
    return
  fi
  if ! grep -q -- "$want" "$log"; then
    echo "FAIL: $fx was rejected, but not for the expected reason ($want)."
    echo "      A gate that rejects for the wrong reason prescribes the wrong fix."
    sed 's/^/      /' "$log"
    status=1
    return
  fi
  echo "  OK: $1 rejected, for the right reason"
}

echo "=== self-test: the description gate must measure, not guess ==="

# Exactly at the cap, folded. Must pass. Pins the fold arithmetic: a
# space-vs-newline error anywhere in this scalar moves the number off 1024.
expect_pass description-at-cap.md 1024 ">"

# One character over, literal. Must fail. Pins the boundary, and proves `|` is
# measured as a literal — folding it to `>` would change the text and the length.
expect_fail description-over-cap.md "description of 1025 characters"

# 1024 characters in 1104 bytes. Must pass. `wc -c` and awk fail this one.
expect_pass description-multibyte.md 1024 ">"

# A more-indented line inside a folded scalar keeps its breaks literally — the
# most intricate branch in the parser, and the one no fixture covered when this
# gate was first written.
expect_pass description-more-indented.md 150 ">"

# Chomping indicators change the value's length. `|+` measured as clip for a
# while, which was unbounded under-reporting, not an off-by-one.
expect_pass description-chomp-keep.md 1024 "|+"

# The spec also forbids `<` and `>` inside a description.
expect_fail description-angle-bracket.md "forbids"

echo ""
if [ "$status" -ne 0 ]; then
  echo "The description gate is no longer measuring what it claims to measure."
  echo "If a fixture was changed deliberately, update its expected length in the"
  echo "SAME commit and say why in the commit message."
fi
exit "$status"

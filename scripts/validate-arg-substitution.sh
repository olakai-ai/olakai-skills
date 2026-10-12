#!/usr/bin/env bash
#
# Skill bodies must not contain an unescaped `$` followed by a digit.
#
# ## Why
#
# Claude Code substitutes positional arguments into a skill body at invoke
# time: `$0` becomes the first argument, `$1` the second, and so on. It does
# not care that the `$` was a currency symbol. So a skill invoked as
#
#     /olakai-finops last 30 days
#
# read its own rule 13 as *"`last` is a real budget meaning no spend allowed"*
# — the `$0`-vs-absent distinction the skill exists to protect, destroyed by
# its own argument. Every documented default went the same way: `$55/hour`,
# `$200/developer/month`, `$114,400/yr`. 46 occurrences across 7 skills
# (OLA-1611).
#
# ## What protects it, measured
#
# Probed against a live skill invoked with five arguments:
#
#     $0            -> ALPHA           substituted
#     `$0`          -> `ALPHA`         substituted — BACKTICKS DO NOT PROTECT
#     ```$0```      -> ALPHA           substituted — CODE FENCES DO NOT PROTECT
#     $$0           -> $ALPHA          substituted
#     \$0           -> $0              SAFE
#     $AGENT_ID     -> $AGENT_ID       untouched (not a digit)
#
# So `\$` is the fix, and it is the whole fix: the backslash is consumed, the
# agent receives a literal `$0`, and markdown renders it as `$0`. No amount has
# to be reworded into `USD 55` to be safe.
#
# The two negative results are the ones worth keeping written down: a reviewer
# will assume a fenced block or an inline code span is inert, and it is not.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  FILES=(skills/*/SKILL.md)
fi

status=0

echo "=== Skill bodies: no unescaped \$<digit> (argument substitution) ==="

for file in "${FILES[@]}"; do
  # A `$` taken as a positional argument is one not preceded by a backslash.
  hits=$(grep -nE '(^|[^\])\$[0-9]' "$file" || true)
  if [ -n "$hits" ]; then
    count=$(printf '%s\n' "$hits" | wc -l | tr -d ' ')
    echo "FAIL: $file — $count unescaped \$<digit> occurrence(s); write them as \\\$0, not \$0"
    printf '%s\n' "$hits" | while IFS= read -r line; do
      lineno=${line%%:*}
      echo "        line $lineno: $(printf '%s' "${line#*:}" | cut -c1-96)"
      [ -n "${GITHUB_ACTIONS:-}" ] && echo "::error file=$file,line=$lineno::Unescaped \$<digit> is replaced by a skill argument at invoke time; write \\\$ instead"
    done
    status=1
  else
    echo "  OK: $(basename "$(dirname "$file")")"
  fi
done

exit $status

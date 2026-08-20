#!/usr/bin/env bash
#
# Safety pins for skills/olakai-tune-my-setup/SKILL.md (OLA-1053).
#
# This skill is prose that tells an agent when it may rewrite the files
# governing that agent — CLAUDE.md, skills, subagent definitions, hooks, model
# and permission config. Prose has no type system, so the rules that make it
# safe can be deleted or softened in an edit and nothing would fail.
#
# Each check below is one rule the skill must keep stating. A failure here means
# a safety property was removed, not that the wording drifted — the patterns
# match on the load-bearing phrase, not on a whole sentence.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

FILE="skills/olakai-tune-my-setup/SKILL.md"
status=0

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE is missing"
  exit 1
fi

# `check <label> <extended-regex>`
check() {
  local label="$1" pattern="$2"
  if grep -Eqi -- "$pattern" "$FILE"; then
    echo "  OK: $label"
  else
    echo "FAIL: $label — the skill no longer states this rule (pattern: $pattern)"
    status=1
  fi
}

echo "=== olakai-tune-my-setup safety rules ==="

# 1. Approval before any write, as a SEPARATE turn. Bundling the diff and the
#    edit into one turn is the failure mode this rule exists to prevent.
check "shows a diff before writing"          'show the diff|exact diff'
check "waits for approval in a separate turn" 'End your turn\. Wait for the user'
check "per-change approval, not blanket"      'Approval is per-change'

# 2. Untrusted free text may never drive an edit; only closed enums may.
check "closed enums are the only edit driver" 'Only closed-enum keys may drive an edit'
check "names the closed enum keys"            'dimension.*patternKey.*leverKey'
check "free text is quote-only"               'Quote it to the user\. Nothing else'
check "refuses injected imperatives"          'ignore previous instructions|injection attempt'
check "free text cannot select a command"     'never.*select a file path, a shell command'

# 3. Bounded proposal count.
check "two or three changes, never ten"       'Propose two or three changes'

# 4. Honest refusal — no generic advice when there is no evidence.
check "refuses on feature_not_enabled"        'feature_not_enabled'
check "refuses on no grounded growth edge"    'no_grounded_growth_edge'
check "forbids the generic-advice fallback"   'Do not fall back to generic advice'

# 5. No invented numbers. The null-ROI case is called out by name because it is
#    the one where a fabricated $0 is most tempting.
check "null rate is unobserved, not zero"     'never.*observable.*Say .unobserved.|It is not 0%'
check "null ROI yields no dollar figures"     'no dollar figures in it at all'
check "never substitutes personalSpendCents"  'never substitute .?personalSpendCents'

# 6. The write surface is bounded — no traversal, no credentials, no escape.
check "bounds the editable surfaces"          'Never touch a file outside the setup surfaces'
check "rejects path traversal"                'no path containing'
check "rejects unresolved symlinks"           'no symlink you have not resolved'
check "rejects credential files"              'no .?\.env|no credential file'

# 7. Re-runs check adoption before proposing anything new.
check "checks adoption before re-proposing"   'Before proposing anything new'
check "leads with not_adopted"                'not_adopted'
check "never reads a dead lever as a failure" 'never actually running|was never running'

# 8. Recording is honest about what it is.
check "records only closed enum keys"         'never invented'
check "calls the measurement observational"   'observational'
check "does not promise the change worked"    'not a promise that the change worked'

echo ""
if [ "$status" -ne 0 ]; then
  echo "One or more safety rules are no longer stated in $FILE."
  echo "If a rule was deliberately changed, update this script in the same commit"
  echo "and say why in the commit message."
fi
exit "$status"

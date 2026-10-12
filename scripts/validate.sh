#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

status=0

# Frontmatter: required fields, name rules, and description length.
#
# This replaces an inline loop that could never fail. It extracted the
# frontmatter with
#   sed -n '1,/^---$/{ /^---$/d; p; }'
# which ranges line 1 to the FIRST /^---$/ — line 1 itself — then deletes it,
# so the variable was always empty and the name/description presence checks
# under it always passed. Nothing was lost by deleting it; the replacement
# checks the same two fields and measures the description as well.
./scripts/validate-descriptions.sh || status=1
echo ""
# …and the gate has a gate. A length gate degrades by drifting its ARITHMETIC,
# so prove it still measures the fixtures exactly, not merely that it rejects.
./scripts/validate-descriptions-selftest.sh || status=1

echo ""
echo "=== Verifying symlinks ==="
for link in plugins/olakai/skills/*/; do
  link="${link%/}"
  if [ -L "$link" ]; then
    if [ ! -e "$link/SKILL.md" ]; then
      echo "FAIL: broken symlink — $link"
      status=1
    else
      echo "  OK: $(basename "$link") -> $(readlink "$link")"
    fi
  fi
done

for skill_dir in skills/*/; do
  skill_name=$(basename "$skill_dir")
  if [ ! -L "plugins/olakai/skills/$skill_name" ]; then
    echo "FAIL: missing symlink for $skill_name"
    status=1
  fi
done

echo ""
# The tune skill rewrites the files that govern the agent, so the rules that
# keep it safe are pinned rather than trusted to survive an edit (OLA-1053).
./scripts/validate-tune-safety.sh || status=1
# …and the gate has a gate: prove it still rejects a file with the rules
# stripped, so the patterns cannot drift back into matching bare tokens.
./scripts/validate-tune-safety-selftest.sh || status=1

echo ""
echo "=== Linting markdown ==="
# CI runs the pinned markdownlint-cli2 ACTION as its own step, so skip this one
# there: running both would either lint twice or quietly trade a pinned action
# for an unpinned `npx --yes` fetch.
if [ -n "${CI:-}" ]; then
  echo "SKIP: CI runs markdownlint as its own pinned step"
elif command -v npx &>/dev/null; then
  npx --yes markdownlint-cli2 "skills/**/*.md" --config .markdownlint.json && echo "  OK: no lint errors" || status=1
else
  echo "SKIP: npx not found — install Node.js to run markdown lint"
fi

echo ""
if [ $status -eq 0 ]; then
  echo "All checks passed."
else
  echo "Some checks failed."
fi
exit $status

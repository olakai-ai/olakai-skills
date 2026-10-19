#!/usr/bin/env bash
#
# Every `olakai kpis create` example must pass --scope.
#
# ## Why
#
# The API makes it mandatory — `scope: kpiScopeSchema`, not optional, in
# apps/main-app/src/app/api/config/kpis/route.ts — and the CLI has no default,
# so an example without it fails outright:
#
#   $ olakai kpis create --name zz --calculator-id formula --formula 1
#   error: required option '--scope <scope>' not specified
#
# 13 examples across 5 skills shipped that way (OLA-1611). An agent following
# one hits an error it did not cause and cannot fix from the surrounding text,
# which is the worst kind of documentation bug: it burns a turn and leaves the
# user believing the product is broken.
#
# `olakai kpis create --help` does not say the flag is required, so there is no
# second chance to notice.
#
# ## Why a script and not review
#
# The examples are mostly MULTI-LINE, continued with backslashes, so a reviewer
# scanning a diff sees `--calculator-id formula \` and has to look two lines
# further to tell whether --scope is there. This script joins continuations
# first, which is also what makes it catch the duplicate-flag case: a blanket
# regex sweep added a second --scope to the one file that was already correct,
# and only the joined view showed it.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  FILES=(skills/*/SKILL.md)
fi

status=0

echo "=== CLI examples: \`olakai kpis create\` must pass --scope ==="

for file in "${FILES[@]}"; do
  # Join shell line-continuations so each command is one logical line.
  out=$(perl -0777 -ne '
    s/\\\n\s*/ /g;
    my $ln = 0;
    for my $line (split /\n/) {
      $ln++;
      next unless $line =~ /olakai kpis create/;
      # Count flags, not prose: a trailing `# ... (--scope is required)`
      # comment is not a second --scope, and must not stand in for a
      # missing one either. Only a comment after whitespace is stripped, so
      # a "#" inside a quoted argument with no space before it survives.
      (my $cmd = $line) =~ s/\s+#\s.*$//;
      my $n = () = $cmd =~ /--scope/g;
      print "MISSING\t$ln\t$line\n"   if $n == 0;
      print "DUPLICATE\t$ln\t$line\n" if $n > 1;
    }
  ' "$file")
  # NOTE: the line number above is the number AFTER joining continuations, so it
  # is approximate for multi-line commands. The command text is printed in full
  # precisely because that, not the number, is what locates it.
  if [ -n "$out" ]; then
    echo "FAIL: $file"
    printf '%s\n' "$out" | while IFS=$'\t' read -r kind ln cmd; do
      echo "        $kind (near joined line $ln): $(printf '%s' "$cmd" | cut -c1-92)"
      [ -n "${GITHUB_ACTIONS:-}" ] && echo "::error file=$file::$kind --scope in an \`olakai kpis create\` example; the API requires it and the CLI has no default"
    done
    status=1
  else
    echo "  OK: $(basename "$(dirname "$file")")"
  fi
done

exit $status

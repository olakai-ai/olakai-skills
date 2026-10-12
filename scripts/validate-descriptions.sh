#!/usr/bin/env bash
#
# SKILL.md frontmatter gate: description length, plus the handful of other
# frontmatter rules that cost portability when broken.
#
# ## Why this exists
#
# The Agent Skills spec caps `description` at 1024 characters. Claude Code does
# NOT enforce that: it truncates `description` + `when_to_use` at 1536 in the
# skill listing, and separately DROPS whole descriptions once the listing
# exceeds ~1% of the model's context window, starting with the skills you invoke
# least. So an over-cap description does not fail to load — it fails to be
# portable, and it quietly spends context that every other skill's routing text
# has to share. Nothing anywhere reports either effect. Hence a gate.
#
# Four descriptions in this repo shipped between 1206 and 1836 characters before
# anything measured them.
#
# ## Why perl, and not awk / yq / python
#
# The cap is in CHARACTERS, and these descriptions are full of em dashes:
#
#   * `wc -c` reads the folded olakai-finops description as 1047 BYTES against
#     1008 characters. It would fail a COMPLIANT file, and the obvious "fix" is
#     to raise the threshold — so the wrong tool here corrupts the limit itself.
#   * awk is byte-oriented too (mawk on ubuntu-latest, BSD awk on macOS):
#     length("—") is 3, not 1.
#   * yq is not installed and not declared anywhere in this repo.
#   * the python3 on a dev box here has no PyYAML.
#   * npx would mean a network fetch to run a gate. npx is guarded-OPTIONAL in
#     validate.sh for markdownlint; a gate cannot be optional.
#
# perl 5 plus core Encode is present on macOS and on ubuntu-latest with nothing
# to install, and decode_utf8 + length counts characters.
#
# ## Relationship to Anthropic's own validator
#
# The reference implementation is quick_validate.py, shipped inside the official
# skill-creator skill:
#
#   ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/
#     skills/skill-creator/scripts/quick_validate.py
#
# It cannot be vendored — it is `import yaml` top to bottom, takes a skill
# DIRECTORY, and early-returns on the first error, which is the opposite of this
# repo's "accumulate into status, report everything" convention. Its CONSTANTS
# are reimplemented below; diff against it when the spec moves. One deliberate
# difference: it measures description.strip(), so it reports exactly one
# character fewer than the clip-chomped value this script reports.
#
# ## Why the block-scalar folding is hand-rolled
#
# Every description here is a YAML block scalar — 8 folded (`>`), 5 literal
# (`|`), all with default clip chomping. `wc -c` of the `description:` LINE
# returns 1 or 2 characters. Folding implemented below: for `>`, a single break
# becomes a space, k blank lines become k newlines, and a more-indented line
# keeps its breaks literally; for `|`, breaks are preserved; clip means exactly
# one trailing newline.
#
# Converting `|` to `>` is NOT a reflow. It turns embedded newlines into spaces,
# which changes both the rendered text and the length. Do not bring an over-cap
# `|` skill under the limit by swapping the indicator.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# `--lengths` prints one `<path>\t<chars>\t<style>` line per file and nothing
# else, so the self-test can assert exact numbers without scraping FAIL/WARN/OK
# prose. Its first version grepped the WARN wording and therefore only worked
# while the fixtures happened to sit above the warn line — raising the warn
# threshold made it fail while reporting the right number, and blame the folding.
PRINT_LENGTHS=0
if [ "${1:-}" = "--lengths" ]; then PRINT_LENGTHS=1; shift; fi

# Default to every real skill. The self-test passes fixtures instead, so the
# gate can be proved to reject — and proved EXACT, not merely directional.
if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  FILES=(skills/*/SKILL.md)
fi

# Hard cap from the spec. Over this fails the build.
MAX_DESCRIPTION="${MAX_DESCRIPTION:-1024}"
# Warn line. olakai-finops shipped at 1008 — 16 characters of headroom — so a
# bare 1024 gate would let the next edit to it break CI by surprise. A warn does
# NOT fail the build; if it did, this would just be a lower cap wearing a
# different word, and the first response to it would be to raise the number.
# 1010, not something tighter: olakai-finops ships at 1008 and is compliant, and
# a warn that fires on a correct file is a warn people learn to ignore. The band
# is for catching the next edit, not for relitigating a passing one.
WARN_DESCRIPTION="${WARN_DESCRIPTION:-1010}"

[ "$PRINT_LENGTHS" -eq 1 ] || echo "=== SKILL.md frontmatter: description length and spec limits ==="

MAX_DESCRIPTION="$MAX_DESCRIPTION" WARN_DESCRIPTION="$WARN_DESCRIPTION" \
PRINT_LENGTHS="$PRINT_LENGTHS" \
  perl - "${FILES[@]}" <<'PERL'
use strict;
use warnings;
use Encode qw(decode_utf8 FB_CROAK);

my $MAX  = $ENV{MAX_DESCRIPTION}  || 1024;
my $WARN = $ENV{WARN_DESCRIPTION} || 975;
my $GHA  = $ENV{GITHUB_ACTIONS} ? 1 : 0;
my $LENGTHS_ONLY = $ENV{PRINT_LENGTHS} ? 1 : 0;

# Mirrors ALLOWED_PROPERTIES in Anthropic's quick_validate.py.
my %ALLOWED = map { $_ => 1 }
  qw(name description license allowed-tools metadata compatibility);

my $status = 0;
# Per-file, so a file that already failed one check never also prints an OK
# line. A FAIL and an OK for the same path reads as a passing file to anyone
# skimming, which is the opposite of what a gate is for.
my $clean = 1;

sub problem {
  my ($file, $msg) = @_;
  # ${file} is brace-delimited deliberately: "$file::$msg" makes perl read
  # `$file::` as a package-qualified name, and the path drops out of the
  # annotation — visible only in CI, where the annotation is the whole point.
  print "FAIL: $file — $msg\n";
  print "::error file=${file}::$msg\n" if $GHA;
  $status = 1;
  $clean  = 0;
}

sub caution {
  my ($file, $msg) = @_;
  print "WARN: $file — $msg\n";
  print "::warning file=${file}::$msg\n" if $GHA;
}

# ---------------------------------------------------------------------------
# Frontmatter extraction, bounded at the SECOND `---`.
#
# The bound is the whole point. The check this replaces used
#   sed -n '1,/^---$/{ /^---$/d; p; }'
# which ranges line 1 to the FIRST /^---$/ — that is line 1 itself — and then
# deletes it, so the variable was ALWAYS empty and the name/description presence
# checks underneath it could never fail. Scanning to EOF instead would be just
# as wrong in the other direction: these SKILL.md bodies carry a dozen `---`
# horizontal rules each (olakai-governance has 14).
# ---------------------------------------------------------------------------
sub frontmatter_lines {
  my ($file) = @_;
  open my $fh, '<:raw', $file or do { problem($file, "cannot be read"); return (undef, 0, 1) };
  my $raw = do { local $/; <$fh> };
  close $fh;

  my $txt = eval { decode_utf8($raw, FB_CROAK) };
  if (!defined $txt) { problem($file, "is not valid UTF-8"); return (undef, 0, 1) }

  my $crlf = ($txt =~ s/\r\n/\n/g) ? 1 : 0;
  $txt =~ s/\r/\n/g;

  my @all = split /\n/, $txt, -1;
  return (undef, $crlf, 0) unless @all && $all[0] =~ /^---[ \t]*$/;

  my (@fm, $closed);
  for my $i (1 .. $#all) {
    if ($all[$i] =~ /^---[ \t]*$/) { $closed = 1; last }
    push @fm, $all[$i];
  }
  return (undef, $crlf, 0) unless $closed;
  return (\@fm, $crlf, 0);
}

# ---------------------------------------------------------------------------
# Block-scalar folding. Returns ($value, $style), or (undef, $reason).
# ---------------------------------------------------------------------------
sub scalar_value {
  my ($fm, $idx) = @_;
  my ($rest) = $fm->[$idx] =~ /^description:(.*)$/;
  $rest = '' unless defined $rest;

  # Quoted scalars need escape processing (\n, \", \uXXXX). Nothing here uses
  # one, and hand-rolling that would be a wrong number waiting to happen. Refuse
  # instead: a gate that says "I cannot measure this" beats one that guesses.
  if ($rest =~ /^\s*["']/) {
    return (undef, 'is a quoted scalar — use a `>` or `|` block scalar so its length can be measured');
  }

  if ($rest =~ /^\s*([|>])([0-9]*)([-+]?)\s*(?:#.*)?$/) {
    my ($ind, $explicit, $chomp) = ($1, $2, $3);

    my @body;
    for my $k ($idx + 1 .. $#$fm) {
      my $l = $fm->[$k];
      if ($l =~ /^[ \t]*$/) { push @body, ''; next }
      last unless $l =~ /^ /;          # the parent key sits at indent 0
      return (undef, 'uses a tab for indentation inside the description block')
        if $l =~ /^ *\t/;
      push @body, $l;
    }
    # Count the trailing blank lines before dropping them: clip keeps exactly
    # one newline, keep (`+`) keeps all of them. Measuring `+` as clip was a
    # silent wrong number — unbounded, not off-by-one — in a script whose whole
    # contract is to refuse rather than guess.
    my $trailing_blanks = 0;
    while (@body && $body[-1] eq '') { pop @body; $trailing_blanks++ }

    my $ci = $explicit ? $explicit + 0 : undef;
    if (!defined $ci) {
      for my $l (@body) { next if $l eq ''; ($l =~ /^( *)/) and $ci = length($1); last }
    }
    $ci = 0 unless defined $ci;
    my @c = map { $_ eq '' ? '' : substr($_, $ci) } @body;

    my $out = '';
    if ($ind eq '|') {
      $out = join("\n", @c);
      $out .= "\n" if @c;
    } else {
      my $prev_more = 0;
      for my $n (0 .. $#c) {
        my $l    = $c[$n];
        my $more = ($l ne '' && $l =~ /^ /) ? 1 : 0;
        if ($n == 0)          { $out = $l; $prev_more = $more; next }
        if ($l eq '')         { $out .= "\n"; $prev_more = 0;  next }
        if    ($out =~ /\n\z/)      { $out .= $l }          # break already emitted
        elsif ($more || $prev_more) { $out .= "\n" . $l }   # more-indented: literal
        else                        { $out .= ' '  . $l }   # the fold
        $prev_more = $more;
      }
      $out =~ s/\n+\z//;
      $out .= "\n" if length $out;
    }

    if    ($chomp eq '-') { $out =~ s/\n+\z// }                       # strip
    elsif ($chomp eq '+') { $out .= "\n" x $trailing_blanks }         # keep
    # else: clip, already applied above.
    return ($out, $ind . $chomp);
  }

  # Plain scalar on one line.
  my $v = $rest;
  $v =~ s/^\s+//;
  $v =~ s/\s+$//;

  # A plain scalar MAY continue onto following indented lines. Measuring only
  # the first would under-report, i.e. silently pass an over-cap description.
  if ($idx < $#$fm && $fm->[$idx + 1] =~ /^\s+\S/) {
    return (undef, 'is a multi-line plain scalar — use `description: >` so the folded value is unambiguous');
  }
  return ($v, 'plain');
}

# ---------------------------------------------------------------------------
for my $file (@ARGV) {
  $clean = 1;
  my ($fm, $crlf, $hard) = frontmatter_lines($file);
  next if $hard;
  if (!defined $fm) {
    problem($file, 'has missing or unterminated YAML frontmatter (needs `---` on line 1 and a closing `---`)');
    next;
  }
  caution($file, 'uses CRLF line endings; lengths are measured after normalising to LF') if $crlf;

  # Top-level keys only: matched at column 0, so nested metadata.* stays
  # invisible, which is what quick_validate.py's key check means too.
  my @keys = map { /^([A-Za-z0-9_-]+):/ ? $1 : () } @$fm;
  my %seen = map { $_ => 1 } @keys;

  my @unexpected = grep { !$ALLOWED{$_} } @keys;
  problem($file, 'has unexpected frontmatter key(s): ' . join(', ', sort @unexpected)
                . '. Allowed: ' . join(', ', sort keys %ALLOWED))
    if @unexpected;

  # --- name ---------------------------------------------------------------
  # NOTE: the spec says `name` should match the parent directory name. That is
  # deliberately NOT checked here. skills/olakai-status/SKILL.md declares
  # `name: olakai` ON PURPOSE, so that the slash command is `/olakai` rather
  # than `/olakai-status`. Adding a dirname check would fail that file, and the
  # next person to read the spec will want to add one. Don't.
  if (!$seen{name}) {
    problem($file, 'is missing the frontmatter field: name');
  } else {
    my ($n) = grep { defined } map { /^name:\s*(.*?)\s*$/ ? $1 : undef } @$fm;
    $n = '' unless defined $n;
    $n =~ s/^["']|["']$//g;
    if    ($n eq '')             { problem($file, 'has an empty name') }
    elsif (length($n) > 64)      { problem($file, 'has a name of ' . length($n) . ' characters; the spec caps it at 64') }
    elsif ($n !~ /^[a-z0-9-]+$/) { problem($file, "has the name '$n', which must match ^[a-z0-9-]+\$") }
    elsif ($n =~ /^-|-$|--/)     { problem($file, "has the name '$n', which cannot start or end with a hyphen or contain '--'") }
  }

  # --- description --------------------------------------------------------
  my ($didx) = grep { $fm->[$_] =~ /^description:/ } 0 .. $#$fm;
  if (!defined $didx) {
    problem($file, 'is missing the frontmatter field: description');
    next;
  }

  my ($desc, $style) = scalar_value($fm, $didx);
  if (!defined $desc) {
    problem($file, "description $style");
    next;
  }

  my $label = $file;
  $label =~ s{^skills/}{};
  $label =~ s{/SKILL\.md$}{};

  if (length($desc) == 0) {
    problem($file, 'has an empty description (the spec requires 1-1024 characters)');
    next;
  }

  if ($desc =~ /[<>]/) {
    problem($file, 'has a description containing `<` or `>`, which the spec forbids');
  }

  my $len = length($desc);

  if ($LENGTHS_ONLY) {
    print "$file\t$len\t$style\n";
    next;
  }

  if ($len > $MAX) {
    problem($file, "has a description of $len characters (style `$style`); the spec caps it at $MAX. "
                 . 'Trim ' . ($len - $MAX) . ' character'
                 . (($len - $MAX) == 1 ? '.' : 's.'));
  } elsif ($len > $WARN) {
    caution($file, "has a description of $len characters — under $MAX, but past the $WARN warn line, so only "
                 . ($MAX - $len) . ' characters of headroom remain. Trim it before the next edit does it for you.');
  } elsif ($clean) {
    printf "  OK: %s — %d chars (%s)\n", $label, $len, $style;
  }
}

exit $status
PERL

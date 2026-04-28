#!/usr/bin/env bash
# Audit AppTypography token contract violations.
#
# Contract: .copyWith on any AppTypography token may only override
# `color` or `fontStyle`. Any other property (fontSize, fontWeight,
# letterSpacing, height, fontFeatures) must be expressed as a token
# or documented with an // EXCEPTION comment on the preceding line.
#
# Usage:
#   bash tool/check_typography_overrides.sh          # audit only
#   bash tool/check_typography_overrides.sh --ci     # exit 1 if violations found

set -euo pipefail

DART_FILES=$(find lib -name '*.dart')
VIOLATIONS=0

while IFS= read -r line; do
  echo "$line"
  VIOLATIONS=$((VIOLATIONS + 1))
done < <(perl -0777 -ne '
  my $file = $ARGV;
  while (/AppTypography\.(\w+)\.copyWith\s*\(([^)]*)\)/gs) {
    my ($tok, $body) = ($1, $2);
    my @forbidden;
    for my $prop (qw(fontSize fontWeight letterSpacing height fontFeatures)) {
      if ($body =~ /\b$prop\s*:/) {
        # Allow if preceded by an // EXCEPTION comment (on prior line or inline)
        my $before = substr($`, 0, length($`));
        my $last_line = (split /\n/, $before)[-1] // "";
        my $penultimate = (split /\n/, $before)[-2] // "";
        next if $last_line =~ m{//\s*EXCEPTION} || $penultimate =~ m{//\s*EXCEPTION};
        push @forbidden, $prop;
      }
    }
    if (@forbidden) {
      my @lines = split(/\n/, substr($_, 0, pos($_)));
      my $ln = scalar @lines;
      print "$file:$ln  token=$tok  forbids=[@forbidden]\n";
    }
  }
' $DART_FILES 2>/dev/null)

if [[ "$VIOLATIONS" -eq 0 ]]; then
  echo "✓ No typography token contract violations found."
else
  echo ""
  echo "Found $VIOLATIONS violation(s)."
  if [[ "${1:-}" == "--ci" ]]; then
    exit 1
  fi
fi

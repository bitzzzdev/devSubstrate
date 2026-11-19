#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CATALOG="$ROOT/android/app-package-catalog.tsv"
SCRIPTS=(
  "$ROOT/android/scripts/manage-shopping-traffic.sh"
  "$ROOT/android/scripts/manage-shopping-traffic.fish"
  "$ROOT/android/termux-scripts/termux-manage-shopping-traffic.sh"
  "$ROOT/android/termux-scripts/termux-manage-shopping-traffic.fish"
)
test -s "$CATALOG"
awk -F '\t' '
  /^#/ || NF == 0 { next }
  NF != 4 { print "Invalid catalog row " NR > "/dev/stderr"; exit 1 }
  $2 !~ /^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$/ { print "Invalid package ID on row " NR > "/dev/stderr"; exit 1 }
  $4 != "restrict" && $4 != "keep" { print "Invalid policy on row " NR > "/dev/stderr"; exit 1 }
  seen[$2]++ { print "Duplicate package ID: " $2 > "/dev/stderr"; exit 1 }
  END { if (NR < 50) { print "Catalog unexpectedly small" > "/dev/stderr"; exit 1 } }
' "$CATALOG"
while IFS="$(printf '\t')" read -r category package app policy; do
  [[ -z "${category:-}" || "$category" == \#* ]] && continue
  if [[ "$policy" == "restrict" ]]; then
    for script in "${SCRIPTS[@]}"; do
      if ! grep -Fq "$package" "$script"; then
        echo "Missing target $package in $script" >&2
        exit 1
      fi
    done
  else
    for script in "${SCRIPTS[@]}"; do
      if grep -Fq ""$package"" "$script" || grep -Fq "    $package" "$script"; then
        echo "Protected package unexpectedly targeted: $package in $script" >&2
        exit 1
      fi
    done
  fi
done < "$CATALOG"
echo "PASS: catalog schema, package IDs, uniqueness, and four-script target parity."

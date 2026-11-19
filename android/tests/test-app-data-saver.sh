#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/android/scripts/app-data-saver.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/state"

cat > "$TMP/catalog.tsv" <<'CATALOG'
# category<TAB>package<TAB>app<TAB>policy
social	com.flipkart.android	Flipkart	restrict
social	com.instagram.android	Instagram	restrict
essential_messaging	com.whatsapp	WhatsApp	keep
shopping	com.snapdeal.main	Snapdeal	restrict
CATALOG

cat > "$TMP/packages.tsv" <<'PACKAGES'
com.flipkart.android	11001
com.whatsapp	11001
com.instagram.android	11002
com.snapdeal.main	11004
PACKAGES

printf '11004\n' > "$TMP/whitelist"
printf '11999\n' > "$TMP/blacklist"

cat > "$TMP/bin/adb" <<'ADB'
#!/usr/bin/env bash
set -euo pipefail
STATE="${MOCK_ADB_STATE:?}"
if [[ "$1" == "get-state" ]]; then
  echo device
  exit 0
fi
[[ "$1" == "shell" ]] || exit 2
shift
if [[ "$1" == "cmd" && "$2" == "netpolicy" && "$3" == "help" ]]; then
  echo "add restrict-background-blacklist UID"
  echo "list restrict-background-blacklist"
  exit 0
fi
if [[ "$1" == "cmd" && "$2" == "package" && "$3" == "list" && "$4" == "packages" && "$5" == "-U" ]]; then
  wanted="$6"
  while IFS=$'\t' read -r pkg uid; do
    [[ "$pkg" == "$wanted" ]] && printf 'package:%s uid:%s\n' "$pkg" "$uid"
  done < "$STATE/packages.tsv"
  exit 0
fi
if [[ "$1" == "cmd" && "$2" == "netpolicy" && "$3" == "get" ]]; then
  echo "Restrict background status: disabled"
  exit 0
fi
if [[ "$1" == "cmd" && "$2" == "netpolicy" && "$3" == "list" ]]; then
  case "$4" in
    restrict-background-blacklist) file="$STATE/blacklist" ;;
    restrict-background-whitelist) file="$STATE/whitelist" ;;
    *) exit 2 ;;
  esac
  if [[ -s "$file" ]]; then
    printf 'UIDs: '
    tr '\n' ' ' < "$file"
    echo
  else
    echo "UIDs: none"
  fi
  exit 0
fi
if [[ "$1" == "cmd" && "$2" == "netpolicy" && "$3" == "add" && "$4" == "restrict-background-blacklist" ]]; then
  grep -qxF "$5" "$STATE/blacklist" || printf '%s\n' "$5" >> "$STATE/blacklist"
  exit 0
fi
if [[ "$1" == "cmd" && "$2" == "netpolicy" && "$3" == "remove" && "$4" == "restrict-background-blacklist" ]]; then
  grep -vxF "$5" "$STATE/blacklist" > "$STATE/blacklist.new" || true
  mv "$STATE/blacklist.new" "$STATE/blacklist"
  exit 0
fi
echo "unexpected adb command: $*" >&2
exit 2
ADB
chmod +x "$TMP/bin/adb"

export PATH="$TMP/bin:$PATH"
export MOCK_ADB_STATE="$TMP"
export DEVSUBSTRATE_CATALOG_FILE="$TMP/catalog.tsv"
export DEVSUBSTRATE_STATE_DIR="$TMP/state"

bash "$SCRIPT" apply > "$TMP/apply.log"
grep -q 'BACKGROUND_METERED_BLOCKED' <(bash "$SCRIPT" status)
grep -qxF '11002' "$TMP/blacklist"
grep -qxF '11999' "$TMP/blacklist"
! grep -qxF '11001' "$TMP/blacklist"
! grep -qxF '11004' "$TMP/blacklist"
grep -qxF '11002' "$TMP/state/app-data-saver-uids.txt"

bash "$SCRIPT" revert > "$TMP/revert.log"
! grep -qxF '11002' "$TMP/blacklist"
grep -qxF '11999' "$TMP/blacklist"
test ! -e "$TMP/state/app-data-saver-uids.txt"

echo "PASS: app data policy apply, protected shared UID, allowlist preservation, status, and scoped revert."

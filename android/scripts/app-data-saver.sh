#!/usr/bin/env bash
#
# Apply per-app Android background metered-data restrictions through ADB.
# This does not enable global Data Saver or disable Wi-Fi/mobile data in the
# foreground. It uses the Android 11 NetworkPolicyManager UID denylist.
#
set -Eeuo pipefail

ACTION="${1:-status}"
CATALOG_URL="${DEVSUBSTRATE_CATALOG_URL:-https://gitlab.com/bitzzdev/devSubstrate/-/raw/dev/android/app-package-catalog.tsv}"
STATE_DIR="${DEVSUBSTRATE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/devsubstrate}"
STATE_FILE="$STATE_DIR/app-data-saver-uids.txt"
CATALOG_FILE=""
TEMP_CATALOG=""

cleanup() {
    [[ -n "$TEMP_CATALOG" ]] && rm -f "$TEMP_CATALOG"
}
trap cleanup EXIT

die() {
    echo "[!] $*" >&2
    exit 1
}

check_adb() {
    command -v adb >/dev/null 2>&1 || die "adb is not installed."
    adb get-state >/dev/null 2>&1 || die "No authorized ADB device. Connect the phone and accept its debugging prompt."
    local help
    help="$(adb shell cmd netpolicy help 2>&1 | tr -d '\r' || true)"
    grep -q "restrict-background-blacklist" <<< "$help" || die "This Android build does not expose the AOSP restrict-background-blacklist command."
}

load_catalog() {
    if [[ -n "${DEVSUBSTRATE_CATALOG_FILE:-}" ]]; then
        CATALOG_FILE="$DEVSUBSTRATE_CATALOG_FILE"
        [[ -r "$CATALOG_FILE" ]] || die "Catalog file is not readable: $CATALOG_FILE"
        return
    fi
    command -v curl >/dev/null 2>&1 || die "curl is required to download the app catalog."
    TEMP_CATALOG="$(mktemp)"
    curl -fsSL "$CATALOG_URL" -o "$TEMP_CATALOG" || die "Could not download the app catalog."
    CATALOG_FILE="$TEMP_CATALOG"
}

get_uid() {
    local pkg="$1"
    local record
    record="$(adb shell cmd package list packages -U "$pkg" 2>/dev/null | tr -d '\r' | awk -v wanted="package:$pkg" '$1 == wanted { print; exit }')"
    awk '{
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^uid:[0-9]+$/) {
                sub(/^uid:/, "", $i)
                print $i
                exit
            }
        }
    }' <<< "$record"
}

uid_listed() {
    local list="$1"
    local uid="$2"
    grep -Eq "(^|[^0-9])${uid}([^0-9]|$)" <<< "$list"
}

get_blacklist() {
    adb shell cmd netpolicy list restrict-background-blacklist 2>&1 | tr -d '\r'
}

get_whitelist() {
    adb shell cmd netpolicy list restrict-background-whitelist 2>&1 | tr -d '\r'
}

load_protected_uids() {
    local category pkg app policy uid
    while IFS=$'\t' read -r category pkg app policy; do
        [[ -z "${category:-}" || "$category" == \#* || "$policy" != "keep" ]] && continue
        uid="$(get_uid "$pkg")"
        [[ -n "$uid" ]] && PROTECTED_UIDS["$uid"]="$pkg"
    done < "$CATALOG_FILE"
}

status_catalog() {
    local category pkg app policy uid state
    local blacklist whitelist
    blacklist="$(get_blacklist)" || die "Could not read the NetPolicy blacklist."
    whitelist="$(get_whitelist)" || die "Could not read the NetPolicy allowlist."
    echo "Global Data Saver: $(adb shell cmd netpolicy get restrict-background 2>&1 | tr -d '\r')"
    echo "Per-app background metered-data policy:"
    while IFS=$'\t' read -r category pkg app policy; do
        [[ -z "${category:-}" || "$category" == \#* ]] && continue
        uid="$(get_uid "$pkg")"
        [[ -z "$uid" ]] && continue
        if [[ "$policy" == "keep" || -n "${PROTECTED_UIDS[$uid]:-}" ]]; then
            state="PROTECTED"
        elif uid_listed "$whitelist" "$uid"; then
            state="USER_ALLOWLISTED"
        elif uid_listed "$blacklist" "$uid"; then
            state="BACKGROUND_METERED_BLOCKED"
        else
            state="NOT_RESTRICTED"
        fi
        printf '%-30s UID=%-8s %s\n' "$pkg" "$uid" "$state"
    done < "$CATALOG_FILE"
}

apply_catalog() {
    mkdir -p "$STATE_DIR"
    touch "$STATE_FILE"

    local category pkg app policy uid blacklist whitelist
    local added=0 already=0 skipped=0 failed=0
    declare -A PROCESSED_UIDS=()
    declare -A PROTECTED_UIDS=()
    declare -A VERIFY_UIDS=()

    load_protected_uids
    blacklist="$(get_blacklist)" || die "Could not read the NetPolicy blacklist."
    whitelist="$(get_whitelist)" || die "Could not read the NetPolicy allowlist."

    echo "Global Data Saver is unchanged:"
    adb shell cmd netpolicy get restrict-background 2>&1 | tr -d '\r'

    while IFS=$'\t' read -r category pkg app policy; do
        [[ -z "${category:-}" || "$category" == \#* || "$policy" != "restrict" ]] && continue
        uid="$(get_uid "$pkg")"
        if [[ -z "$uid" ]]; then
            continue
        fi
        if [[ -n "${PROTECTED_UIDS[$uid]:-}" ]]; then
            echo "[KEEP] $pkg shares UID $uid with protected package ${PROTECTED_UIDS[$uid]}"
            skipped=$((skipped + 1))
            continue
        fi
        if uid_listed "$whitelist" "$uid"; then
            echo "[KEEP] $pkg UID $uid is explicitly allowlisted by the user"
            skipped=$((skipped + 1))
            continue
        fi
        if [[ -n "${PROCESSED_UIDS[$uid]:-}" ]]; then
            echo "[SHARED UID] $pkg uses UID $uid already handled for ${PROCESSED_UIDS[$uid]}"
            continue
        fi
        PROCESSED_UIDS["$uid"]="$pkg"
        VERIFY_UIDS["$uid"]="$pkg"

        if uid_listed "$blacklist" "$uid"; then
            echo "[ALREADY] $pkg UID $uid is already blacklisted"
            already=$((already + 1))
            continue
        fi

        if adb shell cmd netpolicy add restrict-background-blacklist "$uid" >/dev/null 2>&1; then
            echo "[ADD] $pkg UID $uid"
            printf '%s\n' "$uid" >> "$STATE_FILE"
            added=$((added + 1))
        else
            echo "[FAIL] $pkg UID $uid: NetPolicy rejected the change" >&2
            failed=$((failed + 1))
        fi
    done < "$CATALOG_FILE"

    blacklist="$(get_blacklist)" || die "Could not verify the NetPolicy blacklist."
    local verified=0
    for uid in "${!VERIFY_UIDS[@]}"; do
        if uid_listed "$blacklist" "$uid"; then
            verified=$((verified + 1))
        else
            echo "[UNVERIFIED] ${VERIFY_UIDS[$uid]} UID $uid is absent from the blacklist" >&2
            failed=$((failed + 1))
        fi
    done

    echo
    echo "Installed target UIDs verified: $verified"
    echo "Newly added UIDs: $added"
    echo "Already restricted UIDs: $already"
    echo "Skipped protected or user-allowlisted packages: $skipped"
    echo "Failures: $failed"
    echo "Global Data Saver was not changed."
    echo "State file for this script: $STATE_FILE"
    (( failed == 0 ))
}

revert_catalog() {
    [[ -f "$STATE_FILE" ]] || {
        echo "No UID changes recorded by this script."
        return 0
    }

    local blacklist uid failed=0 removed=0
    local remaining
    remaining="$(mktemp)"
    blacklist="$(get_blacklist)" || die "Could not read the NetPolicy blacklist."

    while IFS= read -r uid; do
        [[ "$uid" =~ ^[0-9]+$ ]] || continue
        if ! uid_listed "$blacklist" "$uid"; then
            echo "[ALREADY CLEAR] UID $uid"
            continue
        fi
        if adb shell cmd netpolicy remove restrict-background-blacklist "$uid" >/dev/null 2>&1; then
            blacklist="$(get_blacklist)" || die "Could not verify the NetPolicy blacklist."
            if uid_listed "$blacklist" "$uid"; then
                echo "[FAIL] UID $uid remains blacklisted" >&2
                printf '%s\n' "$uid" >> "$remaining"
                failed=$((failed + 1))
            else
                echo "[REMOVED] UID $uid"
                removed=$((removed + 1))
            fi
        else
            echo "[FAIL] Could not remove UID $uid" >&2
            printf '%s\n' "$uid" >> "$remaining"
            failed=$((failed + 1))
        fi
    done < "$STATE_FILE"

    if [[ -s "$remaining" ]]; then
        mv "$remaining" "$STATE_FILE"
    else
        rm -f "$remaining" "$STATE_FILE"
    fi
    echo "Removed UID policies: $removed"
    echo "Failures: $failed"
    (( failed == 0 ))
}

check_adb
case "$ACTION" in
    apply)
        load_catalog
        declare -A PROTECTED_UIDS=()
        apply_catalog
        ;;
    status)
        load_catalog
        declare -A PROTECTED_UIDS=()
        load_protected_uids
        status_catalog
        ;;
    revert)
        revert_catalog
        ;;
    *)
        echo "Usage: $0 {apply|status|revert}" >&2
        exit 2
        ;;
esac

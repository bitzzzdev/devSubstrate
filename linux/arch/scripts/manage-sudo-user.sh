#!/usr/bin/env bash
#
# manage-sudo-user.sh: Creates or deletes a sudo user with wheel group privileges on Arch Linux.
#
# Usage:
#   sudo ./manage-sudo-user.sh create <username>  # Creates user, sets password, adds to wheel
#   sudo ./manage-sudo-user.sh remove <username>  # Removes user and deletes home directory
#   ./manage-sudo-user.sh status <username>       # Checks user existence and group membership
#

set -euo pipefail

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This operation requires root privileges. Run with sudo." >&2
        exit 1
    fi
}

status_user() {
    local user="$1"
    if id "$user" >/dev/null 2>&1; then
        echo "User '$user' exists:"
        id "$user"
    else
        echo "User '$user' does not exist."
    fi
}

create_user() {
    check_root
    local user="$1"

    if id "$user" >/dev/null 2>&1; then
        echo "User '$user' already exists."
        exit 0
    fi

    read -rsp "Enter password for $user: " password
    echo ""
    read -rsp "Confirm password for $user: " password_confirm
    echo ""

    if [[ "$password" != "$password_confirm" ]]; then
        echo "Error: Passwords do not match." >&2
        exit 1
    fi

    useradd -m -G wheel -s /bin/bash "$user"
    echo "$user:$password" | chpasswd

    # Enable wheel in sudoers if commented
    if grep -q "^# %wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
        sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
        echo "Enabled wheel group privilege in /etc/sudoers."
    fi

    echo "User '$user' created successfully with sudo access."
}

remove_user() {
    check_root
    local user="$1"

    if ! id "$user" >/dev/null 2>&1; then
        echo "User '$user' does not exist. Nothing to revert."
        exit 0
    fi

    read -rp "Are you sure you want to delete user '$user' and remove /home/$user? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        userdel -r "$user"
        echo "User '$user' and home directory deleted."
    else
        echo "Aborted."
    fi
}

action="${1:-}"
username="${2:-}"

if [[ -z "$action" ]] || [[ -z "$username" ]]; then
    echo "Usage: $0 {create|remove|status} <username>"
    exit 1
fi

case "$action" in
    create)
        create_user "$username"
        ;;
    remove)
        remove_user "$username"
        ;;
    status)
        status_user "$username"
        ;;
    *)
        echo "Usage: $0 {create|remove|status} <username>"
        exit 1
        ;;
esac

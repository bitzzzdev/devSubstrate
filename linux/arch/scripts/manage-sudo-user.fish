#!/usr/bin/env fish
#
# manage-sudo-user.fish: Fish shell script to create or delete a sudo user on Arch Linux.
#
# Usage:
#   sudo ./manage-sudo-user.fish create <username>  # Creates user and configures sudo
#   sudo ./manage-sudo-user.fish remove <username>  # Removes user and home directory
#   ./manage-sudo-user.fish status <username>       # Checks user existence and groups
#

function check_root
    if test (id -u) -ne 0
        echo "Error: This operation requires root privileges. Run with sudo." >&2
        return 1
    end
    return 0
end

function status_user -a user
    if id "$user" >/dev/null 2>&1
        echo "User '$user' exists:"
        id "$user"
    else
        echo "User '$user' does not exist."
    end
end

function create_user -a user
    if not check_root
        return 1
    end

    if id "$user" >/dev/null 2>&1
        echo "User '$user' already exists."
        return 0
    end

    read -sP "Enter password for $user: " password
    echo ""
    read -sP "Confirm password for $user: " password_confirm
    echo ""

    if test "$password" != "$password_confirm"
        echo "Error: Passwords do not match." >&2
        return 1
    end

    useradd -m -G wheel -s /bin/bash "$user"
    echo "$user:$password" | chpasswd

    if grep -q "^# %wheel ALL=(ALL:ALL) ALL" /etc/sudoers
        sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
        echo "Enabled wheel group privilege in /etc/sudoers."
    end

    echo "User '$user' created successfully with sudo access."
end

function remove_user -a user
    if not check_root
        return 1
    end

    if not id "$user" >/dev/null 2>&1
        echo "User '$user' does not exist. Nothing to revert."
        return 0
    end

    read -P "Are you sure you want to delete user '$user' and remove /home/$user? [y/N]: " confirm
    if string match -ri '^[yY]$' "$confirm"
        userdel -r "$user"
        echo "User '$user' and home directory deleted."
    else
        echo "Aborted."
    end
end

set -l action $argv[1]
set -l username $argv[2]

if test -z "$action" -o -z "$username"
    echo "Usage: "(status filename)" {create|remove|status} <username>"
    exit 1
end

switch "$action"
    case "create"
        create_user "$username"
    case "remove"
        remove_user "$username"
    case "status"
        status_user "$username"
    case '*'
        echo "Usage: "(status filename)" {create|remove|status} <username>"
        exit 1
end

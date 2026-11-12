#!/usr/bin/env fish
# Fish wrapper for manage-shopping-traffic.sh.
# The Bash implementation is the single source of truth.
set -l script_dir (dirname (status filename))
set -l script_path "$script_dir/manage-shopping-traffic.sh"
if not test -f "$script_path"
    echo "Error: $script_path not found." >&2
    exit 1
end
exec bash "$script_path" $argv

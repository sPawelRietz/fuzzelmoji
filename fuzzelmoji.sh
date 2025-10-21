#!/bin/sh

# Dependencies: curl, fuzzel, wl-copy

# Exit on error
set -e

# --- Configuration ---
EMOJI_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
EMOJI_CACHE_FILE="$EMOJI_CACHE_DIR/emoji.json"
EMOJI_URL="https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json"

# --- Functions ---

# Check for required commands
check_dependencies() {
    for cmd in curl fuzzel wl-copy jq notify-send; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: Required command '$cmd' is not installed." >&2
            exit 1
        fi
    done
}

# Download or update the emoji data file
update_emoji_cache() {
    if [ ! -f "$EMOJI_CACHE_FILE" ] || [ "$(find "$EMOJI_CACHE_FILE" -mtime +7)" ]; then
        echo "Downloading emoji data..."
        mkdir -p "$EMOJI_CACHE_DIR"
        curl -sL "$EMOJI_URL" -o "$EMOJI_CACHE_FILE"
    fi
}

# --- Main Script ---

check_dependencies
update_emoji_cache

# Select an emoji using fuzzel
# The user sees "emoji description"
# The output is just the emoji
selected=$(jq -r '.[] | select(.emoji != null) | "\(.emoji) \(.description)"' "$EMOJI_CACHE_FILE" | \
           fuzzel --dmenu --log-no-syslog | \
           sed 's/ .*//')

# If an emoji was selected, copy it to the clipboard
if [ -n "$selected" ]; then
    echo -n "$selected" | wl-copy
    notify-send "Emoji Copied" "'$selected' has been copied to your clipboard."
fi

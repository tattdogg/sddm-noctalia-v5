#!/bin/bash

THEME_DIR="/usr/share/sddm/themes/sddm-noctalia-v5"
TEMPLATE_FILE="$THEME_DIR/template.conf"
THEME_FILE="$THEME_DIR/theme.conf"

WALLPAPER_PATH=$(noctalia msg wallpaper-get)

if [[ -z "$WALLPAPER_PATH" || ! -f "$WALLPAPER_PATH" ]]; then
    exit 1
fi

update_background() {
    local file_path="$1"
    local wp_path="$2"

    [[ ! -f "$file_path" ]] && touch "$file_path"

    if grep -q "^background=" "$file_path"; then
        sed -i "s|^background=.*|background=$wp_path|" "$file_path"
    fi
}

update_background "$TEMPLATE_FILE" "$WALLPAPER_PATH"
update_background "$THEME_FILE" "$WALLPAPER_PATH"

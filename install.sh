#!/usr/bin/env bash

#  install.sh — Noctalia v5 SDDM Theme Installer
#  Repo  : https://github.com/tattdogg/sddm-noctalia-v5
#  Usage : sudo ./install.sh [--noctalia-sync]

set -euo pipefail

# ── Constants ─────────────────────────────────────────────────────────────────
THEME_NAME="sddm-noctalia-v5"
REPO="tattdogg/sddm-noctalia-v5"
BRANCH="noctalia"
ARCHIVE_URL="https://github.com/${REPO}/tarball/main"
INSTALL_DIR="/usr/share/sddm/themes/${THEME_NAME}"
SDDM_CONF="/etc/sddm.conf"
SDDM_CONF_D="/etc/sddm.conf.d/theme.conf"

# ── Arguments parsing ─────────────────────────────────────────────────────────
OPT_SYNC=0

for arg in "$@"; do
    case "$arg" in
        --noctalia-sync) OPT_SYNC=1 ;;
    esac
done

# ── Root check ────────────────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]] || [[ "$OPT_SYNC" -eq 1 && -z "${SUDO_USER:-}" ]]; then
    echo "Error: This script must be run via 'sudo' from a regular user account." >&2
    exit 1
fi

# ── Dependency check ──────────────────────────────────────────────────────────
DOWNLOADER=""
if command -v curl &>/dev/null; then
    DOWNLOADER="curl"
elif command -v wget &>/dev/null; then
    DOWNLOADER="wget"
else
    echo "Error: Neither curl nor wget found. Please install one and retry." >&2
    exit 1
fi

# ── Clean target directory ────────────────────────────────────────────────────
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
fi
mkdir -p "$INSTALL_DIR"

# ── Download and extract theme from the branch tarball ────────────────────────
echo "Downloading and extracting the theme..."
if [[ "$DOWNLOADER" == "curl" ]]; then
    curl -fsSL "$ARCHIVE_URL" | tar -xzf - -C "$INSTALL_DIR" --strip-components=1
else
    wget -qO- "$ARCHIVE_URL" | tar -xzf - -C "$INSTALL_DIR" --strip-components=1
fi

# ── SDDM configuration ────────────────────────────────────────────────────────
configure_sddm() {
    local conf_file="$1"
    mkdir -p "$(dirname "$conf_file")"

    if [[ -f "$conf_file" ]]; then
        if grep -q '^\[Theme\]' "$conf_file"; then
            if grep -q '^Current=' "$conf_file"; then
                sed -i "s|^Current=.*|Current=${THEME_NAME}|" "$conf_file"
            else
                sed -i '/^\[Theme\]/a Current='"${THEME_NAME}" "$conf_file"
            fi
        else
            printf '\n[Theme]\nCurrent=%s\n' "${THEME_NAME}" >> "$conf_file"
        fi
    else
        printf '[Theme]\nCurrent=%s\n' "${THEME_NAME}" > "$conf_file"
    fi
}

if [[ -d "/etc/sddm.conf.d" ]]; then
    configure_sddm "$SDDM_CONF_D"
else
    configure_sddm "$SDDM_CONF"
fi

# ── Noctalia Sync ─────────────────────────────────────────────────────────────
configure_noctalia_sync() {
    echo "Setting up Noctalia Sync..."

    # Getting the real user and their home directory
    local real_user="$SUDO_USER"
    local user_home=$(getent passwd "$real_user" | cut -d: -f6)
    local change_wallpaper_sh="${INSTALL_DIR}/change_wallpaper.sh"

    chown -R "$real_user:$real_user" "$INSTALL_DIR"
    chmod 744 "${change_wallpaper_sh}"

    # Create Noctalia configuration file
    local theme_config="${user_home}/.config/noctalia/${THEME_NAME}.toml"
    sudo -u "$real_user" mkdir -p "$(dirname "$theme_config")"

    sudo -u "$real_user" tee "$theme_config" > /dev/null << 'EOF'
[theme.templates.user.sddm-noctalia-v5]
input_path  = "/usr/share/sddm/themes/sddm-noctalia-v5/template.conf"
output_path = "/usr/share/sddm/themes/sddm-noctalia-v5/theme.conf"

[hooks]
wallpaper_changed = "/usr/share/sddm/themes/sddm-noctalia-v5/change_wallpaper.sh"
EOF


	# update templates + wallpaper
    local user_pid=$(pgrep -u "$real_user" -x noctalia | head -n1)
    local env_vars=""

    [[ -n "$user_pid" && -r "/proc/${user_pid}/environ" ]] && env_vars=$(tr '\0' '\n' < "/proc/${user_pid}/environ" | grep -E '^(XDG_RUNTIME_DIR|WAYLAND_DISPLAY)=')

    if [[ -n "$env_vars" ]]; then
        sudo -u "$real_user" env $env_vars noctalia msg templates-apply >/dev/null || true
        sudo -u "$real_user" env $env_vars ${change_wallpaper_sh} >/dev/null
    fi

}

if [[ "$OPT_SYNC" -eq 1 ]]; then
    configure_noctalia_sync
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo "Noctalia v5 SDDM theme installed successfully!"

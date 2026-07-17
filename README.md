# Noctalia v5 SDDM Theme

Noctalia SDDM is a cozy, elegant login theme for **SDDM (Simple Desktop Display Manager)**, designed to complement the **Noctalia v5** experience.

![Noctalia SDDM Sync Preview](Assets/preview-sync.png)

## Features

- **Noctalia Sync** – Syncs the theme with Noctalia colors and wallpaper.
- **Responsive Scaling** – Automatically adapts to 1080p, 1440p, and 4K resolutions.

- **Smart Avatar Handling** – Automatically detects user profile pictures or gracefully falls back to defaults.
- **Session Management** – Built-in support for switching desktop sessions (Wayland/X11).

- **Customizable Configuration** – easy tweaks via `theme.conf`.

## Installation

### 1. Clone the repository

```sh
cd /usr/share/sddm/themes/
sudo git clone --depth=1 https://github.com/tattdogg/sddm-noctalia-v5.git
```

### 2. Configure SDDM

Edit your SDDM configuration file to use the new theme:

```sh
sudo nano /etc/sddm.conf
```

Add or modify the `[Theme]` section:

```ini
[Theme]
Current=sddm-noctalia-v5
```

### 3. Sync (Optional)

Make config and wallpaper files writable by Noctalia
```sh
sudo chmod 644 /usr/share/sddm/themes/sddm-noctalia-v5/*.conf
sudo chmod 644 /usr/share/sddm/themes/sddm-noctalia-v5/Assets/background.png
```

Add "On wallpaper changed" hook in the Noctalia settings 
```sh
cp "$NOCTALIA_WALLPAPER_PATH" /usr/share/sddm/themes/sddm-noctalia-v5/Assets/background.png
```

Append to `~/.config/noctalia/user-templates.toml` (ensure file exists):
```toml
[theme.templates.user.sddm-noctalia]
input_path = "/usr/share/sddm/themes/sddm-noctalia-v5/template.conf"
output_path = "/usr/share/sddm/themes/sddm-noctalia-v5/theme.conf"
```

Change the wallpaper and theme in the Noctalia settings at least once to sync.

## Manual Configuration

You can customize colors, background, and blur settings in `theme.conf`:

```ini
[General]
background=Assets/background.png
blurRadius=0
radius=20
```

## Experimental

install using script (uses tarball link for now):

### without Noctalia sync
```sh
curl -fsSL https://raw.githubusercontent.com/tattdogg/sddm-noctalia-v5/main/install.sh | sudo bash
```

### with Noctalia sync
```sh
curl -fsSL https://raw.githubusercontent.com/tattdogg/sddm-noctalia-v5/main/install.sh | sudo bash -s -- --noctalia-sync
```

## TODO
- create automated installation/uninstallation script
- capslock,numlock and keyboard state indicators
- animations
- Some icons for Sessions

## Preview

You can test the theme without logging out by running the sddm-greeter in test mode:

```sh
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-noctalia-v5
```

## Troubleshooting

*   **Error:** `module is not installed`
    *   **Solution:** Ensure that the `qt6-5compat` and `qt6-declarative` packages are installed on your system.

## Credits

- All credits to mahaveergurjar for the original theme
- Designed for **Noctalia v5**
# Customization

## Colors

Edit:

```text
~/.config/hypr/palette.conf
```

Regenerate all theme fragments:

```bash
~/.config/hypr/scripts/sync-theme.sh
```

The generator updates Hyprland, Waybar, Rofi, Mako and Hyprlock from one
palette.

## Local Hyprland overrides

Create `~/.config/hypr/user/local.lua` or copy the supplied monitor example.
Local override files are excluded from Git.

## Wallpapers

Installed wallpapers live in:

```text
~/.local/share/fog-and-ember/wallpapers
```

Place favorites in its `favorite/` subdirectory.

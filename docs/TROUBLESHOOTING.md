# Troubleshooting

Run the built-in diagnostics:

```bash
./scripts/doctor.sh
```

## Hyprland does not start

Check the version:

```bash
Hyprland --version
```

This repository uses the Lua configuration introduced in current Hyprland and
requires version `0.56.0` or newer.

Inspect the session log from a TTY or another desktop:

```bash
journalctl --user -b --no-pager | grep -iE 'hypr|waybar|portal'
```

## Waybar

```bash
systemctl --user status waybar-fog-and-ember.service
journalctl --user -u waybar-fog-and-ember.service -b --no-pager
```

## Theme regeneration

```bash
~/.config/hypr/scripts/sync-theme.sh
```

## Session helper logs

```bash
ls -la "${XDG_RUNTIME_DIR:-/tmp}/hypr-fog-and-ember"
```

## Restore previous configuration

Use the backup path printed by the installer:

```bash
./scripts/restore.sh ~/.local/state/fog-and-ember/backups/YYYY-MM-DD_HH-MM-SS
```

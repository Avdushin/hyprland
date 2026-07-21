#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/scripts/lib.sh"

install_packages=true
run_doctor=true
dry_run=false

usage() {
  cat <<'EOF'
Fog & Ember installer

Usage:
  ./install.sh [options]

Options:
  --dotfiles-only  Do not install distribution packages
  --no-doctor      Skip post-install diagnostics
  --dry-run        Print package-manager actions and make no changes
  -h, --help       Show this help
EOF
}

while (($#)); do
  case "$1" in
    --dotfiles-only) install_packages=false ;;
    --no-doctor) run_doctor=false ;;
    --dry-run) dry_run=true ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

[[ $EUID -ne 0 ]] || die 'Run this installer as a regular user, not root'

family=$(detect_family)
if $install_packages && [[ $family == unsupported ]]; then
  die 'Automatic package installation supports Arch Linux, EndeavourOS, Manjaro and Fedora. Use --dotfiles-only on other distributions.'
fi

if $dry_run; then
  note "Detected package family: $family"
  if $install_packages; then
    FOG_EMBER_DRY_RUN=1 "$script_dir/scripts/install-packages.sh" "$family"
  else
    note 'Package installation disabled'
  fi
  note 'Dry run completed; no files were changed'
  exit 0
fi

if $install_packages; then
  command -v sudo >/dev/null 2>&1 || die 'sudo is required to install packages'
  "$script_dir/scripts/install-packages.sh" "$family"

  note 'Enabling desktop services'
  sudo systemctl enable --now NetworkManager.service >/dev/null 2>&1 \
    || warn 'Could not enable NetworkManager automatically'
  sudo systemctl enable --now bluetooth.service >/dev/null 2>&1 \
    || warn 'Could not enable Bluetooth automatically'
fi

note 'Creating a backup'
backup=$("$script_dir/scripts/backup.sh")
printf 'Backup: %s\n' "$backup"

note 'Installing dotfiles'
rsync -a -- "$script_dir/dotfiles/" "$HOME/"

share_dir="$HOME/.local/share/fog-and-ember"
mkdir -p "$share_dir"
rsync -a --delete -- "$script_dir/assets/wallpapers/" "$share_dir/wallpapers/"

mkdir -p "$HOME/Images/Screenshots"
if command -v xdg-user-dirs-update >/dev/null 2>&1; then
  xdg-user-dirs-update >/dev/null 2>&1 || true
fi

chmod +x \
  "$HOME/.config/hypr/scripts/"*.sh \
  "$HOME/.config/waybar/scripts/"*.sh \
  "$HOME/.config/waybar/scripts/"*.py

"$HOME/.config/hypr/scripts/sync-theme.sh" --no-reload
"$script_dir/scripts/apply-appearance.sh"

note 'Activating user services'
systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user enable waybar-fog-and-ember.service >/dev/null 2>&1 \
  || warn 'Waybar service will be started by Hyprland session-start.sh'

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hyprctl reload >/dev/null 2>&1 || warn 'Hyprland reload failed; log in again'
  "$HOME/.config/hypr/scripts/session-start.sh" || true
fi

if $run_doctor; then
  "$script_dir/scripts/doctor.sh"
fi

cat <<EOF

Fog & Ember is installed.

Backup:
  $backup

Next:
  1. Log out.
  2. Select the Hyprland session in your display manager, or start Hyprland
     from a TTY.
  3. For custom monitor placement, copy:
       ~/.config/hypr/monitors/local.lua.example
     to:
       ~/.config/hypr/monitors/local.lua

Restore:
  $script_dir/scripts/restore.sh "$backup"
EOF

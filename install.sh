#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/scripts/lib.sh"

nvim_submodule_rel="dotfiles/.config/nvim"
nvim_submodule="$script_dir/$nvim_submodule_rel"

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

preserve_gitconfig_local() {
  local managed="$HOME/.gitconfig"
  local private="$HOME/.gitconfig.local"
  local marker="# Managed by Avdushin/hyprland."
  local entries=""

  [[ -f "$managed" ]] || return
  [[ ! -e "$private" ]] || return
  grep -Fqx "$marker" "$managed" 2>/dev/null && return

  if ! command -v git >/dev/null 2>&1; then
    warn "git is unavailable; the existing ~/.gitconfig will still be backed up, but personal values cannot be migrated automatically"
    return
  fi

  if ! git config --file "$managed" --list >/dev/null 2>&1; then
    warn "Existing ~/.gitconfig could not be parsed; it will still be preserved in the installer backup"
    return
  fi

  entries="$(
    git config --file "$managed" \
      --get-regexp '^(user\.|credential\.)' \
      2>/dev/null || true
  )"

  [[ -n "$entries" ]] || return

  : >"$private"

  while IFS=' ' read -r key value; do
    [[ -n "$key" ]] || continue
    git config --file "$private" --add "$key" "${value:-}"
  done <<<"$entries"

  note "Preserved personal Git identity/credential settings in ~/.gitconfig.local"
}


prepare_nvim_submodule() {
  command -v git >/dev/null 2>&1 ||
    die 'git is required to initialize the Neovim submodule'

  [[ -d "$script_dir/.git" || -f "$script_dir/.git" ]] ||
    die 'Fog & Ember must be installed from a Git checkout so the pinned Neovim submodule can be resolved'

  note 'Preparing pinned Neovim configuration'

  git -C "$script_dir" submodule sync -- "$nvim_submodule_rel"
  git -C "$script_dir" submodule update \
    --init \
    --recursive \
    --depth 1 \
    -- "$nvim_submodule_rel"

  local expected actual dirty
  expected="$(git -C "$script_dir" rev-parse "HEAD:$nvim_submodule_rel")"
  actual="$(git -C "$nvim_submodule" rev-parse HEAD)"
  dirty="$(git -C "$nvim_submodule" status --porcelain --untracked-files=all)"

  [[ "$actual" == "$expected" ]] ||
    die "Neovim submodule mismatch: expected $expected, found $actual"

  [[ -z "$dirty" ]] ||
    die 'Neovim submodule has local changes. Commit/stash them in nvchad-rc or clean the submodule before installing.'
}

family=$(detect_family)
if $install_packages && [[ $family == unsupported ]]; then
  die 'Automatic package installation supports Arch Linux, EndeavourOS, Manjaro and Fedora. Use --dotfiles-only on other distributions.'
fi

if $dry_run; then
  note "Detected package family: $family"
  if $install_packages; then
    FOG_EMBER_DRY_RUN=1 "$script_dir/scripts/install-packages.sh" "$family"
    FOG_EMBER_DRY_RUN=1 "$script_dir/scripts/install-git-tools.sh"
  else
    note 'Package installation disabled'
  fi
  note "Would initialize pinned Neovim submodule: $nvim_submodule_rel"
  note 'Dry run completed; no files were changed'
  exit 0
fi

if $install_packages; then
  command -v sudo >/dev/null 2>&1 || die 'sudo is required to install packages'
  "$script_dir/scripts/install-packages.sh" "$family"
  "$script_dir/scripts/install-git-tools.sh"

  note 'Enabling desktop services'
  sudo systemctl enable --now NetworkManager.service >/dev/null 2>&1 \
    || warn 'Could not enable NetworkManager automatically'
  sudo systemctl enable --now bluetooth.service >/dev/null 2>&1 \
    || warn 'Could not enable Bluetooth automatically'
fi

prepare_nvim_submodule
preserve_gitconfig_local

note 'Creating a backup'
backup=$("$script_dir/scripts/backup.sh")
printf 'Backup: %s\n' "$backup"

note 'Replacing Neovim configuration from the pinned submodule'
rm -rf -- "$HOME/.config/nvim"

note 'Installing dotfiles'
rsync -a \
  --exclude='.git' \
  -- "$script_dir/dotfiles/" "$HOME/"

# Remove files used by older static Waybar builds. The current profile is
# rendered into XDG_RUNTIME_DIR from config.template.json.
rm -f -- "$HOME/.config/waybar/config.jsonc"

find "$HOME/.config/waybar/scripts" \
  -type d \
  -name '__pycache__' \
  -prune \
  -exec rm -rf -- {} + \
  2>/dev/null || true

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

#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

family=${1:-$(detect_family)}
dry_run=${FOG_EMBER_DRY_RUN:-0}

run() {
  printf '  +'
  printf ' %q' "$@"
  printf '\n'
  [[ $dry_run == 1 ]] || "$@"
}

install_arch() {
  [[ $dry_run == 1 ]] || command -v pacman >/dev/null 2>&1 || die 'pacman not found'
  mapfile -t packages < <(read_package_file "$repo_root/packages/arch.txt")
  note "Installing Arch-family packages (${#packages[@]})"
  run sudo pacman -Syu --needed -- "${packages[@]}"

  # Optional packages are installed only when present in enabled repositories.
  while IFS= read -r package; do
    if [[ $dry_run == 1 ]] || pacman -Si "$package" >/dev/null 2>&1; then
      run sudo pacman -S --needed -- "$package"
    else
      warn "Optional package is unavailable: $package"
    fi
  done < <(read_package_file "$repo_root/packages/optional.txt")
}

fedora_dnf() {
  if command -v dnf5 >/dev/null 2>&1; then
    printf 'dnf5\n'
  elif command -v dnf >/dev/null 2>&1; then
    printf 'dnf\n'
  elif [[ $dry_run == 1 ]]; then
    printf 'dnf\n'
  else
    die 'dnf/dnf5 not found'
  fi
}

fedora_has_package() {
  local dnf=$1 package=$2
  "$dnf" -q repoquery --available "$package" >/dev/null 2>&1 ||
    "$dnf" -q list --available "$package" >/dev/null 2>&1
}

install_fedora() {
  local dnf
  dnf=$(fedora_dnf)

  note 'Enabling the upstream-recommended lionheartp/Hyprland COPR'
  if ! "$dnf" copr --help >/dev/null 2>&1; then
    run sudo "$dnf" install -y dnf-plugins-core || run sudo "$dnf" install -y dnf5-plugins
  fi
  run sudo "$dnf" copr enable -y lionheartp/Hyprland
  run sudo "$dnf" makecache

  mapfile -t requested < <(read_package_file "$repo_root/packages/fedora.txt")
  available=()
  missing=()
  for package in "${requested[@]}"; do
    if [[ $dry_run == 1 ]] || fedora_has_package "$dnf" "$package"; then
      available+=("$package")
    else
      missing+=("$package")
    fi
  done

  # Fedora 42 used rofi-wayland; newer releases provide Wayland support in rofi.
  if ! printf '%s\n' "${available[@]}" | grep -qx rofi && fedora_has_package "$dnf" rofi-wayland; then
    available+=(rofi-wayland)
  fi

  ((${#available[@]})) || die 'No Fedora packages could be resolved'
  note "Installing Fedora packages (${#available[@]})"
  run sudo "$dnf" install -y "${available[@]}"

  for package in "${missing[@]}"; do
    warn "Package unavailable on this Fedora release: $package"
  done

  while IFS= read -r package; do
    if [[ $dry_run == 1 ]] || fedora_has_package "$dnf" "$package"; then
      run sudo "$dnf" install -y "$package"
    else
      warn "Optional package is unavailable: $package"
    fi
  done < <(read_package_file "$repo_root/packages/optional.txt")
}

case "$family" in
  arch) install_arch ;;
  fedora) install_fedora ;;
  *) die 'Supported distributions: Arch Linux, EndeavourOS, Manjaro and Fedora' ;;
esac

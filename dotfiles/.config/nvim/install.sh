#!/usr/bin/env bash

set -euo pipefail

REPO="https://github.com/Avdushin/nvchad-rc.git"
NVIM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
STAMP="$(date +%Y%m%d-%H%M%S)"

info() {
  printf '\n\033[1;34m==>\033[0m %s\n' "$1"
}

die() {
  printf '\n\033[1;31mError:\033[0m %s\n' "$1" >&2
  exit 1
}

install_linux_dependencies() {
  if command -v pacman >/dev/null 2>&1; then
    info "Installing dependencies with pacman"

    sudo pacman -S --needed --noconfirm \
      git \
      neovim \
      ripgrep \
      nodejs \
      npm \
      imagemagick \
      curl \
      unzip \
      tar \
      gzip \
      wl-clipboard

  elif command -v apt-get >/dev/null 2>&1; then
    info "Installing dependencies with apt"

    sudo apt-get update

    sudo apt-get install -y \
      git \
      neovim \
      ripgrep \
      nodejs \
      npm \
      imagemagick \
      curl \
      unzip \
      tar \
      gzip \
      wl-clipboard

  elif command -v dnf >/dev/null 2>&1; then
    info "Installing dependencies with dnf"

    sudo dnf install -y \
      git \
      neovim \
      ripgrep \
      nodejs \
      npm \
      ImageMagick \
      curl \
      unzip \
      tar \
      gzip \
      wl-clipboard

  else
    die "Unsupported Linux package manager. Install dependencies manually and follow README.md."
  fi
}

install_macos_dependencies() {
  if ! command -v brew >/dev/null 2>&1; then
    die "Homebrew is required on macOS: https://brew.sh"
  fi

  info "Installing dependencies with Homebrew"

  brew install \
    git \
    neovim \
    ripgrep \
    node \
    imagemagick

  # Optional Nerd Font.
  if ! brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
    brew install --cask font-jetbrains-mono-nerd-font || true
  fi
}

install_dependencies() {
  case "$(uname -s)" in
    Linux)
      install_linux_dependencies
      ;;

    Darwin)
      install_macos_dependencies
      ;;

    *)
      die "Automatic installer supports Linux and macOS only. See README.md for manual installation."
      ;;
  esac
}

backup_config() {
  if [ -e "$NVIM_DIR" ]; then
    local backup="${NVIM_DIR}.bak-${STAMP}"

    info "Backing up existing Neovim config"
    mv "$NVIM_DIR" "$backup"

    echo "Backup: $backup"
  fi
}

clone_config() {
  info "Cloning NvChad config"

  mkdir -p "$(dirname "$NVIM_DIR")"
  git clone "$REPO" "$NVIM_DIR"
}

install_plugins() {
  info "Installing Neovim plugins"

  nvim --headless "+Lazy! sync" +qa
}

install_lsp() {
  info "Installing LSP servers"

  nvim --headless "+MasonToolsInstallSync" +qa
}

main() {
  install_dependencies
  backup_config
  clone_config
  install_plugins
  install_lsp

  printf '\n\033[1;32m✓ Installation complete\033[0m\n\n'
  echo "Run:"
  echo
  echo "  nvim"
  echo
}

main "$@"

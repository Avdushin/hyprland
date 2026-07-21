#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

note() { printf '\n==> %s\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

read_package_file() {
  local file=$1
  [[ -r $file ]] || die "Package manifest not found: $file"
  sed -E 's/[[:space:]]+#.*$//; /^[[:space:]]*(#|$)/d; s/^[[:space:]]+//; s/[[:space:]]+$//' "$file"
}

detect_family() {
  if [[ -n ${FOG_EMBER_DISTRO:-} ]]; then
    printf '%s\n' "$FOG_EMBER_DISTRO"
    return
  fi

  # shellcheck source=/dev/null
  [[ -r /etc/os-release ]] && source /etc/os-release
  case " ${ID:-} ${ID_LIKE:-} " in
    *arch*|*manjaro*|*endeavouros*) printf 'arch\n' ;;
    *fedora*) printf 'fedora\n' ;;
    *)
      if command -v pacman >/dev/null 2>&1; then printf 'arch\n'
      elif command -v dnf5 >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then printf 'fedora\n'
      else printf 'unsupported\n'
      fi
      ;;
  esac
}

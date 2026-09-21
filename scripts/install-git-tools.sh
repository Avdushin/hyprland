#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

dry_run=${FOG_EMBER_DRY_RUN:-0}
local_bin="$HOME/.local/bin"

mkdir -p "$local_bin"
export PATH="$local_bin:$PATH"

case "$(uname -m)" in
  x86_64|amd64)
    rust_arch=x86_64
    diffnav_arch=x86_64
    ;;
  aarch64|arm64)
    rust_arch=aarch64
    diffnav_arch=arm64
    ;;
  *)
    die "Unsupported architecture for Git TUI fallbacks: $(uname -m)"
    ;;
esac

install_release_tool() {
  local binary=$1 repo=$2

  if command -v "$binary" >/dev/null 2>&1; then
    note "$binary is already installed"
    return
  fi

  if [[ $dry_run == 1 ]]; then
    note "Would install $binary from the latest $repo GitHub release if the package manager does not provide it"
    return
  fi

  local release_json tag version asset url digest expected tmp archive executable

  release_json="$(curl -fsSL --retry 3 "https://api.github.com/repos/$repo/releases/latest")"
  tag="$(jq -er '.tag_name' <<<"$release_json")"
  version="${tag#v}"

  case "$binary" in
    delta)
      asset="delta-${version}-${rust_arch}-unknown-linux-gnu.tar.gz"
      ;;
    diffnav)
      asset="diffnav_Linux_${diffnav_arch}.tar.gz"
      ;;
    tuicr)
      asset="tuicr-${version}-${rust_arch}-unknown-linux-gnu.tar.gz"
      ;;
    *)
      die "Unsupported release tool: $binary"
      ;;
  esac

  url="$(
    jq -er --arg asset "$asset"       '.assets[] | select(.name == $asset) | .browser_download_url'       <<<"$release_json"
  )" || die "Release asset not found for $binary: $asset"

  digest="$(
    jq -er --arg asset "$asset"       '.assets[] | select(.name == $asset) | .digest'       <<<"$release_json"
  )" || die "Release digest not found for $binary: $asset"

  [[ $digest == sha256:* ]] || die "Unsupported release digest for $binary: $digest"
  expected="${digest#sha256:}"

  tmp="$(mktemp -d)"
  archive="$tmp/$asset"

  note "Installing $binary $tag from $repo"
  curl -fL --retry 3 "$url" -o "$archive"
  printf '%s  %s\n' "$expected" "$archive" | sha256sum -c - >/dev/null

  mkdir -p "$tmp/extracted"
  tar -xzf "$archive" -C "$tmp/extracted"
  executable="$(find "$tmp/extracted" -type f -name "$binary" -print -quit)"
  [[ -n $executable ]] || die "Could not find $binary in $asset"

  install -m 0755 "$executable" "$local_bin/$binary"
  rm -rf -- "$tmp"
  hash -r

  command -v "$binary" >/dev/null 2>&1 || die "$binary installation verification failed"
}

install_release_tool delta dandavison/delta
install_release_tool diffnav dlvhdr/diffnav
install_release_tool tuicr agavra/tuicr

if [[ $dry_run == 1 ]]; then
  exit 0
fi

for command_name in git ssh gh delta diffnav tuicr; do
  command -v "$command_name" >/dev/null 2>&1 ||     die "Required Git tooling command is missing: $command_name"
done

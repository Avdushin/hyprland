#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &&
  pwd
)"
source "$repo_root/scripts/lib.sh"

submodule_rel="dotfiles/.config/nvim"
submodule_dir="$repo_root/$submodule_rel"

command -v git >/dev/null 2>&1 || die 'git is required'

[[ -d "$repo_root/.git" || -f "$repo_root/.git" ]] ||
  die 'Run this command from a Git checkout of Avdushin/hyprland'

git -C "$repo_root" submodule sync -- "$submodule_rel"
git -C "$repo_root" submodule update --init --recursive -- "$submodule_rel"

dirty="$(git -C "$submodule_dir" status --porcelain --untracked-files=all)"
[[ -z "$dirty" ]] ||
  die 'Neovim submodule has local changes. Commit/stash them in nvchad-rc before updating the pointer.'

before="$(git -C "$submodule_dir" rev-parse HEAD)"

note 'Fetching nvchad-rc/main'
git -C "$submodule_dir" fetch --depth 1 origin main
after="$(git -C "$submodule_dir" rev-parse FETCH_HEAD)"

if [[ "$before" == "$after" ]]; then
  note "Neovim submodule is already current: $before"
  exit 0
fi

git -C "$submodule_dir" checkout --detach "$after"

cat <<EOF

Neovim submodule updated:
  $before
  ->
  $after

Review and commit the pointer in the superproject:

  git diff --submodule=log -- $submodule_rel
  git add $submodule_rel
  git commit -m "chore: update Neovim submodule"
EOF

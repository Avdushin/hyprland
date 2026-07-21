# Distribution support

## Arch Linux / EndeavourOS / Manjaro

Packages are installed with `pacman` from enabled repositories. The installer
does not install or modify GPU drivers, kernels, boot loaders or microcode.

## Fedora

The installer enables the `lionheartp/Hyprland` COPR and resolves available
packages before installation. Fedora package names can differ across releases,
so unavailable optional packages produce warnings rather than aborting the
whole setup.

## Other distributions

The dotfiles are ordinary files and can be installed using:

```bash
./install.sh --dotfiles-only
```

Automatic package installation is intentionally limited to the two package
families above. Adding untested package-manager branches would make the
one-command promise misleading.

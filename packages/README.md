# Package profiles

The installer detects the package family through `/etc/os-release` and the
available package manager.

- `arch.txt`: Arch Linux, EndeavourOS, Manjaro and other pacman-based systems.
- `fedora.txt`: Fedora. The installer enables the `lionheartp/Hyprland` COPR,
  currently referenced by the upstream Hyprland installation page.
- `optional.txt`: quality-of-life features; missing packages never abort the
  installation.

GPU drivers, microcode, kernels, gaming packages and vendor-specific settings
are intentionally outside this repository.

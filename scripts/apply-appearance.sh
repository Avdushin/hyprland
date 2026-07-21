#!/usr/bin/env bash
set -Eeuo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

theme=Adwaita-dark
for candidate in Materia-dark Materia-dark-compact; do
  if [[ -d /usr/share/themes/$candidate || -d "$HOME/.themes/$candidate" ]]; then
    theme=$candidate
    break
  fi
done

for file in "$config_home/gtk-3.0/settings.ini" "$config_home/gtk-4.0/settings.ini"; do
  [[ -f $file ]] || continue
  sed -i -E "s/^gtk-theme-name=.*/gtk-theme-name=$theme/" "$file"
done

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
  gsettings set org.gnome.desktop.interface gtk-theme "$theme" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark 2>/dev/null || true
fi

if command -v xfconf-query >/dev/null 2>&1; then
  xfconf-query -c thunar -p /last-view -s ThunarDetailsView --create -t string 2>/dev/null || true
  xfconf-query -c thunar -p /misc-thumbnail-mode -s THUNAR_THUMBNAIL_MODE_ALWAYS --create -t string 2>/dev/null || true
  xfconf-query -c thunar -p /misc-full-path-in-title -s true --create -t bool 2>/dev/null || true
fi

printf 'GTK theme: %s\n' "$theme"

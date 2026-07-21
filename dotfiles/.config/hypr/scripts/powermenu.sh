#!/usr/bin/env bash
set -Eeuo pipefail

theme="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/fog-and-ember.rasi"
lock="  Lock"
suspend="  Suspend"
logout="  Log out"
reboot="  Reboot"
poweroff="  Power off"

choice=$(printf '%s\n' "$lock" "$suspend" "$logout" "$reboot" "$poweroff" | rofi -dmenu -p "Power" -theme "$theme") || exit 0

confirm() {
  local answer
  answer=$(printf '%s\n' "No" "Yes" | rofi -dmenu -p "$1" -theme "$theme" || true)
  [[ $answer == "Yes" ]]
}

case "$choice" in
  "$lock") "$HOME/.config/hypr/scripts/lock.sh" ;;
  "$suspend")
    "$HOME/.config/hypr/scripts/lock.sh" &
    sleep 0.4
    systemctl suspend
    ;;
  "$logout") confirm "Log out?" && hyprctl dispatch exit ;;
  "$reboot") confirm "Reboot?" && systemctl reboot ;;
  "$poweroff") confirm "Power off?" && systemctl poweroff ;;
esac

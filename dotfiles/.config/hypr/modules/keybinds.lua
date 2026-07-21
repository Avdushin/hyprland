local mod = "SUPER"
local scripts = "$HOME/.config/hypr/scripts"

local function bind(keys, dispatcher, description, flags)
  flags = flags or {}
  flags.description = description
  hl.bind(keys, dispatcher, flags)
end

-- Core applications and launchers.
bind(mod .. " + Return", hl.dsp.exec_cmd(scripts .. "/app-launch.sh terminal"), "Terminal")
bind(mod .. " + B", hl.dsp.exec_cmd(scripts .. "/app-launch.sh browser"), "Default browser")
bind(mod .. " + E", hl.dsp.exec_cmd(scripts .. "/app-launch.sh files"), "File manager: Thunar")
bind(mod .. " + D", hl.dsp.exec_cmd("rofi -show drun -show-icons -theme $HOME/.config/rofi/fog-and-ember.rasi"), "Application launcher: Rofi")
bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("wofi --show drun"), "Application launcher: Wofi")
bind("ALT + V", hl.dsp.exec_cmd(scripts .. "/clipboard.sh"), "Clipboard history")

-- Session helpers.
bind(mod .. " + X", hl.dsp.exec_cmd(scripts .. "/powermenu.sh"), "Power menu")
bind(mod .. " + L", hl.dsp.exec_cmd(scripts .. "/lock.sh"), "Lock screen")
bind(mod .. " + W", hl.dsp.exec_cmd(scripts .. "/wallpaper.sh random"), "Random wallpaper")
bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd(scripts .. "/wallpaper.sh favorite"), "Next favorite wallpaper")
bind(mod .. " + P", hl.dsp.exec_cmd(scripts .. "/toggle-waybar.sh"), "Toggle Waybar")
bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"), "Reload Hyprland")

-- Screenshots.
bind(mod .. " + SHIFT + S", function()
  hl.dispatch(hl.dsp.submap("screenshot"))
  hl.dispatch(hl.dsp.exec_cmd(scripts .. "/screenshot.sh area"))
end, "Screenshot area or window")
hl.define_submap("screenshot", function()
  hl.bind("CTRL + A", hl.dsp.exec_cmd(scripts .. "/screenshot.sh all-from-selector"))
  hl.bind("escape", hl.dsp.exec_cmd(scripts .. "/screenshot.sh cancel"))
end)
bind("Print", hl.dsp.exec_cmd(scripts .. "/screenshot.sh area"), "Screenshot area or window")
bind(mod .. " + Print", hl.dsp.exec_cmd(scripts .. "/screenshot.sh all"), "Screenshot all monitors")

-- Window behavior.
bind(mod .. " + Q", hl.dsp.window.close(), "Close window")
bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = 0, action = "toggle" }), "Toggle fullscreen")
bind(mod .. " + Space", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
bind(mod .. " + H", hl.dsp.layout("preselect r"), "Open next window on the right")
bind(mod .. " + V", hl.dsp.layout("preselect d"), "Open next window below")
bind(mod .. " + SHIFT + E", hl.dsp.layout("togglesplit"), "Toggle split orientation")

bind(mod .. " + R", hl.dsp.submap("resize"), "Enter resize mode")
hl.define_submap("resize", function()
  hl.bind("left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
  hl.bind("right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
  hl.bind("up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
  hl.bind("down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })
  hl.bind("return", hl.dsp.submap("reset"))
  hl.bind("escape", hl.dsp.submap("reset"))
  hl.bind(mod .. " + R", hl.dsp.submap("reset"))
end)

for _, direction in ipairs({ "left", "right", "up", "down" }) do
  bind(mod .. " + " .. direction, hl.dsp.focus({ direction = direction }), "Focus " .. direction, { repeating = true })
  bind(mod .. " + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }), "Move window " .. direction, { repeating = true })
end

for i = 1, 9 do
  bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }), "Workspace " .. i)
  bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }), "Move window silently to workspace " .. i)
end

bind(mod .. " + mouse:272", hl.dsp.window.drag(), "Move window with mouse", { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Resize window with mouse", { mouse = true })

-- PipeWire media and laptop brightness keys.
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), "Volume up", { locked = true, repeating = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), "Volume down", { locked = true, repeating = true })
bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), "Toggle mute", { locked = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), "Toggle microphone", { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause", { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause", { locked = true })
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), "Next track", { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), "Previous track", { locked = true })
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), "Brightness up", { locked = true, repeating = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), "Brightness down", { locked = true, repeating = true })

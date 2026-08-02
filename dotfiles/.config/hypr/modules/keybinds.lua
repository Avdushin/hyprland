local mod = "SUPER"
local scripts = "$HOME/.config/hypr/scripts"

local function bind(keys, dispatcher, description, flags)
  flags = flags or {}
  flags.description = description
  hl.bind(keys, dispatcher, flags)
end

-- Applications and menus.
bind(mod .. " + Return", hl.dsp.exec_cmd(scripts .. "/app-launch.sh terminal"), "Terminal: Ghostty")
bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd(scripts .. "/app-launch.sh sublime"), "Editor: Sublime Text")
bind(mod .. " + B", hl.dsp.exec_cmd(scripts .. "/app-launch.sh browser"), "Browser: Zen")
bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd(scripts .. "/app-launch.sh codium"), "Editor: Codium")
bind(mod .. " + T", hl.dsp.exec_cmd(scripts .. "/app-launch.sh telegram"), "Telegram")
bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd(scripts .. "/app-launch.sh discord"), "Discord / Vesktop")
bind(mod .. " + E", hl.dsp.exec_cmd(scripts .. "/app-launch.sh thunar"), "File manager: Thunar")
bind(mod .. " + O", hl.dsp.exec_cmd(scripts .. "/app-launch.sh obsidian"), "Obsidian")
bind(mod .. " + SHIFT + K", hl.dsp.exec_cmd("ghostty -e calcurse"), "Calendar: Calcurse")
bind(mod .. " + D", hl.dsp.exec_cmd("rofi -show drun -show-icons -theme $HOME/.config/rofi/fog-and-ember.rasi"), "Application launcher")
bind(mod .. " + C", hl.dsp.exec_cmd("rofi -show calc -modi calc -no-show-match -no-sort -theme $HOME/.config/rofi/fog-and-ember.rasi"), "Calculator and converter")
bind(mod .. " + semicolon", hl.dsp.exec_cmd("rofi -show emoji -theme $HOME/.config/rofi/fog-and-ember.rasi"), "Emoji picker")
bind("ALT + V", hl.dsp.exec_cmd(scripts .. "/clipboard.sh"), "Clipboard history")

-- Session helpers.
bind(mod .. " + X", hl.dsp.exec_cmd(scripts .. "/powermenu.sh"), "Power menu")
bind(mod .. " + L", hl.dsp.exec_cmd(scripts .. "/lock.sh"), "Lock screen")
bind(mod .. " + W", hl.dsp.exec_cmd(scripts .. "/wallpaper.sh random"), "Random wallpaper")
bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd(scripts .. "/wallpaper.sh favorite"), "Favorite wallpaper")
bind(mod .. " + P", hl.dsp.exec_cmd(scripts .. "/toggle-waybar.sh"), "Toggle Waybar")
bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd(scripts .. "/monitor-autoconfig.sh --reload-bars"), "Redetect monitors")
bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"), "Reload Hyprland")

-- Open the selector immediately. A click picks the window under the cursor;
-- dragging selects an arbitrary rectangle. Super+Print captures all outputs.
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

-- Window behavior. H/V are one-shot Dwindle preselection, matching the way
-- the user described i3 split h / split v for the next opened window.
bind(mod .. " + Q", hl.dsp.window.close(), "Close window")
bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = 0, action = "toggle" }), "Toggle fullscreen")
bind(mod .. " + Space", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
bind(mod .. " + H", hl.dsp.layout("preselect r"), "Open next tiled window on the right")
bind(mod .. " + V", hl.dsp.layout("preselect d"), "Open next tiled window below")
bind(mod .. " + SHIFT + E", hl.dsp.layout("togglesplit"), "Toggle current split orientation")

-- Familiar i3-like resize mode.
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

bind(mod .. " + left", hl.dsp.focus({ direction = "left" }), "Focus left", { repeating = true })
bind(mod .. " + right", hl.dsp.focus({ direction = "right" }), "Focus right", { repeating = true })
bind(mod .. " + up", hl.dsp.focus({ direction = "up" }), "Focus up", { repeating = true })
bind(mod .. " + down", hl.dsp.focus({ direction = "down" }), "Focus down", { repeating = true })

bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }), "Move window left", { repeating = true })
bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), "Move window right", { repeating = true })
bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }), "Move window up", { repeating = true })
bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }), "Move window down", { repeating = true })

-- Named workspace name:0 preserves the visible/keybinding number 0 because
-- Hyprland reserves numeric workspace id 0.
bind(mod .. " + 0", hl.dsp.focus({ workspace = "name:0" }), "Workspace 0")
bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = "name:0", follow = false }), "Move window silently to workspace 0")
for i = 1, 9 do
  bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }), "Workspace " .. i)
  bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }), "Move window silently to workspace " .. i)
end

bind(mod .. " + mouse:272", hl.dsp.window.drag(), "Move window with mouse", { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Resize window with mouse", { mouse = true })

-- PipeWire media keys.
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), "Volume up", { locked = true, repeating = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), "Volume down", { locked = true, repeating = true })
bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), "Toggle mute", { locked = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), "Toggle microphone", { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause", { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause", { locked = true })
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), "Next track", { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), "Previous track", { locked = true })

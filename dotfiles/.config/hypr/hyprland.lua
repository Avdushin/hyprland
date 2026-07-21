-- Fog & Ember: portable Hyprland desktop configuration.
-- Requires a Hyprland release with Lua configuration support.

require("generated-theme")
require("monitors")
require("modules/appearance")
require("modules/input")
require("modules/rules")
require("modules/keybinds")
require("modules/autostart")

-- Optional machine-local overrides. This file is not tracked by Git.
local user_ok, user_error = pcall(require, "user/local")
if not user_ok and not tostring(user_error):match("module 'user/local' not found") then
  print("Fog & Ember user override:", user_error)
end

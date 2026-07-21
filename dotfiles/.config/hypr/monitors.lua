-- Safe universal fallback: preferred mode, automatic horizontal placement,
-- scale 1. Override this file locally through monitors.local.lua if required.
local local_ok, local_error = pcall(require, "monitors/local")
if not local_ok then
  if not tostring(local_error):match("module 'monitors/local' not found") then
    print("Fog & Ember monitor override:", local_error)
  end
  hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
end

# Monitor configuration

The default profile is intentionally safe and portable:

```lua
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
```

Hyprland chooses each output's preferred mode and arranges monitors
automatically.

For a machine-specific layout:

```bash
cp ~/.config/hypr/monitors/local.lua.example \
   ~/.config/hypr/monitors/local.lua
```

Then inspect outputs:

```bash
hyprctl monitors
```

Edit `~/.config/hypr/monitors/local.lua` and reload:

```bash
hyprctl reload
```

`monitors.local.lua` is ignored by Git so personal output names and geometry do
not leak into a shared configuration.

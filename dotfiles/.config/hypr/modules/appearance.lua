hl.config({
  general = {
    gaps_in = 6,
    gaps_out = 10,
    border_size = 2,
    layout = "dwindle",
    resize_on_border = true,
    extend_border_grab_area = 8,
    allow_tearing = false,
    col = {
      active_border = {
        colors = { THEME.accent, THEME.accent2 },
        angle = 35,
      },
      inactive_border = THEME.inactive,
    },
  },

  decoration = {
    rounding = 11,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    fullscreen_opacity = 1.0,
    shadow = {
      enabled = true,
      range = 10,
      render_power = 2,
      color = THEME.shadow,
      offset = { 0, 3 },
    },
    -- Blur is intentionally restrained: launchers stay legible over both
    -- the bright fog wallpaper and the detailed rainy-house wallpaper.
    blur = {
      enabled = true,
      size = 4,
      passes = 1,
      new_optimizations = true,
      ignore_opacity = false,
      vibrancy = 0.05,
    },
  },

  animations = {
    enabled = true,
  },

  dwindle = {
    -- New windows normally go right/below. The width multiplier also makes
    -- three tiled clients form a vertical column on a portrait monitor.
    force_split = 2,
    preserve_split = true,
    permanent_direction_override = false,
    smart_resizing = true,
    split_width_multiplier = 0.8,
    use_active_for_splits = true,
  },

  binds = {
    drag_threshold = 8,
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
    focus_on_activate = true,
  },
})

hl.curve("fogOut", {
  type = "bezier",
  points = { { 0.22, 1.0 }, { 0.36, 1.0 } },
})
hl.curve("emberFast", {
  type = "bezier",
  points = { { 0.2, 0.0 }, { 0.0, 1.0 } },
})

hl.animation({ leaf = "global", enabled = true, speed = 3.2, bezier = "fogOut" })
hl.animation({ leaf = "windows", enabled = true, speed = 2.5, bezier = "fogOut", style = "popin 94%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.7, bezier = "emberFast", style = "popin 96%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.4, bezier = "fogOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.3, bezier = "fogOut", style = "slidefade 18%" })
hl.animation({ leaf = "layers", enabled = true, speed = 2.0, bezier = "emberFast", style = "fade" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.9, bezier = "emberFast" })
hl.animation({ leaf = "border", enabled = true, speed = 2.4, bezier = "fogOut" })

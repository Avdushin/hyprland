hl.config({
  input = {
    kb_layout = "us,ru",
    kb_variant = "",
    kb_options = "grp:alt_shift_toggle",
    repeat_rate = 35,
    repeat_delay = 300,
    numlock_by_default = true,
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = false,
      disable_while_typing = true,
      tap_to_click = true,
    },
  },
})

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

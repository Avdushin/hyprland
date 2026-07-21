hl.window_rule({
  name = "suppress-app-maximize",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  name = "fix-xwayland-drag",
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  no_focus = true,
})

hl.window_rule({
  name = "desktop-utility-dialogs",
  match = { class = "^(pavucontrol|Pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor|blueman-manager)$" },
  float = true,
  center = true,
  size = { "(monitor_w*0.62)", "(monitor_h*0.70)" },
})

hl.window_rule({
  match = { content = "game", fullscreen = true },
  idle_inhibit = "fullscreen",
})

hl.layer_rule({
  match = { namespace = "rofi" },
  blur = true,
  ignore_alpha = 0.25,
})

hl.window_rule({
  name = "thunar-rename-dialog",
  match = {
    class = "^(thunar|Thunar)$",
    title = "^(Rename|Переименовать).*$",
  },
  float = true,
  center = true,
  size = { 680, 190 },
})

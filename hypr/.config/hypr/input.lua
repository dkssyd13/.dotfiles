hl.config({
  input = {
    kb_layout = "us",
    kb_options = "caps:swapescape,korean:ralt_hangul",
    sensitivity = 0.7,
    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,
    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.2,
    },
  },
})

o.window({ tag = "terminal" }, { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

local function send_shortcut(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

-- Alt+Space opens the Omarchy menu and Right Alt is the Hangul key, so drop
-- Omarchy's dictation bindings on those keys (Superwhisper toggle/push-to-talk).
hl.unbind("ALT + SPACE")
hl.unbind("ALT + Alt_R")

-- macOS-like application shortcuts (Alt acts like Command).
o.bind("ALT + SPACE", "Omarchy menu", "omarchy-menu toggle")
o.bind("ALT + Q", "Close window", hl.dsp.window.close())
o.bind("ALT + W", "Close tab", send_shortcut("CTRL", "W"))
require("hypr.clipboard_alt")
o.bind("ALT + X", "Cut", send_shortcut("CTRL", "X"))
o.bind("ALT + A", "Select all", send_shortcut("CTRL", "A"))
o.bind("ALT + Z", "Undo", send_shortcut("CTRL", "Z"))
o.bind("ALT + SHIFT + Z", "Redo", send_shortcut("CTRL + SHIFT", "Z"))
o.bind("ALT + S", "Save", send_shortcut("CTRL", "S"))
o.bind("ALT + F", "Find", send_shortcut("CTRL", "F"))
o.bind("ALT + N", "New window", send_shortcut("CTRL", "N"))
o.bind("ALT + T", "New tab", send_shortcut("CTRL", "T"))
o.bind("ALT + SHIFT + T", "Reopen closed tab", send_shortcut("CTRL + SHIFT", "T"))
o.bind("ALT + L", "Focus location", send_shortcut("CTRL", "L"))
o.bind("ALT + R", "Reload", send_shortcut("CTRL", "R"))
o.bind("ALT + SHIFT + R", "Hard reload", send_shortcut("CTRL + SHIFT", "R"))
o.bind("ALT + O", "Open", send_shortcut("CTRL", "O"))
o.bind("ALT + P", "Print", send_shortcut("CTRL", "P"))
o.bind("ALT + COMMA", "Preferences", send_shortcut("CTRL", "COMMA"))

-- Replace only the Omarchy shortcuts remapped below.
for _, keys in ipairs({
  "SUPER + J", "SUPER + K", "SUPER + L", "SUPER + W", "SUPER + SPACE",
  "SUPER + TAB", "SUPER + code:20", "SUPER + code:21", "SUPER + SHIFT + SPACE",
  "SUPER + SHIFT + COMMA", "SUPER + BACKSPACE",
}) do
  hl.unbind(keys)
end

o.bind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + SHIFT + H", "Move window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Move window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Move window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Move window right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SUPER + E", "Toggle split orientation", hl.dsp.layout("togglesplit"))
o.bind("SUPER + W", "Toggle window grouping", hl.dsp.group.toggle())
o.bind("SUPER + SHIFT + SPACE", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + code:20", "Resize smaller", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
o.bind("SUPER + code:21", "Resize larger", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
o.bind("SUPER + TAB", "Previous workspace", hl.dsp.focus({ workspace = "previous" }))
o.bind("SUPER + BACKSPACE", "Delete word backward", send_shortcut("CTRL", "BACKSPACE"))

-- Keep the existing Omarchy launch bindings; customize the terminal shortcut.
hl.unbind("SUPER + RETURN")
hl.unbind("SUPER + SHIFT + RETURN")
o.bind("SUPER + SHIFT + RETURN", "Terminal", { omarchy = "terminal" })

-- AeroSpace: alt-shift-[ / ] moves the workspace to the previous/next monitor.
o.bind("SUPER + SHIFT + bracketleft", "Move workspace to left monitor", o.workspaces.move_to_monitor("l"))
o.bind("SUPER + SHIFT + bracketright", "Move workspace to right monitor", o.workspaces.move_to_monitor("r"))

-- AeroSpace: alt-` / alt-shift-` is workspace 0. Omarchy's per-monitor slots are
-- 1-10, so workspace 0 is a named workspace. This replaces the Quake console keys.
hl.unbind("SUPER + grave")
hl.unbind("SUPER + SHIFT + grave")
o.bind("SUPER + grave", "Switch to workspace 0", hl.dsp.focus({ workspace = "name:0" }))
o.bind("SUPER + SHIFT + grave", "Move window to workspace 0", hl.dsp.window.move({ workspace = "name:0" }))

-- AeroSpace app launchers (alt-shift-<key> on macOS). Focus the app if it's
-- already open, otherwise launch it. B (browser), F (files) and Return
-- (terminal) already match Omarchy's defaults.
o.rebind("SUPER + SHIFT + N", "Notion", { webapp = "https://www.notion.so", focus = true })
o.rebind("SUPER + SHIFT + A", "Claude", { webapp = "https://claude.ai", focus = true })
o.rebind("SUPER + SHIFT + O", "ChatGPT", { webapp = "https://chatgpt.com", focus = true })
o.rebind("SUPER + SHIFT + G", "Goodnotes", { webapp = "https://web.goodnotes.com", focus = true })
o.rebind("SUPER + SHIFT + C", "Cursor", { launch = "cursor", focus = "^(Cursor|cursor)$" })
o.rebind("SUPER + SHIFT + V", "VS Code", { launch = "code", focus = "^(Code|code)$" })
o.rebind("SUPER + SHIFT + P", "PyCharm", { launch = "pycharm", focus = "^jetbrains-pycharm.*$" })
o.rebind("SUPER + SHIFT + I", "IntelliJ IDEA", { launch = "idea", focus = "^jetbrains-idea.*$" })
o.rebind("SUPER + SHIFT + Z", "ZenNotes", { launch = "zennotes", focus = "^(ZenNotes|zennotes)$" })

-- Screenshot on Super+Shift+S (was: Google Maps web app). Same action as PRINT.
o.rebind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")

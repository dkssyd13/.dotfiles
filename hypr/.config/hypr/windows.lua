-- Workspace routing shared with the macOS AeroSpace setup.
-- Hyprland regexes are full matches and use RE2 syntax.
o.window({ tag = "chromium-based-browser" }, { workspace = "1" })
o.window({ tag = "firefox-based-browser" }, { workspace = "1" })
o.window("^(Notion|notion-app|chrome-.*notion[.]so.*)$", { workspace = "2" })
o.window("^(jetbrains-.*|Cursor|cursor|Code|code|VSCodium|codium)$", { workspace = "3" })
o.window({ tag = "terminal" }, { workspace = "4" })
o.window("^(Claude|claude|claude-desktop|chrome-.*claude[.](ai|com).*)$", { workspace = "5" })
o.window("^(ChatGPT|chatgpt|chrome-.*chatgpt[.]com.*|Codex|codex)$", { workspace = "5" })
o.window("^(org[.]gnome[.]Nautilus|Nautilus|nautilus)$", { workspace = "6" })
o.window("^(discord|Discord|vesktop|Vesktop|chrome-.*discord[.]com.*)$", {
  float = true,
  workspace = "10",
})

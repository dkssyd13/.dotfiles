-- Workspace routing mirrored from the macOS AeroSpace setup (aerospace.toml).
-- Hyprland regexes are full matches and use RE2 syntax.

-- 1: browsers
o.window({ tag = "chromium-based-browser" }, { workspace = "1" })
o.window({ tag = "firefox-based-browser" }, { workspace = "1" })

-- 2: AI apps (desktop apps or Chrome web apps)
o.window("^(Claude|claude|claude-desktop|chrome-.*claude[.](ai|com).*)$", { workspace = "2" })
o.window("^(ChatGPT|chatgpt|chrome-.*chatgpt[.]com.*|Codex|codex|t3code|T3 Code)$", { workspace = "2" })

-- 3: editors and IDEs
o.window("^(jetbrains-.*|Cursor|cursor|Code|code|com[.]microsoft[.]VSCode|VSCodium|codium)$", { workspace = "3" })

-- 4: terminals
o.window({ tag = "terminal" }, { workspace = "4" })

-- 5: notes
o.window("^(Notion|notion-app|chrome-.*notion[.]so.*|chrome-web[.]goodnotes[.]com.*|ZenNotes|zennotes)$", { workspace = "5" })

-- 6: file manager
o.window("^(org[.]gnome[.]Nautilus|Nautilus|nautilus)$", { workspace = "6" })

-- 10: chat apps, floating
o.window("^(discord|Discord|vesktop|Vesktop|chrome-.*discord[.]com.*|kakaotalk[.]exe|KakaoTalk)$", {
  float = true,
  workspace = "10",
})

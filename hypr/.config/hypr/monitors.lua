-- Portable default: use every connected display at its preferred mode.
hl.env("GDK_SCALE", "2")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Machine-specific outputs live in the untracked ~/.config/hypr/monitors_local.lua.
-- Check outputs with `hyprctl monitors all`.
pcall(require, "hypr.monitors_local")

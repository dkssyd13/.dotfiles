-- Portable default: use every connected display at its preferred mode.
-- Add machine-specific output rules below after checking `hyprctl monitors all`.
hl.env("GDK_SCALE", "2")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

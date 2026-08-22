-- Omarchy bootstrap and defaults. Personal modules below are loaded last so
-- distro updates can improve the defaults without replacing these settings.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")
require("default.hypr.omarchy")

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
require("hypr.windows")

require("default.hypr.toggles")

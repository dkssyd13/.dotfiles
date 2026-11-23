-- macOS and non-Omarchy Linux: catppuccin macchiato, transparent.
-- On Omarchy the theme comes from plugins/omarchy.lua instead.
if require("config.omarchy").enabled() then
  return {}
end

return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  opts = {
    flavour = "macchiato",
    transparent_background = true,
    no_italic = true,
    auto_integrations = true,
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin-macchiato")
  end,
}

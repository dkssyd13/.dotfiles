-- Omarchy (Linux) only: every theme plugin Omarchy may select, so theme
-- switches never need a download. Synced with omarchy-nvim's all-themes.lua
-- and Omarchy 4's default/themed/neovim.lua.tpl. See config/omarchy.lua.
if not require("config.omarchy").enabled() then
  return {}
end

local themes = {
  { "ribru17/bamboo.nvim" },
  -- name and branch must match Omarchy 4's generated theme spec
  { "omacom/aether.nvim", branch = "v3", name = "aether" },
  { "bjarneo/ethereal.nvim" },
  { "bjarneo/hackerman.nvim" },
  { "bjarneo/vantablack.nvim" },
  { "bjarneo/white.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
  { "neanias/everforest-nvim" },
  { "kepano/flexoki-neovim" },
  { "ellisonleao/gruvbox.nvim" },
  { "rebelot/kanagawa.nvim" },
  { "tahayvr/matteblack.nvim" },
  { "loctvl842/monokai-pro.nvim" },
  { "EdenEast/nightfox.nvim" },
  { "rose-pine/neovim", name = "rose-pine" },
  { "ficcdaf/ashen.nvim" },
  { "folke/tokyonight.nvim" },
  { "OldJobobo/miasma.nvim" },
  { "OldJobobo/retro-82.nvim" },
  { "omacom-io/lumon.nvim" },
}
for _, spec in ipairs(themes) do
  spec.lazy = true
  spec.priority = 1000
end

return vim.list_extend(themes, {
  -- The Omarchy theme file (plugins/theme.lua) also carries
  -- { "LazyVim/LazyVim", opts = { colorscheme = ... } }. Disabled here so
  -- LazyVim is never installed; config/omarchy.lua reads the colorscheme.
  { "LazyVim/LazyVim", enabled = false },
  -- An Omarchy migration may copy lualine-transparent.lua into the config;
  -- the statusline here is mini.statusline.
  { "nvim-lualine/lualine.nvim", enabled = false },
})

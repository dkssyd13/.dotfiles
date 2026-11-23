-- Hand-written config on lazy.nvim (no LazyVim).
-- Load order: shared ~/.vimrc -> options -> autocmds -> keymaps -> plugins.

-- The shared vimrc is also read by VS Code (vscodevim) and IdeaVim. It sets
-- the leader and the common mappings; Neovim-specific ones override it below.
local vimrc = vim.fn.expand("~/.vimrc")
if vim.uv.fs_stat(vimrc) then
  local ok, err = pcall(vim.cmd.source, vimrc)
  if not ok then
    vim.notify("Failed to source ~/.vimrc: " .. tostring(err), vim.log.levels.WARN)
  end
end
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.autocmds")
require("config.keymaps")

-- On Omarchy, lua/plugins/theme.lua must be a symlink to the current Omarchy
-- theme so that lazy.nvim's change detection sees theme switches.
local omarchy = require("config.omarchy")
if omarchy.enabled() then
  omarchy.link_theme()
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "catppuccin-macchiato", "habamax" } },
  checker = { enabled = true, notify = false },
  -- Keep change detection on: Omarchy theme hot-reload depends on it.
  change_detection = { enabled = true, notify = false },
  rocks = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})

if omarchy.enabled() then
  omarchy.setup()
end

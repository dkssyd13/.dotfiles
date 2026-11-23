-- Omarchy (Linux) theme integration without LazyVim. Ported from the
-- omarchy-nvim package (theme hot-reload, transparency).
--
-- Omarchy writes the current theme's Neovim spec to
--   ~/.local/state/omarchy/current/theme/neovim.lua   (Omarchy 4)
--   ~/.config/omarchy/current/theme/neovim.lua        (Omarchy 3)
-- It returns a plugin spec plus { "LazyVim/LazyVim", opts = { colorscheme = ... } }.
-- lua/plugins/theme.lua is a symlink to that file (created by link_theme(),
-- ignored by git), so lazy.nvim's change detection fires on every theme switch.
-- The LazyVim entry is disabled in plugins/omarchy.lua; this module reads its
-- colorscheme and applies it on startup and on `User LazyReload`.
local M = {}

local home = vim.env.HOME or vim.fn.expand("~")
local candidates = {
  home .. "/.local/state/omarchy/current/theme/neovim.lua",
  home .. "/.config/omarchy/current/theme/neovim.lua",
}

M.link = vim.fn.stdpath("config") .. "/lua/plugins/theme.lua"

---@return string?
function M.theme_file()
  for _, file in ipairs(candidates) do
    if vim.uv.fs_stat(file) then
      return file
    end
  end
end

function M.enabled()
  if M._enabled == nil then
    M._enabled = vim.uv.os_uname().sysname == "Linux" and M.theme_file() ~= nil
  end
  return M._enabled
end

--- Point lua/plugins/theme.lua at the Omarchy theme file. Only a missing file
--- or a symlink is replaced; a regular file is left alone.
function M.link_theme()
  local target = M.theme_file()
  if not target then
    return
  end
  local stat = vim.uv.fs_lstat(M.link)
  if stat and stat.type ~= "link" then
    vim.schedule(function()
      vim.notify(M.link .. " is a regular file; Omarchy theme hot-reload needs it to be a symlink", vim.log.levels.WARN)
    end)
    return
  end
  if stat and vim.uv.fs_readlink(M.link) == target then
    return
  end
  if stat then
    vim.uv.fs_unlink(M.link)
  end
  local ok, err = vim.uv.fs_symlink(target, M.link)
  if not ok then
    vim.schedule(function()
      vim.notify("Could not link Omarchy theme: " .. tostring(err), vim.log.levels.WARN)
    end)
  end
end

---@return table? spec
local function read_theme_spec()
  local chunk = loadfile(M.link) or (M.theme_file() and loadfile(M.theme_file()))
  if not chunk then
    return
  end
  local ok, spec = pcall(chunk)
  if ok and type(spec) == "table" then
    return spec
  end
end

local function plugin_name(spec)
  if spec.name then
    return spec.name
  end
  local url = spec[1] or spec.url or ""
  return (url:gsub("%.git$", ""):match("[^/]+$"))
end

--- Colorscheme name and theme plugin name from the Omarchy spec.
---@return string? colorscheme, string? plugin
function M.current()
  local spec = read_theme_spec()
  if not spec then
    return
  end
  local colorscheme, plugin
  for _, entry in ipairs(spec) do
    if type(entry) == "table" then
      if entry[1] == "LazyVim/LazyVim" then
        colorscheme = entry.opts and entry.opts.colorscheme
      elseif not plugin and (entry[1] or entry.url or entry.dir) then
        plugin = plugin_name(entry)
      end
    end
  end
  return colorscheme, plugin
end

-- Transparent backgrounds, as in omarchy-nvim's plugin/after/transparency.lua,
-- adapted to the plugins used here (mini.statusline, snacks).
local transparent_groups = {
  "Normal",
  "NormalFloat",
  "FloatBorder",
  "Pmenu",
  "Terminal",
  "EndOfBuffer",
  "FoldColumn",
  "Folded",
  "SignColumn",
  "LineNr",
  "CursorLineNr",
  "StatusLine",
  "StatusLineNC",
  "NormalNC",
  -- statusline sections that lualine's b/c sections cover in omarchy-nvim;
  -- the mode and location sections keep their colours
  "MiniStatuslineDevinfo",
  "MiniStatuslineFilename",
  "MiniStatuslineFileinfo",
  "MiniStatuslineInactive",
}

function M.transparency()
  -- The current line goes see-through too, leaving its number to mark it.
  -- The explorer marks its selection with that line alone, so it keeps it.
  local cursorline = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false })
  if cursorline.bg then
    vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = cursorline.bg })
  end
  for _, name in ipairs(vim.list_extend(vim.deepcopy(transparent_groups), { "CursorLine" })) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok then
      hl.bg = nil
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
end

local function apply(colorscheme)
  if not colorscheme or not pcall(vim.cmd.colorscheme, colorscheme) then
    vim.notify("Omarchy colorscheme not available: " .. tostring(colorscheme), vim.log.levels.WARN)
    pcall(vim.cmd.colorscheme, "habamax")
  end
end

local function reload()
  local colorscheme, plugin_id = M.current()
  if not colorscheme then
    return
  end
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  -- Light themes set this back themselves.
  vim.o.background = "dark"

  local Config = require("lazy.core.config")
  local Loader = require("lazy.core.loader")
  local plugin = plugin_id and Config.plugins[plugin_id]
  if plugin then
    require("lazy.core.util").walkmods(plugin.dir .. "/lua", function(modname)
      package.loaded[modname] = nil
      package.preload[modname] = nil
    end)
  end
  -- Old and new theme may share a plugin (Omarchy 4 generates most themes on
  -- aether.nvim). lazy keeps the old opts for an already loaded plugin, so
  -- reload it to run setup() with the new theme's opts.
  if plugin and plugin._.loaded then
    Loader.reload(plugin)
  else
    Loader.colorscheme(colorscheme)
  end
  vim.defer_fn(function()
    apply(colorscheme)
    vim.cmd("redraw!")
  end, 5)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_omarchy", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = M.transparency })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "LazyReload",
    callback = function()
      vim.schedule(reload)
    end,
  })
  apply((M.current()))
end

return M

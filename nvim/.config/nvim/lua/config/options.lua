local opt = vim.opt

-- Look
opt.guicursor = ""
opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.colorcolumn = "80,120" -- VS Code rulers
opt.cursorline = true
opt.laststatus = 3
opt.showmode = false -- the statusline shows the mode

-- Indentation: 4 spaces (C/C++ use 2, see autocmds.lua)
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- Wrapping like VS Code "editor.wordWrap": "on"
opt.wrap = true
opt.linebreak = true
opt.breakindent = true

opt.scrolloff = 8
opt.isfname:append("@-@")

-- Files and undo (undodir is shared with the old config, so history is kept)
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.env.HOME .. "/.vim/undodir"
opt.undolevels = 10000
opt.confirm = true

-- Search
opt.hlsearch = false
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true

opt.updatetime = 50
opt.clipboard = "" -- system clipboard only through <leader>y / <leader>Y

-- Over SSH or inside herdr, "+ yanks also go to the terminal in front of you
-- through OSC 52 (herdr forwards it). Otherwise <leader>y on a remote Mac only
-- reaches that Mac's pbcopy clipboard. Paste never asks the terminal over OSC 52
-- (it prompts or hangs): over SSH it returns the last yank, so paste text from
-- the local machine with the terminal's own paste key.
do
  local in_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil
  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if ok and (in_ssh or vim.env.HERDR_PANE_ID ~= nil) then
    local native
    if vim.fn.has("mac") == 1 then
      native = { copy = { "pbcopy" }, paste = { "pbpaste" } }
    elseif vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-copy") == 1 then
      native = { copy = { "wl-copy", "--type", "text/plain" }, paste = { "wl-paste", "--no-newline" } }
    end
    local use_native = native ~= nil and not in_ssh
    local last = {}

    local function copy(reg)
      local emit = osc52.copy(reg)
      return function(lines, regtype)
        last[reg] = { vim.deepcopy(lines), regtype }
        emit(lines)
        if use_native then
          vim.fn.system(native.copy, lines)
        end
      end
    end

    local function paste(reg)
      return function()
        if use_native then
          local lines = vim.fn.systemlist(native.paste, "", 1)
          if vim.v.shell_error == 0 then
            if last[reg] and vim.deep_equal(lines, last[reg][1]) then
              return vim.deepcopy(last[reg])
            end
            return lines
          end
        end
        return vim.deepcopy(last[reg] or { {}, "v" })
      end
    end

    vim.g.clipboard = {
      name = "osc52",
      copy = { ["+"] = copy("+"), ["*"] = copy("*") },
      paste = { ["+"] = paste("+"), ["*"] = paste("*") },
      cache_enabled = 0,
    }
  end
end
opt.splitright = true
opt.splitbelow = true

-- Folding: nothing is folded on open; treesitter folds where available
opt.foldlevel = 99
opt.foldmethod = "indent"
opt.foldtext = ""

-- Snacks: no animations
vim.g.snacks_animate = false

-- No remote-plugin providers. Without this, every Python buffer pays ~40 ms
-- for the python3 provider probe started by ftplugin/python.vim.
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

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

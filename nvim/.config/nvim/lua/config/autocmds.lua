local function augroup(name)
  return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Orange relative line numbers and yank flash (same colour as VS Code),
-- re-applied after every colorscheme change.
local function custom_highlights()
  vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#FF6B00" })
  vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#FF6B00" })
  vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#FF6B00" })
end
custom_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup("custom_highlights"),
  callback = custom_highlights,
})

-- Replaces the ~/.vimrc yank autocmd (same group name), which uses defaults.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ higroup = "YankHighlight", timeout = 40 })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("c_indent"),
  pattern = { "c", "cpp" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("markdown_nospell"),
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- Reload files changed outside Neovim
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Reopen files at the last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(ev)
    local exclude = { gitcommit = true, gitrebase = true }
    if exclude[vim.bo[ev.buf].filetype] or vim.b[ev.buf].last_loc_done then
      return
    end
    vim.b[ev.buf].last_loc_done = true
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close helper windows with q
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "qf", "checkhealth", "lspinfo", "man", "notify", "dap-float", "gitsigns-blame" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true, desc = "Close window" })
  end,
})

-- Keep splits equal when the terminal is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. tab)
  end,
})

-- Create missing parent directories on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_create_dir"),
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

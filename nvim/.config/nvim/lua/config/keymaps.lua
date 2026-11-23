-- Global keymaps. ~/.vimrc is sourced first; where it disagrees with VS Code,
-- VS Code wins (<C-j>/<C-k>, [d/]d, <Esc>). Plugin keys live in their specs,
-- LSP buffer keys (gd, gr, gR, gi, K) in config/lsp.lua.
local map = vim.keymap.set

-- Neovim's default gr* LSP maps would make `gr` wait for a second key.
for _, lhs in ipairs({ "grn", "grr", "gri", "grt", "grx" }) do
  pcall(vim.keymap.del, "n", lhs)
end
pcall(vim.keymap.del, { "n", "x" }, "gra")

-- Windows (VS Code ctrl+h/j/k/l)
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Diagnostics
local function open_diagnostic_float(diagnostic, bufnr)
  if diagnostic then
    vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
  end
end
map("n", "]d", function()
  vim.diagnostic.jump({ count = vim.v.count1, on_jump = open_diagnostic_float })
end, { desc = "Next diagnostic" })
map("n", "[d", function()
  vim.diagnostic.jump({ count = -vim.v.count1, on_jump = open_diagnostic_float })
end, { desc = "Previous diagnostic" })

-- <Esc>: close side panels (explorer, Trouble, dap-ui) if any, else clear search.
local function close_panels()
  local closed = false
  if package.loaded.snacks then
    for _, picker in ipairs(Snacks.picker.get({ source = "explorer" })) do
      picker:close()
      closed = true
    end
  end
  if package.loaded.trouble then
    local trouble = require("trouble")
    for _ = 1, 10 do
      if not trouble.is_open() then
        break
      end
      trouble.close()
      closed = true
    end
  end
  if package.loaded.dapui then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
      if ft:find("^dapui_") or ft == "dap-repl" then
        require("dapui").close()
        closed = true
        break
      end
    end
  end
  return closed
end
map("n", "<Esc>", function()
  if not close_panels() then
    vim.cmd("nohlsearch")
  end
end, { desc = "Close side panels or clear search highlight" })

-- LSP actions (PyCharm/VS Code habits). Refactors come from pyrefly.
-- Wrapped in functions so vim.lsp is not loaded at startup.
map("n", "<leader>rn", function()
  vim.lsp.buf.rename()
end, { desc = "Rename symbol" })
map({ "n", "x" }, "<leader>ca", function()
  vim.lsp.buf.code_action()
end, { desc = "Code action" })
map("n", "<leader>oi", function()
  require("config.lsp").apply_action("source.organizeImports.ruff")
end, { desc = "Organize imports (ruff)" })
map({ "n", "x" }, "<leader>nm", function()
  require("config.lsp").refactor("extract_method")
end, { desc = "Extract method" })
map({ "n", "x" }, "<leader>nv", function()
  require("config.lsp").refactor("extract_variable")
end, { desc = "Extract variable" })
map({ "n", "x" }, "<leader>in", function()
  require("config.lsp").refactor("inline")
end, { desc = "Inline" })

map("n", "<leader>cr", function()
  require("config.python").run_file()
end, { desc = "Run file (no debugger)" })

-- Surround (mini.surround, see plugins/mini.lua). Normal: inner word under the
-- cursor; visual: the selection. Opening and closing characters give the same
-- result without inner spaces, like the VS Code snippets.
local pairs_by_char = {
  ['"'] = '"',
  ["'"] = "'",
  ["("] = ")",
  [")"] = ")",
  ["["] = "]",
  ["]"] = "]",
  ["{"] = "}",
  ["}"] = "}",
}
for char, target in pairs(pairs_by_char) do
  map("n", "<leader>w" .. char, "gsaiw" .. target, { remap = true, desc = "Surround word with " .. char })
  map("x", "<leader>" .. char, "gsa" .. target, { remap = true, desc = "Surround selection with " .. char })
end

-- Markdown math
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_markdown_keys", { clear = true }),
  pattern = "markdown",
  callback = function(ev)
    map("i", ";m", "$$<Left>", { buffer = ev.buf, desc = "Inline math" })
    map("i", ";M", "$$<CR><CR>$$<Up>", { buffer = ev.buf, desc = "Display math" })
  end,
})

-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- Refactoring
vim.keymap.set({ "n", "v" }, "<leader>rc", function()
  LazyVim.format({ force = true })
end, { desc = "Format" })

vim.keymap.set({ "n", "v" }, "<leader>rm", function()
  vim.lsp.buf.code_action({
    context = { only = { "refactor.extract" } },
  })
end, { desc = "Extract Method" })

vim.keymap.set({ "n", "v" }, "<leader>rv", function()
  vim.lsp.buf.code_action({
    context = { only = { "refactor.extract" } },
  })
end, { desc = "Extract Variable" })

-- Unbind 
vim.keymap.del("n", "s")
vim.keymap.del("v", "s")
vim.keymap.del("n", "[d")
vim.keymap.del("n", "]d")

-- Snacks
vim.keymap.set("n", "<Esc>", function()
  local explorers = Snacks.picker.get({ source = "explorer" })
  if #explorers > 0 then
    for _, picker in ipairs(explorers) do
      picker:close()
    end
  else
    vim.cmd("nohlsearch")
  end
end, { desc = "Close explorer or clear highlights" })

-- VIM bindings
vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next Diagnostic" })

vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev Diagnostic" })
vim.keymap.set("n", "<leader>pv", ":Ex<CR>")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>")
vim.keymap.set("n", "<leader>q", ":lopen<CR>")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "=ap", "ma=ap'a")
vim.keymap.set("x", "<leader>p", '"_dP')
vim.keymap.set("n", "<leader>Y", '"+Y')
vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>d", '"_d')
vim.keymap.set("v", "<leader>d", '"_d')
vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<C-k>", ":cnext<CR>zz")
vim.keymap.set("n", "<C-j>", ":cprev<CR>zz")
vim.keymap.set("n", "<leader>k", ":lnext<CR>zz")
vim.keymap.set("n", "<leader>j", ":lprev<CR>zz")
vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")
vim.keymap.set("n", "<leader>x", ":!chmod +x %<CR>")

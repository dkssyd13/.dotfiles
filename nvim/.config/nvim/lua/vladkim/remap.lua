vim.cmd("source ~/.vimrc")

vim.api.nvim_set_keymap("n", "<leader>tf", "<Plug>PlenaryTestFile", { noremap = false, silent = false })

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to previous [D]iagnostic message" })

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.keymap.set("n", "<leader>f", function()
	require("conform").format({ bufnr = 0 })
end)

-- 창 너비 줄이기: Ctrl + Alt + Left
vim.keymap.set("n", "<C-M-Right>", "<Cmd>vertical resize -5<CR>", { desc = "창 너비 줄이기" })

-- 창 너비 늘리기: Ctrl + Alt + Right
vim.keymap.set("n", "<C-M-Left>", "<Cmd>vertical resize +5<CR>", { desc = "창 너비 늘리기" })

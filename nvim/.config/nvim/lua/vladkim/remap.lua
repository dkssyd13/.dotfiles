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


-- Explorer 너비 조정 함수들
local function adjust_explorer_width(delta)
    -- 현재 열려있는 explorer picker 찾기
    local explorers = Snacks.picker.get({ source = "explorer" })

    if #explorers == 0 then
        vim.notify("No explorer open", vim.log.levels.WARN)
        return
    end

    local picker = explorers[1]
    local current_layout = picker.resolved_layout
    local current_width = current_layout.layout.width or 30
    local new_width = math.max(15, math.min(80, current_width + delta))

    -- 새로운 레이아웃 적용
    picker:set_layout(vim.tbl_deep_extend("force", current_layout, {
        layout = { width = new_width }
    }))

    vim.notify(string.format("Explorer width: %d", new_width), vim.log.levels.INFO)
end

-- 창 너비 줄이기: Ctrl + Alt + Left
vim.keymap.set("n", "<C-A-Left>", function()
    adjust_explorer_width(-5)
end, { desc = "Decrease explorer width" })

-- 창 너비 늘리기: Ctrl + Alt + Right
vim.keymap.set("n", "<C-A-Right>", function()
    adjust_explorer_width(5)
end, { desc = "Increase explorer width" })

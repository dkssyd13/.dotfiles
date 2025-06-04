require("vladkim.set")

require("vladkim.lazy_init")

local augroup = vim.api.nvim_create_augroup
local vladkimGroup = augroup('vladkim', {})
local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

-- module hot reload
function R(name)
	require("plenary.reload").reload_module(name)
end

-- Highlight after yank
vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#FF6B00" })
autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'YankHighlight',
            timeout = 40, -- 40 ms
        })
    end,
})

--
autocmd({"BufWritePre"}, {
    group = vladkimGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- Keyboard shortcuts auto conf. (When LSP is connected)
autocmd('LspAttach', {
    group = vladkimGroup,
    callback = function(e)
        local opts = { buffer = e.buf }
        vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
        vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
        vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
        vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
        vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
        vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
        vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
        vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
        vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
    end
})

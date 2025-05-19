-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
        'MunifTanjim/nui.nvim',
    },
    lazy = false,
    keys = {
        { '\\', ':Neotree reveal<CR>',mode = 'n', desc = 'NeoTree reveal', silent = true },
    },
    opts = {
        filesystem = {
            window = {
                width = 30,
                mappings = {
                    ['\\'] = 'close_window',
                    ['<esc>'] = function(state)
                        vim.cmd('wincmd p')  -- 이전 창으로 포커스 이동
                    end,
                },
            },
        },
    },
}

return {
  "nvim-mini/mini.nvim",
  event = "VeryLazy",
  config = function()
    require("mini.icons").setup()
    MiniIcons.mock_nvim_web_devicons()
    require("mini.ai").setup({ n_lines = 500 })
    require("mini.pairs").setup()
    -- gs-prefixed like LazyVim's mini-surround extra; <leader>w" etc. in keymaps.lua
    require("mini.surround").setup({
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
    })
    require("mini.statusline").setup()
  end,
}

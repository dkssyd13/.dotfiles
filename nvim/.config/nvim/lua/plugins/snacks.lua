return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    picker = {
      enabled = true,
      sources = {
        files = { hidden = true, ignored = false },
        grep = { ignored = true },
        explorer = {
          hidden = true,
          ignored = true,
          layout = { layout = { width = 25, min_width = 25 } }, -- the sidebar preset has min_width 40
          win = {
            list = {
              keys = {
                -- back to the editor, explorer stays open (VS Code Escape in the sidebar)
                ["<Esc>"] = {
                  function()
                    vim.cmd("wincmd p")
                  end,
                  mode = "n",
                },
              },
            },
          },
        },
      },
    },
    explorer = { enabled = true },
    terminal = { enabled = true },
    dashboard = { enabled = false },
    scroll = { enabled = false },
    dim = { enabled = false },
    animate = { enabled = false },
  },
  -- stylua: ignore
  keys = {
    { "<leader>e", function() Snacks.explorer() end, desc = "File explorer" },
    { "<leader><space>", function() Snacks.picker.files() end, desc = "Find files" },
    { "<leader>fp", function() Snacks.picker.grep() end, desc = "Grep (find in files)" },
    { "<leader>ff", function() Snacks.picker.grep() end, desc = "Grep (find in files)" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>u", function() Snacks.picker.undo() end, desc = "Undo history" },
  },
}

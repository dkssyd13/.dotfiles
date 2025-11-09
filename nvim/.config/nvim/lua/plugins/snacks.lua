return {
  "folke/snacks.nvim",
  opts = {
    dashboard = { enabled = false },
    scroll = { enabled = false },
    picker = {
      sources = {
        explorer = {
          layout = {
            layout = {
              width = 25, -- 너비만 조정
            },
          },
          win = {
            list = {
              keys = {
                ["<Esc>"] = {
                  function()
                    -- 메인 버퍼로 포커스 이동 (explorer는 열어둠)
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
  },
  keys = function()
    return {
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "File Explorer",
      },
      {
        "<leader><space>",
        function()
          Snacks.picker.files()
        end,
        desc = "Find (Project) Files",
      },
      {
        "<leader>u",
        function()
          Snacks.picker.undo()
        end,
        desc = "Undo History",
      },
    }
  end,
}

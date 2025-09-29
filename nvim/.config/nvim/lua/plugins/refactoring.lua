return {
  "ThePrimeagen/refactoring.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    { "<leader>n", "", desc = "+refactor", mode = { "n", "x" } },
    {
      "<leader>in",
      function()
        return require("refactoring").refactor("Inline Variable")
      end,
      mode = { "n", "x" },
      desc = "Inline Variable",
      expr = true,
    },
    {
      "<leader>nb",
      function()
        return require("refactoring").refactor("New Block")
      end,
      mode = { "n", "x" },
      desc = "Extract Block",
      expr = true,
    },
    {
      "<leader>nB",
      function()
        return require("refactoring").refactor("Extract Block To File")
      end,
      mode = { "n", "x" },
      desc = "Extract Block To File",
      expr = true,
    },
    {
      "<leader>np",
      function()
        require("refactoring").debug.print_var({ normal = true })
      end,
      mode = { "n", "x" },
      desc = "Debug Print Variable",
    },
    {
      "<leader>rc",
      function()
        require("refactoring").debug.cleanup({})
      end,
      desc = "Debug Cleanup",
    },
    {
      "<leader>nm",
      function()
        return require("refactoring").refactor("Extract Function")
      end,
      mode = { "n", "x" },
      desc = "Extract Function",
      expr = true,
    },
    {
      "<leader>nM",
      function()
        return require("refactoring").refactor("Extract Function To File")
      end,
      mode = { "n", "x" },
      desc = "Extract Function To File",
      expr = true,
    },
    {
      "<leader>nv",
      function()
        return require("refactoring").refactor("Extract Variable")
      end,
      mode = { "n", "x" },
      desc = "Extract Variable",
      expr = true,
    },
  },
}

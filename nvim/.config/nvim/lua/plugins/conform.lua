return {
  "stevearc/conform.nvim",
  cmd = "ConformInfo",
  dependencies = { "mason-org/mason.nvim" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = false, timeout_ms = 3000 })
      end,
      mode = { "n", "x" },
      desc = "Format",
    },
  },
  opts = {
    -- No format on save (VS Code: formatOnSave off). Python formats through
    -- the ruff language server so lineLength=120 and configurationPreference
    -- from config/lsp.lua apply, as with the VS Code ruff extension.
    default_format_opts = { lsp_format = "fallback" },
    formatters_by_ft = {
      python = { lsp_format = "prefer" },
      lua = { "stylua" },
      markdown = { "markdownlint-cli2" },
      swift = { "swiftformat" },
    },
    formatters = {
      ["markdownlint-cli2"] = {
        prepend_args = { "--config", vim.env.HOME .. "/.markdownlint.yaml" },
      },
    },
  },
}

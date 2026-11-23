-- Mason only installs tools and puts them on PATH; servers are enabled
-- explicitly in config/lsp.lua (no mason-lspconfig auto-enable).
local mason_packages = {
  "pyrefly",
  "ruff",
  "marksman",
  "taplo",
  "lua-language-server",
  "json-lsp",
  "debugpy",
  "stylua",
  "markdownlint-cli2",
}

return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {},
    config = function(_, opts)
      require("mason").setup(opts)
      -- install anything missing, after startup
      vim.defer_fn(function()
        local registry = require("mason-registry")
        registry.refresh(function()
          for _, name in ipairs(mason_packages) do
            local ok, pkg = pcall(registry.get_package, name)
            if ok and not pkg:is_installed() and not pkg:is_installing() then
              pkg:install()
            end
          end
        end)
      end, 500)
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim", "saghen/blink.cmp" },
    config = function()
      require("config.lsp").setup()
    end,
  },
}

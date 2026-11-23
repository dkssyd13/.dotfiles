-- markdownlint-cli2 diagnostics for Markdown, with the user-wide config.
return {
  "mfussenegger/nvim-lint",
  ft = "markdown",
  dependencies = { "mason-org/mason.nvim" },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = { markdown = { "markdownlint-cli2" } }
    -- keep nvim-lint's own args (stdin "-") and put the config in front
    local markdownlint = lint.linters["markdownlint-cli2"]
    markdownlint.args = vim.list_extend({ "--config", vim.env.HOME .. "/.markdownlint.yaml" }, markdownlint.args or {})

    local timer = assert(vim.uv.new_timer())
    local function try_lint()
      timer:stop()
      timer:start(
        100,
        0,
        vim.schedule_wrap(function()
          lint.try_lint()
        end)
      )
    end
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("user_lint", { clear = true }),
      callback = try_lint,
    })
    try_lint()
  end,
}

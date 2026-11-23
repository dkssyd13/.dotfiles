local parsers = {
  "python",
  "lua",
  "vim",
  "vimdoc",
  "markdown",
  "markdown_inline",
  "toml",
  "json",
  "yaml",
  "bash",
  "c",
  "latex",
  "query",
  "html", -- inline HTML in Markdown (render-markdown)
  "regex", -- regex highlighting in the snacks picker
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- the main branch does not support lazy-loading
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    ts.setup()
    local installed = require("nvim-treesitter.config").get_installed()
    local missing = vim.tbl_filter(function(lang)
      return not vim.tbl_contains(installed, lang)
    end, parsers)
    if #missing > 0 then
      ts.install(missing)
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      callback = function(ev)
        if not pcall(vim.treesitter.start, ev.buf) then
          return
        end
        local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
        if lang and vim.treesitter.query.get(lang, "indents") then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
        if lang and vim.treesitter.query.get(lang, "folds") then
          vim.wo[0][0].foldmethod = "expr"
          vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end
      end,
    })
  end,
}

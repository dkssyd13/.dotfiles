-- Used for gR (references list, like VS Code's references view); see config/lsp.lua.
return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  opts = {
    -- always show the list, even for a single reference
    modes = { lsp_references = { auto_jump = false } },
  },
}

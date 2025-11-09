return {
  "folke/noice.nvim",
  opts = {
    lsp = {
      signature = {
        enabled = true,
        opts = {
          relative = "cursor",
          size = {
            max_width = 60,
            max_height = 10,
          },
        },
      },
    },
    presets = {
      lsp_doc_border = true,
    },
  },
}

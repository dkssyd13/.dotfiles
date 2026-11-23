return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(buf)
      local gs = require("gitsigns")
      vim.keymap.set("n", "]h", function()
        gs.nav_hunk("next")
      end, { buffer = buf, desc = "Next git hunk" })
      vim.keymap.set("n", "[h", function()
        gs.nav_hunk("prev")
      end, { buffer = buf, desc = "Previous git hunk" })
    end,
  },
}

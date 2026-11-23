return {
  "saghen/blink.cmp",
  version = "*", -- release tags ship the prebuilt fuzzy matcher
  event = { "InsertEnter", "CmdlineEnter" },
  opts = {
    keymap = {
      preset = "super-tab",
      ["<Tab>"] = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.accept()
          else
            return cmp.select_and_accept()
          end
        end,
        "snippet_forward",
        "fallback",
      },
    },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      accept = { auto_brackets = { enabled = true } },
      menu = { border = "rounded", max_height = 10 },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = {
          min_width = 10,
          max_width = 50,
          max_height = 12,
          border = "rounded",
          direction_priority = {
            menu_north = { "n", "e", "w", "s" },
            menu_south = { "n", "e", "w", "s" },
          },
        },
      },
    },
    -- replaces noice's signature help popup
    signature = { enabled = true, window = { border = "rounded" } },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    cmdline = {
      keymap = { preset = "cmdline", ["<Right>"] = false, ["<Left>"] = false },
      completion = {
        list = { selection = { preselect = false } },
        menu = {
          auto_show = function()
            return vim.fn.getcmdtype() == ":"
          end,
        },
      },
    },
  },
}

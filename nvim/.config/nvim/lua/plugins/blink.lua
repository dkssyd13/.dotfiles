return {
  "saghen/blink.cmp",
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
    completion = {
      menu = {
        border = "rounded",
        max_height = 10,
      },
      documentation = {
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
  },
}

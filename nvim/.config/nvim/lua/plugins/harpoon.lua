local keys = {
  {
    "<leader>H",
    function()
      local harpoon = require("harpoon")
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end,
    desc = "Harpoon menu",
  },
}
for i = 1, 5 do
  table.insert(keys, {
    "<leader>" .. i,
    function()
      require("harpoon"):list():select(i)
    end,
    desc = "Harpoon: go to file " .. i,
  })
  table.insert(keys, {
    "<leader>h" .. i,
    function()
      require("harpoon"):list():replace_at(i)
    end,
    desc = "Harpoon: set file " .. i,
  })
end

return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = { settings = { save_on_toggle = true } },
  config = function(_, opts)
    require("harpoon"):setup(opts)
  end,
  keys = keys,
}

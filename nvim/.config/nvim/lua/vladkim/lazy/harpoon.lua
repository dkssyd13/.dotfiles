return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        menu = {
            width = vim.api.nvim_win_get_width(0) - 4,
        },
        settings = {
            save_on_toggle = true,
        },
    },
    keys = function()
        local keys = {
            {
                "<leader>h",
                function()
                    require("harpoon"):list():add()
                end,
                desc = "Harpoon File",
            },

            {
                "<leader>H",
                function()
                    local harpoon = require("harpoon")
                    harpoon.ui:toggle_quick_menu(harpoon:list())
                end,
                desc = "Harpoon Quick Menu",
            },
        }

        for i = 1, 5 do
            table.insert(keys, {
                "<leader>" .. i,
                function()
                    require("harpoon"):list():select(i)
                end,
                desc = "Harpoon to File " .. i,
            })
        end

        for i = 1, 5 do
            table.insert(keys, {
                "<leader>h" .. i,
                function()
                    local harpoon = require("harpoon")
                    local list = harpoon:list()
                    if list.items[i] ~= nil then
                        list:replace_at(i)
                        print("Replaced Harpoon mark at " .. i)
                    else
                        print("Harpoon mark " .. i .. " doesn't exist. Use :lua require('harpoon'):list():append() first.")
                    end
                end,
                desc = "Harpoon: Replace file at slot " .. i,
            })
        end

        return keys
    end,
}

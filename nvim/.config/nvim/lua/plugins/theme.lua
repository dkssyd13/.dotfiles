local env = require("config.env")

if env.is_omarchy() then
	return dofile(env.omarchy_theme_file())
end

local color = "catppuccin-macchiato"

return {
	{
		"folke/tokyonight.nvim",
		lazy = true,
		opts = {},
		config = function()
			require("tokyonight").setup({
				styles = {
					comments = { italic = false },
				},
			})
		end,
	},
	{
		"sainnhe/gruvbox-material",
		lazy = true,
		config = function()
			vim.g.gruvbox_material_better_performance = 1
			vim.g.gruvbox_material_background = "soft"
			vim.g.gruvbox_material_enable_italic = 0
			vim.g.gruvbox_material_disable_italic_comment = 1
			vim.g.gruvbox_material_transparent_background = 1
		end,
	},
	{
		"nickkadutskyi/jb.nvim",
		lazy = true,
		opts = {},
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		config = function()
			require("catppuccin").setup({
				flavour = "macchiato",
				transparent_background = true,
				no_italic = true,
			})
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = color,
		},
	},
}

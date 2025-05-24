function ColorMyPencils(color)
	color = color or "jb"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	-- Set relative line number colors to orange
	vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#FF6B00" })
	vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#FF6B00" })
end

return {

	{
		"erikbackman/brightburn.vim",
	},

	{
		"folke/tokyonight.nvim",
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
        priority = 1000,
        lazy = false,
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
        lazy = false,
        priority = 1000,
        opts = {},
        config = function()
            ColorMyPencils()
        end,
    },
}

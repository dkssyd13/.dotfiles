local M = {}

local uv = vim.uv or vim.loop

function M.sysname()
	return uv.os_uname().sysname
end

function M.omarchy_theme_file()
	return (vim.env.HOME or vim.fn.expand("~")) .. "/.config/omarchy/current/theme/neovim.lua"
end

function M.is_omarchy()
	return M.sysname() == "Linux" and vim.fn.filereadable(M.omarchy_theme_file()) == 1
end

return M

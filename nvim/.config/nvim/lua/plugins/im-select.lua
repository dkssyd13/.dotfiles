local function is_ssh_session()
  return vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil
end

local function system_name()
  return vim.uv.os_uname().sysname
end

-- Switch to the English layout when leaving insert mode.
return {
  "keaising/im-select.nvim",
  event = "VeryLazy",
  cond = function()
    if is_ssh_session() then
      return false
    end
    local system = system_name()
    return (system == "Darwin" and vim.fn.executable("macism") == 1)
      or (system == "Linux" and vim.fn.executable("fcitx5-remote") == 1)
  end,
  config = function()
    if system_name() == "Darwin" then
      require("im_select").setup({
        default_command = "macism",
        default_im_select = "com.apple.keylayout.ABC",
      })
    else
      require("im_select").setup({
        default_command = "fcitx5-remote",
        default_im_select = "keyboard-us",
      })
    end
  end,
}

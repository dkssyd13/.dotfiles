local function is_ssh_session()
  return vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil
end

local function system_name()
  return (vim.uv or vim.loop).os_uname().sysname
end

return {
  "keaising/im-select.nvim",
  cond = function()
    if is_ssh_session() then
      return false
    end

    local system = system_name()
    return system == "Darwin" or (system == "Linux" and vim.fn.executable("fcitx5-remote") == 1)
  end,
  config = function()
    local system = system_name()
    local opts

    if system == "Darwin" then
      opts = {
        default_command = "macism",
        default_im_select = "com.apple.keylayout.ABC",
      }
    elseif system == "Linux" then
      opts = {
        default_command = "fcitx5-remote",
        default_im_select = "keyboard-us",
      }
    else
      return
    end

    require("im_select").setup(opts)
  end,
}

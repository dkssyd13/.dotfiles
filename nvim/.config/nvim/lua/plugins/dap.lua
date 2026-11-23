-- Python debugging: debugpy (Mason) through nvim-dap-python, UI by nvim-dap-ui.
local function start_or_continue()
  local dap = require("dap")
  if dap.session() then
    return dap.continue()
  end
  local buf = vim.api.nvim_get_current_buf()
  local root = require("config.python").root(buf)
  -- Like VS Code F5: launch.json configurations when the project has them,
  -- otherwise debug the current file right away.
  if vim.bo[buf].filetype ~= "python" or vim.uv.fs_stat(root .. "/.vscode/launch.json") then
    return dap.continue()
  end
  if vim.bo[buf].modified then
    vim.cmd.write()
  end
  dap.run({
    type = "python",
    request = "launch",
    name = "Python: current file",
    program = vim.api.nvim_buf_get_name(buf),
    cwd = root,
    console = "integratedTerminal",
    pythonPath = require("config.python").python(buf),
  })
end

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "mfussenegger/nvim-dap-python",
    "mason-org/mason.nvim",
  },
  -- stylua: ignore
  keys = {
    { "<leader>b", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
    { "<leader>cd", start_or_continue, desc = "Debug: start/continue" },
    { "<F5>", start_or_continue, desc = "Debug: start/continue" },
    { "<S-F5>", function() require("dap").terminate() end, desc = "Debug: stop" },
    { "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
    { "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
    { "<F12>", function() require("dap").step_out() end, desc = "Debug: step out" },
    { "<leader>D", function() require("dapui").toggle() end, desc = "Debug: toggle UI" },
  },
  config = function()
    local dap, dapui = require("dap"), require("dapui")

    -- The adapter runs from Mason's debugpy venv; the program runs with the
    -- project interpreter (config/python.lua: $VIRTUAL_ENV, nearest .venv, python3).
    local debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
    local dap_python = require("dap-python")
    dap_python.setup(vim.fn.executable(debugpy) == 1 and debugpy or "python3")
    dap_python.resolve_python = function()
      return require("config.python").python()
    end

    dapui.setup()
    -- Opens with the session; stays open afterwards so the output can be
    -- read. <Esc> or <leader>D closes it.
    dap.listeners.after.event_initialized.dapui = function()
      dapui.open()
    end

    vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
    local signs = {
      DapBreakpoint = { "\u{f111}", "DiagnosticError" },
      DapBreakpointCondition = { "\u{f059}", "DiagnosticWarn" },
      DapBreakpointRejected = { "\u{f05e}", "DiagnosticError" },
      DapLogPoint = { "\u{f05a}", "DiagnosticInfo" },
      DapStopped = { "\u{f061}", "DiagnosticWarn", "DapStoppedLine" },
    }
    for name, sign in pairs(signs) do
      vim.fn.sign_define(name, { text = sign[1], texthl = sign[2], linehl = sign[3], numhl = sign[3] })
    end
  end,
}

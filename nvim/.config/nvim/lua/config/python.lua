-- Project root and interpreter lookup shared by <leader>cr (run) and dap.
local M = {}

local root_markers = { ".venv", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" }

local function buf_dir(buf)
  local name = vim.api.nvim_buf_get_name(buf or 0)
  if name == "" then
    return vim.fn.getcwd()
  end
  return vim.fs.dirname(vim.fs.normalize(vim.fn.fnamemodify(name, ":p")))
end

---@param buf? integer
---@return string
function M.root(buf)
  return vim.fs.root(buf_dir(buf), root_markers) or vim.fn.getcwd()
end

--- Interpreter for the buffer's project: active $VIRTUAL_ENV, then the
--- nearest .venv above the file, then python3 on PATH.
---@param buf? integer
---@return string
function M.python(buf)
  local venv = vim.env.VIRTUAL_ENV
  if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
    return venv .. "/bin/python"
  end
  local dir = vim.fs.root(buf_dir(buf), ".venv")
  if dir and vim.fn.executable(dir .. "/.venv/bin/python") == 1 then
    return dir .. "/.venv/bin/python"
  end
  return vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or "python"
end

local last_term

--- Run the current file without the debugger in a bottom terminal (VS Code
--- "Run Without Debugging"). The previous run's terminal is replaced.
function M.run_file()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if vim.bo[buf].filetype ~= "python" or file == "" then
    vim.notify("Run: only Python files are supported", vim.log.levels.WARN)
    return
  end
  if vim.bo[buf].modified then
    vim.cmd.write()
  end
  if last_term and last_term:buf_valid() then
    local old = last_term.buf
    last_term:close()
    pcall(vim.api.nvim_buf_delete, old, { force = true })
  end
  last_term = Snacks.terminal.open({ M.python(buf), file }, {
    cwd = M.root(buf),
    auto_close = false,
    start_insert = true,
    auto_insert = false,
    win = { position = "bottom", height = 0.3 },
  })
end

return M

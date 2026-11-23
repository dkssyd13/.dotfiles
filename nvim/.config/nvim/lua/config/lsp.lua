-- LSP setup on Neovim 0.12 (vim.lsp.config / vim.lsp.enable). Server
-- definitions come from nvim-lspconfig's lsp/*.lua; only the servers listed
-- here are enabled, whatever else Mason has installed.
local M = {}

-- PyCharm-style refactors from pyrefly code actions. pyrefly 1.5 reports
-- every extract action with the bare kind "refactor.extract" (no
-- ".method"/".variable" sub-kind), so they are told apart by title:
--   "Extract into method `extracted_method` on `Calc`"   (inside a class)
--   "Extract into helper `extracted_function`"            (module function)
--   "Extract into variable `extracted_value`"
--   "Inline variable `x`" / "Inline call to `f`" / "Inline parameter `p`"
-- Title patterns are in order of preference; the first available is applied.
M.refactors = {
  extract_method = {
    kind = "refactor.extract",
    titles = { "^Extract into method", "^Extract into helper" },
    label = "extract method",
  },
  extract_variable = { kind = "refactor.extract", titles = { "^Extract into variable" }, label = "extract variable" },
  inline = { kind = "refactor.inline", titles = { "^Inline" }, label = "inline" },
}

-- pyrefly reads these from initializationOptions (keys without "python.") and
-- again through workspace/configuration (section "python"). Both must carry the
-- same tables, because a "pyrefly" object that omits a key resets that key.
local pyrefly_settings = {
  pyrefly = {
    typeCheckingMode = "default", -- VS Code: python.pyrefly.typeCheckingMode
    disableTypeErrors = false,
    disableLanguageServices = false,
  },
  analysis = {
    diagnosticMode = "openFilesOnly",
    autoImportCompletions = true,
    inlayHints = {
      variableTypes = true,
      functionReturnTypes = true,
      callArgumentNames = "all",
    },
  },
}

-- ruff reads its settings only from initializationOptions.settings. Lint
-- diagnostics are off (as in VS Code); select/ignore still decide what
-- source.fixAll.ruff fixes on save when the project has no ruff config.
local ruff_settings = {
  configurationPreference = "filesystemFirst",
  lineLength = 120,
  lint = {
    enable = false,
    select = { "E", "W", "F", "I", "B", "UP", "C4", "RUF100" },
    ignore = { "E501", "E731", "E741" },
  },
}

local servers = {
  pyrefly = {
    init_options = pyrefly_settings,
    settings = { python = pyrefly_settings },
  },
  ruff = {
    init_options = { settings = ruff_settings },
  },
  marksman = { filetypes = { "markdown" } },
  taplo = {},
  jsonls = {},
  lua_ls = {
    -- Neovim runtime for this config and other plugin code, unless the
    -- project brings its own .luarc.json.
    on_init = function(client)
      local folder = client.workspace_folders and client.workspace_folders[1]
      if
        folder and (vim.uv.fs_stat(folder.name .. "/.luarc.json") or vim.uv.fs_stat(folder.name .. "/.luarc.jsonc"))
      then
        return
      end
      client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
        runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } },
        workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME, "${3rd}/luv/library" } },
      })
    end,
    settings = {
      Lua = {
        diagnostics = { globals = { "Snacks" } },
        completion = { callSnippet = "Replace" },
        hint = { enable = true },
        telemetry = { enable = false },
      },
    },
  },
}
if vim.fn.executable("sourcekit-lsp") == 1 then
  servers.sourcekit = { filetypes = { "swift", "objc", "objcpp" } }
end

local TIMEOUT = 2000

local function whole_buffer_range(buf)
  local last = vim.api.nvim_buf_line_count(buf) - 1
  local text = vim.api.nvim_buf_get_lines(buf, last, last + 1, false)[1] or ""
  return { start = { line = 0, character = 0 }, ["end"] = { line = last, character = #text } }
end

---@param client vim.lsp.Client
---@param buf integer
---@param params table
---@return lsp.CodeAction[]
local function request_actions(client, buf, params)
  local response = client:request_sync("textDocument/codeAction", params, TIMEOUT, buf)
  return response and response.result or {}
end

---@param client vim.lsp.Client
---@param buf integer
---@param action lsp.CodeAction
local function apply(client, buf, action)
  if not action.edit and client:supports_method("codeAction/resolve") then
    local resolved = client:request_sync("codeAction/resolve", action, TIMEOUT, buf)
    action = resolved and resolved.result or action
  end
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end
  if type(action.command) == "table" then
    client:exec_cmd(action.command, { bufnr = buf })
  end
end

--- Request code actions of exactly `kind` for the whole buffer from one
--- server and apply them synchronously (used on save and for <leader>oi).
---@param kind string
---@param opts? {bufnr?: integer, name?: string, silent?: boolean}
function M.apply_action(kind, opts)
  opts = opts or {}
  local buf = opts.bufnr or vim.api.nvim_get_current_buf()
  local name = opts.name or "ruff"
  local clients = vim.lsp.get_clients({ bufnr = buf, name = name })
  if #clients == 0 and not opts.silent then
    vim.notify(("%s: %s is not attached"):format(kind, name), vim.log.levels.WARN)
  end
  for _, client in ipairs(clients) do
    local actions = request_actions(client, buf, {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      range = whole_buffer_range(buf),
      context = { only = { kind }, diagnostics = {}, triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked },
    })
    for _, action in ipairs(actions) do
      if action.kind == kind then
        apply(client, buf, action)
      end
    end
  end
end

-- Same normalisation as vim.lsp.buf.code_action() for a visual selection.
local function selection_range(buf, mode)
  local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
  local srow, scol, erow, ecol = s[2], s[3], e[2], e[3]
  if srow == erow and ecol < scol then
    scol, ecol = ecol, scol
  elseif erow < srow then
    srow, erow, scol, ecol = erow, srow, ecol, scol
  end
  if mode == "V" then
    scol = 1
    ecol = #vim.api.nvim_buf_get_lines(buf, erow - 1, erow, true)[1]
  end
  return { srow, scol - 1 }, { erow, ecol - 1 }
end

--- Apply the preferred pyrefly refactor (see M.refactors) for the visual
--- selection, or the cursor position in normal mode.
---@param name "extract_method"|"extract_variable"|"inline"
function M.refactor(name)
  local spec = M.refactors[name]
  local buf = vim.api.nvim_get_current_buf()
  local mode = vim.api.nvim_get_mode().mode
  local sel_start, sel_end
  if mode == "v" or mode == "V" then
    sel_start, sel_end = selection_range(buf, mode)
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  end

  local best, best_rank = {}, math.huge
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, method = "textDocument/codeAction" })) do
    local params = sel_start and vim.lsp.util.make_given_range_params(sel_start, sel_end, buf, client.offset_encoding)
      or vim.lsp.util.make_range_params(0, client.offset_encoding)
    params.context =
      { only = { spec.kind }, diagnostics = {}, triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked }
    for _, action in ipairs(request_actions(client, buf, params)) do
      local kind = action.kind or ""
      if kind == spec.kind or vim.startswith(kind, spec.kind .. ".") then
        for rank, pattern in ipairs(spec.titles) do
          if action.title:match(pattern) then
            if rank < best_rank then
              best, best_rank = {}, rank
            end
            if rank == best_rank then
              table.insert(best, { client = client, action = action })
            end
            break
          end
        end
      end
    end
  end

  if #best == 0 then
    vim.notify("No " .. spec.label .. " refactoring here", vim.log.levels.INFO)
  elseif #best == 1 then
    apply(best[1].client, buf, best[1].action)
  else
    vim.ui.select(best, {
      prompt = spec.label,
      format_item = function(item)
        return item.action.title
      end,
    }, function(item)
      if item then
        apply(item.client, buf, item.action)
      end
    end)
  end
end

local function hover()
  if package.loaded.dap and require("dap").session() then
    require("dapui").eval()
  else
    vim.lsp.buf.hover({ border = "rounded" })
  end
end

function M.setup()
  vim.diagnostic.config({
    virtual_text = false,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded", source = "if_many" },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "\u{f057} ",
        [vim.diagnostic.severity.WARN] = "\u{f071} ",
        [vim.diagnostic.severity.HINT] = "\u{f0eb} ",
        [vim.diagnostic.severity.INFO] = "\u{f05a} ",
      },
    },
  })

  -- One position encoding for every server (pyrefly only does UTF-16).
  local capabilities = require("blink.cmp").get_lsp_capabilities({ general = { positionEncodings = { "utf-16" } } })
  vim.lsp.config("*", { capabilities = capabilities })
  for name, config in pairs(servers) do
    vim.lsp.config(name, config)
  end
  vim.lsp.enable(vim.tbl_keys(servers))
  vim.lsp.inlay_hint.enable(true)

  local group = vim.api.nvim_create_augroup("user_lsp", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client then
        return
      end
      if client.name == "ruff" then
        client.server_capabilities.hoverProvider = false -- pyrefly owns hover
      end
      local function bmap(method, lhs, rhs, desc)
        if client:supports_method(method, ev.buf) then
          vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
        end
      end
      -- stylua: ignore start
      bmap("textDocument/definition", "gd", function() Snacks.picker.lsp_definitions() end, "Go to definition")
      bmap("textDocument/references", "gr", function() Snacks.picker.lsp_references() end, "References")
      bmap("textDocument/references", "gR", "<cmd>Trouble lsp_references toggle<cr>", "References (Trouble)")
      bmap("textDocument/implementation", "gi", function() Snacks.picker.lsp_implementations() end, "Go to implementation")
      bmap("textDocument/hover", "K", hover, "Hover (debug: evaluate)")
      -- stylua: ignore end
    end,
  })

  -- VS Code "editor.codeActionsOnSave" for Python: organize imports, then fix all.
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    callback = function(ev)
      if vim.bo[ev.buf].filetype == "python" then
        M.apply_action("source.organizeImports.ruff", { bufnr = ev.buf, silent = true })
        M.apply_action("source.fixAll.ruff", { bufnr = ev.buf, silent = true })
      end
    end,
  })
end

return M

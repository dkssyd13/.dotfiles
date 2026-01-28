return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = {
      enabled = false,
    },
    diagnostics = {
      virtual_text = false,
    },
    servers = {
      ["*"] = {
        keys = {
          { "<leader>rn", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
        },
      },
      ruff = {
        keys = {
          {
            "<leader>oi",
            LazyVim.lsp.action["source.organizeImports"],
            desc = "Organize Imports",
          },
        },
        init_options = {
          settings = {
            lint = {
              ignore = { "F403", "F405" },
            },
          },
        },
      },
      basedpyright = {
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
              autoImportCompletions = true,
              diagnosticSeverityOverrides = {
                -- unused 관련 끄기
                reportUnusedVariable = "none",
                reportUnusedImport = "none",
                reportUnusedFunction = "none",
                reportUnusedClass = "none",
                -- access 관련 끄기
                reportOptionalMemberAccess = "none",
                -- 타입 관련 끄기
                reportAny = "none",
                reportUnknownParameterType = "none",
                reportReturnType = "none",
              },
            },
          },
        },
      },
      sourcekit = {
        cmd = {
          "sourcekit-lsp",
        },
        filetypes = { "swift", "objective-c", "objective-cpp" },
        root_dir = require("lspconfig.util").root_pattern("Package.swift", ".git", "compile_commands.json"),
      },
    },
  },
  setup = {
    basedpyright = function()
      local util = require("lspconfig.util")

      require("lspconfig").basedpyright.setup({
        root_dir = function(fname)
          -- 기본 패턴으로 찾기 시도
          local root = util.root_pattern("pyrightconfig.json", "pyproject.toml", "setup.py", ".git")(fname)

          -- 못 찾으면 현재 디렉토리
          return root or vim.fn.getcwd()
        end,
      })
      return true -- 이 부분이 중요!
    end,
  },
}

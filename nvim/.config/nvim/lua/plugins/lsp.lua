return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = {
      enabled = true,
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
        configurationPreference = "filesystemFirst",
        lineLength = 120,

        lint = {
          select = {
            "E",
            "W",
            "F",
            "I",
            "B",
            "UP",
            "C4",
            "RUF100",
          },

          ignore = {
            "E501",
            "E731",
            "E741",
          },
        },
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
              -- ignore = { "F403", "F405" },
            },
          },
        },
      },
      basedpyright = {
        settings = {
          basedpyright = {
            analysis = {
              disableOrganizeImports = true,
              typeCheckingMode = "standard",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
              autoImportCompletions = true,
              diagnosticSeverityOverrides = {
                reportUnusedImport = "none",
                reportUnusedVariable = "none",
                reportDuplicateImport = "none",
                reportWildcardImportFromLibrary = "none",
                reportImplicitStringConcatenation = false,
                reportUnknownMemberType = false,
                reportUnknownVariableType = false,
                reportUnknownParameterType = false,
                reportUnknownArgumentType = false,
                reportMissingTypeStubs = "none",
                reportAny = false,
                reportMissingParameterType = false,
                reportUnusedCallResult = false,
                reportUnknownLambdaType = false,
              },
              inlayHints = {
                callArgumentNames = true,
                functionReturnTypes = true,
                variableTypes = true,
                genericTypes = false,
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

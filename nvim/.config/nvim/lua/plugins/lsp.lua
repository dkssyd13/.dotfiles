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
                -- 타입 관련만 유지
                reportAny = "none",
                reportUnknownParameterType = "none",
              },
            },
          },
        },
      },
    },
  },
}

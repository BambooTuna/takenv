return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              pythonPath = vim.fn.system("which python"):gsub("\n", ""),
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
                typeCheckingMode = "basic",
                exclude = { "**/node_modules", "**/__pycache__", "**/.*", "**/dist", "**/build" },
              },
            },
          },
        },
      },
    },
  },
}


-- TypeScript/JavaScript設定
-- vtslsの無限ロード問題のため、tsserverを使用
return {
  -- ESLintとPrettierのサポートを追加
  { import = "lazyvim.plugins.extras.linting.eslint" },
  { import = "lazyvim.plugins.extras.formatting.prettier" },

  -- tsserver設定
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsserver = {
          -- tsconfig.jsonを基準にルートディレクトリを検出
          root_dir = function(...)
            return require("lspconfig.util").root_pattern("tsconfig.json")(...)
          end,
          -- プロジェクト外の単一ファイルでは動作させない
          single_file_support = false,
          settings = {
            -- TypeScript設定
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            -- JavaScript設定
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },
        -- vtslsを明示的に無効化
        vtsls = false,
      },
    },
  },
}

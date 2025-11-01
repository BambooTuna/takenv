-- TypeScript/JavaScript設定
-- LazyVimフレームワークをバイパスしてvtslsを直接起動
return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")

      -- on_attachコールバックでLSPキーマップを設定
      local on_attach = function(client, bufnr)
        local opts = { buffer = bufnr, silent = true }

        -- 定義ジャンプ
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        -- 型定義ジャンプ
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        -- 実装ジャンプ
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        -- 参照検索
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        -- hover
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        -- シグネチャヘルプ
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
        -- リネーム
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        -- コードアクション
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
      end

      -- vtslsを直接setup（LazyVimのoptsフレームワークを使わない）
      lspconfig.vtsls.setup({
        -- on_attachでキーマップを設定
        on_attach = on_attach,
        -- root_dir検出
        root_dir = function(fname)
          return util.root_pattern("tsconfig.json", "package.json")(fname)
            or util.root_pattern(".git")(fname)
        end,
        -- 単一ファイルサポート無効
        single_file_support = false,
        -- 自動起動
        autostart = true,
        -- 設定
        settings = {
          -- TypeScript設定
          typescript = {
            tsserver = {
              maxTsServerMemory = 4096, -- メモリ上限を4GBに設定
            },
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
          -- vtsls固有設定
          vtsls = {
            experimental = {
              completion = {
                enableServerSideFuzzyMatch = true,
              },
            },
          },
        },
      })
    end,
  },
}

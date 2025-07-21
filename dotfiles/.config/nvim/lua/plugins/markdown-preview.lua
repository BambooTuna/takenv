return {
  -- markdownでのconceal機能を無効化
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = function(_, opts)
      opts.code = {
        sign = false,
        width = "full",
        right_pad = 1,
        style = "normal",
        position = "left",
        disable_background = { "diff" },
        border = "thin",
        above = "▄",
        below = "▀",
        highlight = "RenderMarkdownCode",
        highlight_inline = "RenderMarkdownCodeInline",
      }
    end,
  },
  -- マークダウンファイルでのconceal設定を無効化
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.highlight = opts.highlight or {}
      opts.highlight.additional_vim_regex_highlighting = { "markdown" }
    end,
  },
}

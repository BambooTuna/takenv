return {
  "kdheepak/lazygit.nvim",
  keys = {
    { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
  },
  config = function()
    vim.g.lazygit_floating_window_winblend = 0
    vim.g.lazygit_floating_window_scaling_factor = 0.9
    vim.g.lazygit_floating_window_corner_chars = { "╭", "╮", "╰", "╯" }
    vim.g.lazygit_floating_window_use_plenary = 0
    vim.g.lazygit_use_neovim_remote = 1
    -- lazygitのターミナルでjキーの応答性を改善
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*",
      callback = function(event)
        local buf_name = vim.api.nvim_buf_get_name(event.buf)
        -- lazygitバッファかどうかを確認
        if string.match(buf_name, "lazygit") then
          -- 元のtimeoutlenを保存
          local original_timeoutlen = vim.o.timeoutlen
          
          -- lazygitのターミナルでtimeoutlenを短縮してjキーの反応を改善
          vim.opt_local.timeoutlen = 100
          -- さらに、jjキーマップを無効化してjキーの応答を即座にする
          vim.keymap.set("t", "j", "j", { buffer = event.buf, silent = true, nowait = true })
          -- lazygitのタブ移動をAlt+h/lで行う
          vim.keymap.set("t", "<A-h>", "[", { buffer = event.buf, silent = true })
          vim.keymap.set("t", "<A-l>", "]", { buffer = event.buf, silent = true })
          
          -- lazygitターミナルが閉じられたときにtimeoutlenを元に戻す
          vim.api.nvim_create_autocmd("BufWinLeave", {
            buffer = event.buf,
            callback = function()
              vim.o.timeoutlen = original_timeoutlen
            end,
            once = true,
          })
        end
      end,
    })
  end,
}

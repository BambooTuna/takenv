-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- lazygit ターミナル (snacks.nvim 標準の <leader>gg/<leader>gG) でも、
-- config/keymaps.lua のターミナルモード `jj` 脱出キーマップと干渉して
-- j キーの入力が timeoutlen 分だけ遅延してしまう。
-- lazygit 内では j/k がカーソル移動の主要キーなので、
-- lazygit ターミナルバッファに限り timeoutlen を短縮し、
-- バッファを離れたら元に戻す。
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function(event)
    local buf_name = vim.api.nvim_buf_get_name(event.buf)
    -- snacks のターミナルバッファ名は `term://…lazygit` のような形式になる
    if string.match(buf_name, "lazygit") then
      -- 元の timeoutlen を保存
      local original_timeoutlen = vim.o.timeoutlen

      -- lazygit のターミナルで timeoutlen を短縮して j キーの反応を改善
      vim.opt_local.timeoutlen = 100

      -- lazygit ターミナルが閉じられたときに timeoutlen を元に戻す
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

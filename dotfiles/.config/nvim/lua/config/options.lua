-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.snacks_animate = false

-- クリップボード設定
vim.opt.clipboard = "unnamedplus"

-- SSH接続時のみOSC52を使用（リモート環境でのクリップボード同期）
-- ローカルmac環境ではpbcopy/pbpasteを使用
local function is_ssh()
  return vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_CLIENT ~= nil or vim.env.SSH_TTY ~= nil
end

if is_ssh() then
  local function paste()
    return {
      vim.fn.split(vim.fn.getreg(""), "\n"),
      vim.fn.getregtype(""),
    }
  end

  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = paste,
      ["*"] = paste,
    },
  }
end

-- ターミナルのデフォルトシェルをzshに設定
vim.o.shell = "zsh"

vim.opt.termguicolors = true

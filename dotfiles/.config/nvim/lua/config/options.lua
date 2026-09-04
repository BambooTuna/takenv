-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.snacks_animate = false

-- クリップボード設定
vim.opt.clipboard = "unnamedplus"

-- SSH接続時 / herdr セッション内では OSC52 を使ってクライアント端末に同期
-- ローカル mac 環境ではデフォルト provider (pbcopy/pbpaste) に任せる
-- (herdr --remote で入ると SSH_* は伝搬しないので HERDR_ENV でも拾う)
local function is_remote()
  return vim.env.SSH_CONNECTION ~= nil
    or vim.env.SSH_CLIENT ~= nil
    or vim.env.SSH_TTY ~= nil
    or vim.env.HERDR_ENV ~= nil
end

if is_remote() then
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

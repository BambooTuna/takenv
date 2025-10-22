-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.snacks_animate = false

-- クリップボード設定（SSH/Docker越しでも動作するようOSC52を使用）
vim.opt.clipboard = "unnamedplus"

-- OSC52を明示的に設定（リモート環境でのクリップボード同期）
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}

-- ターミナルのデフォルトシェルをzshに設定
vim.o.shell = "zsh"

vim.opt.termguicolors = true

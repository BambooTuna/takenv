-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- ターミナルモード
vim.keymap.set("t", "<esc>", "<esc>", { desc = "Escape terminal mode (disabled)" })
vim.keymap.set("t", "jj", [[<C-\><C-n>]], { desc = "ターミナルモードからノーマルモードへ移行" })

-- ビジュアルモード
-- エディター
vim.keymap.set("v", "d", '"_d', { desc = "Delete without yanking" })
vim.keymap.set("v", "dd", '"_dd', { desc = "Delete line without yanking" })
vim.keymap.set("v", "D", '"_D', { desc = "Delete to end of line without yanking" })
vim.keymap.set("v", "x", '"_x', { desc = "Delete character without yanking" })
vim.keymap.set("v", "s", '"_s', { desc = "Substitute without yanking" })

-- クイック移動
vim.keymap.set("v", "<S-h>", "0", { desc = "Cursor to start" })
vim.keymap.set("v", "<S-l>", "$", { desc = "Cursor to end" })

-- 行の移動
vim.keymap.set("v", "J", ":move '>+1<CR>gv-gv", { desc = "Move lines of code up" })
vim.keymap.set("v", "K", ":move '<-2<CR>gv-gv", { desc = "Move lines of code down" })

-- インデント操作（選択を維持）
vim.keymap.set("v", "<Tab>", ">gv", { desc = "Indent" })
vim.keymap.set("v", "<S-Tab>", "<gv", { desc = "Dedent" })

-- インサートモード
vim.keymap.set("i", "jj", "<esc>", { desc = "Exit insert mode" })

-- 方向キーの制限
vim.keymap.set("i", "<Left>", "<Nop>", { desc = "Disable left arrow" })
vim.keymap.set("i", "<Down>", "<Nop>", { desc = "Disable down arrow" })
vim.keymap.set("i", "<Up>", "<Nop>", { desc = "Disable up arrow" })
vim.keymap.set("i", "<Right>", "<Nop>", { desc = "Disable right arrow" })

-- Ctrl + hjkl で移動
vim.keymap.set("i", "<C-h>", "<Left>", { desc = "Move left" })
vim.keymap.set("i", "<C-j>", "<Down>", { desc = "Move down" })
vim.keymap.set("i", "<C-k>", "<Up>", { desc = "Move up" })
vim.keymap.set("i", "<C-l>", "<Right>", { desc = "Move right" })

-- エディター
vim.keymap.set("i", "<C-v>", "<C-r>+", { desc = "Paste from clipboard" })

-- インデント操作
vim.keymap.set("i", "<Tab>", "<C-t>", { desc = "Indent" })
vim.keymap.set("i", "<S-Tab>", "<C-d>", { desc = "Dedent" })

-- ノーマルモード
-- 方向キーの制限
vim.keymap.set("n", "<Left>", "<Nop>", { desc = "Disable left arrow" })
vim.keymap.set("n", "<Down>", "<Nop>", { desc = "Disable down arrow" })
vim.keymap.set("n", "<Up>", "<Nop>", { desc = "Disable up arrow" })
vim.keymap.set("n", "<Right>", "<Nop>", { desc = "Disable right arrow" })

-- クイック移動
vim.keymap.set("n", "<S-h>", "0", { desc = "Cursor to start" })
vim.keymap.set("n", "<S-l>", "$", { desc = "Cursor to end" })

-- バッファー切り替え
vim.keymap.set("n", "<A-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<A-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- エディター
vim.keymap.set("n", "d", '"_d', { desc = "Delete without yanking" })
vim.keymap.set("n", "dd", '"_dd', { desc = "Delete line without yanking" })
vim.keymap.set("n", "D", '"_D', { desc = "Delete to end of line without yanking" })
vim.keymap.set("n", "x", '"_x', { desc = "Delete character without yanking" })
vim.keymap.set("n", "s", '"_s', { desc = "Substitute without yanking" })

-- 単語選択
vim.keymap.set("n", "<S-j>", "viw", { desc = "Word selection" })

-- バッファー削除
vim.keymap.set("n", "<leader>dd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- 折りたたみ
vim.keymap.set("n", "<leader>z", "za", { silent = true, desc = "Toggle fold" })
vim.keymap.set("n", "<leader>Z", "zA", { silent = true, desc = "Toggle fold recursively" })
vim.keymap.set("n", "<leader>zr", "zR", { silent = true, desc = "Open all folds" })
vim.keymap.set("n", "<leader>zm", "zM", { silent = true, desc = "Close all folds" })

-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- diff の削除側フィラー行の斜め線(╱)をやめて背景色(赤)のみにする
vim.opt.fillchars:append({ diff = " " })

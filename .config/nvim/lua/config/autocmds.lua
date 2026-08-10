-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- WezTerm のペイン切替(nvim ⇔ Claude Code 等)で nvim がフォーカス中かを示す:
-- フォーカス中だけカーソル行ハイライトを表示する
local focus_grp = vim.api.nvim_create_augroup("focus_indicator", { clear = true })
local saved_cursorline
vim.api.nvim_create_autocmd("FocusLost", {
  group = focus_grp,
  callback = function()
    local current = vim.api.nvim_get_hl(0, { name = "CursorLine" })
    if next(current) then
      saved_cursorline = current
    end
    vim.api.nvim_set_hl(0, "CursorLine", {})
  end,
})
vim.api.nvim_create_autocmd("FocusGained", {
  group = focus_grp,
  callback = function()
    if saved_cursorline then
      vim.api.nvim_set_hl(0, "CursorLine", saved_cursorline)
    end
  end,
})

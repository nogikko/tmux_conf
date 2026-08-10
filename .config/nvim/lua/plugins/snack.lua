local exclude = {
  "**/node_modules/**",
  "**/.git/**",
  "**/dist/**",
  "**/build/**",
  "**/.next/**",
  "**/.turbo/**",
  "**/.cache/**",
  "**/.dart_tool/**",
  "**/ios/Pods/**",
  "**/coverage/**",
}

-- gitignore 対象(クローンした子リポジトリ配下)が NonText で薄く表示されるのを通常色に戻す
local function fix_ignored_hl()
  vim.api.nvim_set_hl(0, "SnacksPickerPathIgnored", { link = "SnacksPickerFile" })
end

return {
  {
    "folke/snacks.nvim",
    init = function()
      fix_ignored_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = fix_ignored_hl })
    end,
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true, -- .env などの隠しファイルも含める
            ignored = true, -- .gitignore されているクローン配下も含める
            exclude = exclude,
          },
          grep = {
            hidden = true,
            ignored = true,
            exclude = exclude,
          },
          explorer = {
            hidden = true,
            ignored = true,
            exclude = exclude,
          },
        },
      },
    },
  },
}

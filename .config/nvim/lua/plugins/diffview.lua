-- PR やブランチの差分をファイルツリー + 左右分割で表示する
return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    opts = {},
  },
}

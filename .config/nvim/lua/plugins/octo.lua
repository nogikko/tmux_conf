-- octo は gh 実行時の環境変数を許可リスト方式で絞っていて GH_TOKEN を渡さない
-- (GITHUB_TOKEN のみ)。認証を GH_TOKEN に頼っているため明示的に渡す
return {
  {
    "pwntester/octo.nvim",
    opts = {
      gh_env = { GH_TOKEN = vim.env.GH_TOKEN },
    },
  },
}

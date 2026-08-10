-- Claude Code は WezTerm のペインで起動し、nvim は連携（WebSocket サーバ）だけを担う。
-- nvim 内にターミナルを作らせないため provider を "none" にする。
return {
  "coder/claudecode.nvim",
  -- LazyVim の extra は keys 遅延のため、キーを押すまで setup が走らず WebSocket サーバが立たない。
  -- WezTerm 側の claude から /ide で発見できるよう、nvim 起動時に auto_start させる。
  lazy = false,
  opts = {
    terminal = {
      provider = "none",
    },
  },
  keys = {
    -- nvim 内ターミナルの表示制御が前提のキーは無効化する（provider="none" では no-op）
    { "<leader>ac", false },
    { "<leader>af", false },
    { "<leader>ar", false },
    { "<leader>aC", false },
    -- 連携系（WebSocket 経由）はそのまま使える: <leader>ab / <leader>as / <leader>aa / <leader>ad
  },
}

-- diff(diffview 等)の追加/削除の背景色をはっきりした緑・赤にする。
-- LazyVim は ColorScheme イベントを発火させずにテーマを適用するため、
-- autocmd ではなく tokyonight の on_highlights フックで上書きする
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      on_highlights = function(hl)
        hl.DiffAdd = { bg = "#1e4620" } -- 追加行: 緑
        hl.DiffDelete = { bg = "#4b1d22" } -- 削除行: 赤
        hl.DiffChange = { bg = "#20344d" } -- 変更行: 青(控えめ)
        hl.DiffText = { bg = "#38598c", bold = true } -- 変更行内の変更箇所: 強調
        -- WezTerm のカーソル色(金)と揃えて、アクティブペインの目印にする
        hl.Cursor = { bg = "#d4a938", fg = "#000000" }
        -- ウィンドウ境界線(explorer と編集画面の間など)をはっきりさせる。
        -- WezTerm のペイン境界(金)と区別できるよう青にする
        hl.WinSeparator = { fg = "#7aa2f7" }
        -- カーソル行をデフォルトより少しはっきりさせる(フォーカス中のみ表示される)
        hl.CursorLine = { bg = "#33405f" }
      end,
    },
  },
}

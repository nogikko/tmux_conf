local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- キーバインド読み込み
config.keys = require("keybinds").keys
config.key_tables = require("keybinds").key_tables

-- 初期キーバインド無効化
config.disable_default_key_bindings = true

-- OS の IME を使い、未確定文字列を入力位置にインライン表示する
-- （無効だと日本語の未確定文字列がウィンドウ左下に出てしまう）
config.use_ime = true

-- leaderキー ctrl+j
config.leader = { key = "j", mods = "CTRL", timeout_milliseconds = 2000}
config.automatically_reload_config = true
config.font = wezterm.font_with_fallback({
 { family = "JetBrains Mono", weight = "Bold"},
 { family = "Hiragino Sans", weight = 400}})
config.font_size = 13.0
config.window_background_opacity = 0.85
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"
config.show_tabs_in_tab_bar = true
--config.hide_tab_bar_if_only_one_tab = true
config.window_frame = {  
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}
config.window_background_gradient = {
   colors = { "#000000" },
}
-- ペインは暗転させず、アクティブペインは目立つカーソルで見分ける
config.inactive_pane_hsb = {
   saturation = 1.0,
   brightness = 1.0,
}
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 600
-- タブバーの+を消す
config.show_new_tab_button_in_tab_bar = false

-- タブの閉じるボタンを非表示 nightlyでのみ使用可能
-- config.show_close_tab_button_in_tabs = false

-- タブ同士の境界線を非表示
config.colors = {
   tab_bar = {
     inactive_tab_edge = "none",
   },
   -- ペイン分割の境界線色(アクティブタブと同系色)
   split = "#d4a938",
   -- アクティブペインの位置を示す目立つカーソル
   cursor_bg = "#d4a938",
   cursor_fg = "#000000",
   cursor_border = "#d4a938",
}

-- `パス:行番号` をクリックで起動中の nvim（/tmp/nvim.sock）で開く
config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- 行番号付き: 絶対パス / ~パス / 相対パス（相対はスラッシュ＋拡張子必須。localhost:3000 等の誤マッチ防止）
for _, re in ipairs({
  [[(/[\w./_@-]+):(\d+)]],
  [[(~/[\w./_@-]+):(\d+)]],
  [[((?:[\w.@_-]+/)+[\w.@_-]+\.[A-Za-z0-9]+):(\d+)]],
}) do
  table.insert(config.hyperlink_rules, { regex = re, format = 'nvim-open://$1:$2' })
end
-- 行番号なし: 拡張子必須。実在チェックは open-uri ハンドラ側で行うので誤マッチは無害
for _, re in ipairs({
  [[(/[\w./_@-]+\.[A-Za-z0-9]+)]],
  [[(~/[\w./_@-]+\.[A-Za-z0-9]+)]],
  [[((?:[\w.@_-]+/)+[\w.@_-]+\.[A-Za-z0-9]+)]],
}) do
  table.insert(config.hyperlink_rules, { regex = re, format = 'nvim-open://$1' })
end

-- 選択範囲があればコピーして選択解除（右クリック用）。エラー時はログに残す
local copy_selection_on_right_click = wezterm.action_callback(function(window, pane)
  local ok, err = pcall(function()
    local sel = window:get_selection_text_for_pane(pane)
    if sel and sel ~= '' then
      window:perform_action(
        wezterm.action.Multiple {
          wezterm.action.CopyTo 'ClipboardAndPrimarySelection',
          wezterm.action.ClearSelection,
        },
        pane
      )
    end
  end)
  if not ok then
    wezterm.log_error('copy_selection_on_right_click: ' .. tostring(err))
  end
end)

-- Cmd+クリックでリンクを開く（2つ目は nvim/tmux などマウス捕捉アプリ内でも効かせるための mouse_reporting=true 版）
config.mouse_bindings = {
  -- Down は握りつぶす（既定の選択開始やアプリへの転送を防ぐ）
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'SUPER',
    action = wezterm.action.Nop,
  },
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'SUPER',
    mouse_reporting = true,
    action = wezterm.action.Nop,
  },
  -- Up でリンクを開く
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'SUPER',
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'SUPER',
    mouse_reporting = true,
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
  -- 右クリックで選択範囲をクリップボードにコピー（コピー後は選択解除）
  -- nvim/tmux などマウス捕捉アプリ内では Shift+右クリック
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = copy_selection_on_right_click,
  },
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'SHIFT',
    action = copy_selection_on_right_click,
  },
  -- Claude Code / nvim / tmux などマウス捕捉アプリ内でも右クリックコピーを効かせる
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    mouse_reporting = true,
    action = copy_selection_on_right_click,
  },
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'SHIFT',
    mouse_reporting = true,
    action = copy_selection_on_right_click,
  },
}

local function file_exists(p)
  local f = io.open(p, 'r')
  if f then
    f:close()
    return true
  end
  return false
end

wezterm.on('open-uri', function(window, pane, uri)
  local path, line = uri:match('^nvim%-open://(.+):(%d+)$')
  if not path then
    -- 行番号なしの nvim-open リンク
    path = uri:match('^nvim%-open://(.+)$')
  end
  if not path then
    -- Claude Code 等が OSC 8 で埋め込む file:// リンクも nvim で開く
    -- （画像や PDF 等のバイナリは既定アプリに任せる）
    local fpath = uri:match('^file://[^/]*(/[^#?]+)')
    if fpath then
      fpath = fpath:gsub('%%(%x%x)', function(h)
        return string.char(tonumber(h, 16))
      end)
      local binary_exts = {
        png = true, jpg = true, jpeg = true, gif = true, webp = true,
        heic = true, ico = true, svg = true, pdf = true, zip = true,
        gz = true, dmg = true, xlsx = true, docx = true, pptx = true,
        mp4 = true, mov = true, mp3 = true,
      }
      local ext = fpath:match('%.([A-Za-z0-9]+)$')
      if not (ext and binary_exts[ext:lower()]) then
        path = fpath
        line = uri:match('#L?(%d+)$')
      end
    end
  end
  if not path then
    return -- 上記以外の URI（https 等）は既定の動作（ブラウザ等）に任せる
  end
  -- ~ をホームディレクトリに展開する
  if path:match('^~/') then
    path = wezterm.home_dir .. path:sub(2)
  end
  -- 相対パスはペインのカレントディレクトリで解決する
  if not path:match('^/') then
    local cwd = pane:get_current_working_dir()
    if not (cwd and cwd.file_path) then
      return false
    end
    local base = cwd.file_path:gsub('/$', '')
    local resolved = base .. '/' .. path
    if not file_exists(resolved) then
      -- cwd 直下に無ければ1階層下（ai-fc-harness の子リポジトリ等）を探す
      resolved = nil
      local ok, entries = pcall(wezterm.read_dir, base)
      for _, entry in ipairs(ok and entries or {}) do
        local candidate = entry .. '/' .. path
        if file_exists(candidate) then
          resolved = candidate
          break
        end
      end
      if not resolved then
        return false
      end
    end
    path = resolved
  end
  -- 存在しないパス（誤マッチ・解決失敗）は何もしない
  if not file_exists(path) then
    return false
  end
  -- ソケットが生きていれば既存の nvim で開き、いなければペインを分割して nvim を起動する
  local alive = wezterm.run_child_process {
    '/opt/homebrew/bin/nvim', '--server', '/tmp/nvim.sock', '--remote-expr', '1',
  }
  if alive then
    local plus_line = line and ('+' .. line .. ' ') or ''
    wezterm.background_child_process {
      '/opt/homebrew/bin/nvim', '--server', '/tmp/nvim.sock',
      '--remote-send',
      ('<C-\\><C-n>:drop %s%s<CR>'):format(plus_line, path),
    }
  else
    os.remove('/tmp/nvim.sock') -- 残骸ソケットがあると --listen が失敗するため掃除
    local args = { '/opt/homebrew/bin/nvim', '--listen', '/tmp/nvim.sock' }
    if line then
      table.insert(args, '+' .. line)
    end
    table.insert(args, path)
    window:perform_action(
      wezterm.action.SplitHorizontal { args = args },
      pane
    )
  end
  return false -- 既定のオープン動作をキャンセル
end)

-- アクティブタブに色をつける
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
   local background = "#5c6d74"
   local foreground = "#FFFFFF"

   if tab.is_active then
     background = "#ae8b2d"
     foreground = "#FFFFFF"
   end

   local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "

   return {
     { Background = { Color = background } },
     { Foreground = { Color = foreground } },
     { Text = title },
   }
 end)

return config

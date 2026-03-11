local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- キーバインド読み込み
config.keys = require("keybinds").keys
config.key_tables = require("keybinds").key_tables

-- 初期キーバインド無効化
config.disable_default_key_bindings = true

-- leaderキー ctrl+j
config.leader = { key = "j", mods = "CTRL", timeout_milliseconds = 2000}
config.automatically_reload_config = true
config.font.wezterm = wezterm.font_with_fallback({
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
config.inactive_pane_hsb = {
   saturation = 1.0,
   brightness = 1.0,
}
-- タブバーの+を消す
config.show_new_tab_button_in_tab_bar = false

-- タブの閉じるボタンを非表示 nightlyでのみ使用可能
-- config.show_close_tab_button_in_tabs = false

-- タブ同士の境界線を非表示
config.colors = {
   tab_bar = {
     inactive_tab_edge = "none",
   },
}

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

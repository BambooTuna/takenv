local wezterm = require("wezterm")

-- herdr の prefix (Ctrl+a) に続けてキーを送る
local function herdr(key)
	return wezterm.action.Multiple({
		wezterm.action.SendKey({ key = "a", mods = "CTRL" }),
		wezterm.action.SendKey(key),
	})
end

wezterm.on("trigger-nvim-with-scrollback", function(window, pane)
	local scrollback = pane:get_lines_as_text()
	local name = os.tmpname()
	local f = io.open(name, "w+")
	f:write(scrollback)
	f:flush()
	f:close()
	window:perform_action(
		wezterm.action({
			SpawnCommandInNewTab = {
				args = { "nvim", name },
			},
		}),
		pane
	)
	wezterm.sleep_ms(1000)
	os.remove(name)
end)

return {
	font = wezterm.font_with_fallback({
		"CodeNewRoman Nerd Font",
		"Hiragino Sans",
	}),
	use_ime = true,
	font_size = 15.0,
	color_scheme = "iceberg-dark",
	window_background_opacity = 0.93,
	-- color_scheme = "GruvboxDark (Gogh)",-- 自分の好きなテーマ探す https://wezfurlong.org/wezterm/colorschemes/index.html
	hide_tab_bar_if_only_one_tab = true,
	adjust_window_size_when_changing_font_size = false,
	-- Kitty graphics protocol の描画を許可 (デフォルト false)。
	-- herdr-browser プラグインが agent-browser のスクショを APC で流し込むのに必要。
	enable_kitty_graphics = true,
	-- タブ・ペイン操作は herdr に任せるため、デフォルトキーバインドを全無効化。
	-- WezTerm 層に必要な最小セットだけ再定義する。
	disable_default_key_bindings = true,
	keys = {
		{ key = "c", mods = "SUPER", action = wezterm.action({ CopyTo = "Clipboard" }) },
		{ key = "v", mods = "SUPER", action = wezterm.action({ PasteFrom = "Clipboard" }) },
		{ key = "q", mods = "SUPER", action = wezterm.action.QuitApplication },
		{ key = "=", mods = "SUPER", action = wezterm.action.IncreaseFontSize },
		{ key = "-", mods = "SUPER", action = wezterm.action.DecreaseFontSize },
		{ key = "0", mods = "SUPER", action = wezterm.action.ResetFontSize },
		{ key = "E", mods = "ALT",   action = wezterm.action({ EmitEvent = "trigger-nvim-with-scrollback" }) },
		{ key = "F", mods = "SUPER", action = wezterm.action.QuickSelect },

		-- herdr 操作（Cmd キーを prefix シーケンスに変換して送る）
		-- Cmd+T: スペース内に新タブ
		{ key = "t", mods = "SUPER", action = herdr({ key = "c" }) },
		-- Cmd+[ / ]: スペース内のタブ移動
		{ key = "[", mods = "SUPER", action = herdr({ key = "p" }) },
		{ key = "]", mods = "SUPER", action = herdr({ key = "n" }) },
		-- Cmd+1..9: wezterm 純正のタブ切替（herdr のタブ移動は Cmd+[ / ] を使う）
		{ key = "1", mods = "SUPER", action = wezterm.action({ ActivateTab = 0 }) },
		{ key = "2", mods = "SUPER", action = wezterm.action({ ActivateTab = 1 }) },
		{ key = "3", mods = "SUPER", action = wezterm.action({ ActivateTab = 2 }) },
		{ key = "4", mods = "SUPER", action = wezterm.action({ ActivateTab = 3 }) },
		{ key = "5", mods = "SUPER", action = wezterm.action({ ActivateTab = 4 }) },
		{ key = "6", mods = "SUPER", action = wezterm.action({ ActivateTab = 5 }) },
		{ key = "7", mods = "SUPER", action = wezterm.action({ ActivateTab = 6 }) },
		{ key = "8", mods = "SUPER", action = wezterm.action({ ActivateTab = 7 }) },
		{ key = "9", mods = "SUPER", action = wezterm.action({ ActivateTab = 8 }) },
		-- Cmd+Shift+[ / ]: スペース（プロジェクト）間の移動
		-- macOSのキー解釈が環境依存のため、届きうる表現をすべて登録する
		{ key = "[", mods = "SHIFT|SUPER", action = herdr({ key = "UpArrow" }) },
		{ key = "{", mods = "SHIFT|SUPER", action = herdr({ key = "UpArrow" }) },
		{ key = "{", mods = "SUPER", action = herdr({ key = "UpArrow" }) },
		{ key = "phys:LeftBracket", mods = "SHIFT|SUPER", action = herdr({ key = "UpArrow" }) },
		{ key = "]", mods = "SHIFT|SUPER", action = herdr({ key = "DownArrow" }) },
		{ key = "}", mods = "SHIFT|SUPER", action = herdr({ key = "DownArrow" }) },
		{ key = "}", mods = "SUPER", action = herdr({ key = "DownArrow" }) },
		{ key = "phys:RightBracket", mods = "SHIFT|SUPER", action = herdr({ key = "DownArrow" }) },
		-- Cmd+P: session navigator（j/k移動, Enter確定, b/w/i/dでエージェント状態フィルタ, /で検索）
		{ key = "p", mods = "SUPER", action = herdr({ key = "g" }) },
		-- Cmd+Shift+T: スペース追加（herdrは名前プロンプトなしで即作成。リネームは Ctrl+a Shift+W）
		{ key = "T", mods = "SUPER", action = herdr({ key = "n", mods = "SHIFT" }) },
		-- Cmd+Shift+G / O: 今のスペースから新規worktreeを作成 / 既存worktreeを開く
		{ key = "G", mods = "SUPER", action = herdr({ key = "g", mods = "SHIFT" }) },
		{ key = "O", mods = "SUPER", action = herdr({ key = "o", mods = "SHIFT" }) },
		-- Cmd+Shift+V / H: ペイン分割（V: 上下 / H: 左右）
		{ key = "V", mods = "SUPER", action = herdr({ key = "-" }) },
		{ key = "H", mods = "SUPER", action = herdr({ key = "v" }) },
		-- Cmd+W: ペインを閉じる
		{ key = "w", mods = "SUPER", action = herdr({ key = "x" }) },
		-- Cmd+h/j/k/l: スプリット間のフォーカス移動
		{ key = "h", mods = "SUPER", action = herdr({ key = "h" }) },
		{ key = "j", mods = "SUPER", action = herdr({ key = "j" }) },
		{ key = "k", mods = "SUPER", action = herdr({ key = "k" }) },
		{ key = "l", mods = "SUPER", action = herdr({ key = "l" }) },
	},

	use_fancy_tab_bar = false,
	colors = {
		cursor_bg = "#c6c8d1",
		tab_bar = {
			background = "#1b1f2f",

			active_tab = {
				bg_color = "#444b71",
				fg_color = "#c6c8d1",
				intensity = "Normal",
				underline = "None",
				italic = false,
				strikethrough = false,
			},

			inactive_tab = {
				bg_color = "#282d3e",
				fg_color = "#c6c8d1",
				intensity = "Normal",
				underline = "None",
				italic = false,
				strikethrough = false,
			},

			inactive_tab_hover = {
				bg_color = "#1b1f2f",
				fg_color = "#c6c8d1",
				intensity = "Normal",
				underline = "None",
				italic = true,
				strikethrough = false,
			},

			new_tab = {
				bg_color = "#1b1f2f",
				fg_color = "#c6c8d1",
				italic = false,
			},

			new_tab_hover = {
				bg_color = "#444b71",
				fg_color = "#c6c8d1",
				italic = false,
			},
		},
	},
}

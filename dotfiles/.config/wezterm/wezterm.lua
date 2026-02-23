local wezterm = require("wezterm")

local function is_tmux(pane)
	return pane:get_user_vars().IS_TMUX == "true"
end

local function tmux_or_native(tmux_keys, native_action)
	return wezterm.action_callback(function(window, pane)
		if is_tmux(pane) then
			for _, key in ipairs(tmux_keys) do
				window:perform_action(wezterm.action.SendKey(key), pane)
			end
		else
			window:perform_action(native_action, pane)
		end
	end)
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
	-- disable_default_key_bindings = true,
	keys = {
		{ key = "c", mods = "SUPER", action = wezterm.action({ CopyTo = "Clipboard" }) },
		{ key = "v", mods = "SUPER", action = wezterm.action({ PasteFrom = "Clipboard" }) },
		{ key = "E", mods = "ALT",   action = wezterm.action({ EmitEvent = "trigger-nvim-with-scrollback" }) },

		-- Cmd+Shift+V → tmux: Ctrl-a " / native: SplitVertical
		{ key = "V", mods = "SUPER", action = tmux_or_native(
			{ { key = "a", mods = "CTRL" }, { key = '"' } },
			wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" })
		) },
		-- Cmd+Shift+H → tmux: Ctrl-a % / native: SplitHorizontal
		{ key = "H", mods = "SUPER", action = tmux_or_native(
			{ { key = "a", mods = "CTRL" }, { key = "%" } },
			wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" })
		) },
		-- Cmd+W → tmux: Ctrl-a x / native: CloseCurrentPane
		{ key = "w", mods = "SUPER", action = tmux_or_native(
			{ { key = "a", mods = "CTRL" }, { key = "x" } },
			wezterm.action.CloseCurrentPane({ confirm = false })
		) },

		-- Cmd+h/j/k/l → tmux: Ctrl+h/j/k/l / native: ActivatePaneDirection
		{ key = "h", mods = "SUPER", action = tmux_or_native(
			{ { key = "h", mods = "CTRL" } },
			wezterm.action.ActivatePaneDirection("Left")
		) },
		{ key = "l", mods = "SUPER", action = tmux_or_native(
			{ { key = "l", mods = "CTRL" } },
			wezterm.action.ActivatePaneDirection("Right")
		) },
		{ key = "k", mods = "SUPER", action = tmux_or_native(
			{ { key = "k", mods = "CTRL" } },
			wezterm.action.ActivatePaneDirection("Up")
		) },
		{ key = "j", mods = "SUPER", action = tmux_or_native(
			{ { key = "j", mods = "CTRL" } },
			wezterm.action.ActivatePaneDirection("Down")
		) },

		-- Cmd+Z → tmux: Ctrl-a z / native: TogglePaneZoomState
		{ key = "z", mods = "SUPER", action = tmux_or_native(
			{ { key = "a", mods = "CTRL" }, { key = "z" } },
			wezterm.action.TogglePaneZoomState
		) },

		{ key = "F", mods = "SUPER", action = wezterm.action.QuickSelect },
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

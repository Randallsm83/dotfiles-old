local wezterm = require("wezterm")

local act = wezterm.action

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Need empty object to set properties of colors and still support direct color modification of colors itself
config.colors = {}

-------------------- Appearance ----------------------------

--- Gruvbox
-- config.color_scheme = 'GruvboxDark'
-- config.color_scheme = 'GruvboxDarkHard'
-- config.color_scheme = 'Gruvbox Dark (Gogh)'
-- config.color_scheme = 'Gruvbox Material (Gogh)'
-- config.color_scheme = 'Gruvbox dark, pale (base16)'
config.color_scheme = "Gruvbox dark, soft (base16)"
-- config.color_scheme = "Gruvbox dark, medium (base16)"
-- config.color_scheme = 'Gruvbox dark, hard (base16)'

--- Dracula
-- config.color_scheme = 'Dracula+'
-- config.color_scheme = 'Dracula (Gogh)'
-- config.color_scheme = 'Dracula (Official)'

--- One Dark
-- config.color_scheme = 'One Dark (Gogh)'
-- config.color_scheme = 'OneDark (base16)'

--- Kanagawa
-- config.color_scheme = 'Kanagawa (Gogh)'

--- Tokyo Nights
-- config.color_scheme = 'Tokyo Night'
-- config.color_scheme = 'Tokyo Night Storm'
-- config.color_scheme = 'Tokyo Night Moon'

--- Catppuccin
-- config.color_scheme = 'catppuccin-frappe'
-- config.color_scheme = 'catppuccin-macchiato'
-- config.color_scheme = 'catppuccin-mocha'

--- Chalk
-- config.color_scheme = 'Chalk'
-- config.color_scheme = 'Chalk (Gogh)'
-- config.color_scheme = 'Chalk (dark) (terminal.sexy)'

--- Gogh
-- config.color_scheme = 'Gogh (Gogh)'

--- Kanagawa
-- config.colors = {
-- foreground = "#dcd7ba",
-- background = "#1f1f28",
--
-- cursor_bg = "#c8c093",
-- cursor_fg = "#c8c093",
-- cursor_border = "#c8c093",
--
-- selection_fg = "#c8c093",
-- selection_bg = "#2d4f67",
--
-- scrollbar_thumb = "#16161d",
-- split = "#16161d",
--
-- ansi = { "#090618", "#c34043", "#76946a", "#c0a36e", "#7e9cd8", "#957fb8", "#6a9589", "#c8c093" },
-- brights = { "#727169", "#e82424", "#98bb6c", "#e6c384", "#7fb4ca", "#938aa9", "#7aa89f", "#dcd7ba" },
-- indexed = { [16] = "#ffa066", [17] = "#ff5d62" },
-- }

------------------------- Font -----------------------------
config.font = wezterm.font_with_fallback({
	"MonaspiceNe Nerd Font",
	"MesloLGM Nerd Font",
	"Menlo",
})
config.font_size = 14
config.line_height = 1.1

------------------ Windows and Panes -----------------------
-- Window configuration
config.initial_rows = 86
config.initial_cols = 254
config.enable_scroll_bar = false
config.window_decorations = "RESIZE"
config.native_macos_fullscreen_mode = false
config.adjust_window_size_when_changing_font_size = false

config.window_background_opacity = 0.9
config.macos_window_background_blur = 25

-- Window Padding
config.window_padding = {
	top = 2,
	left = 5,
	right = 10,
	bottom = 10,
}

-- Dim inactive panes
config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.6,
}

------------------------- Tabs -----------------------------
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false

-- Tab Bar Colors
config.colors.tab_bar = {
	-- Default ('Other', 'Options')
	background = "#282828", -- Not available with fancy tab bar
	inactive_tab_edge = "#1d2021", -- Only with fancy tab bar
	active_tab = {
		bg_color = "#d65d0e",
		fg_color = "#d5c4a1",
		italic = false, -- false
		strikethrough = false, -- false
		underline = "None", -- 'None' ('Single', 'Double')
		intensity = "Normal", -- 'Normal' ('Half', 'Bold')
	},
	inactive_tab = {
		bg_color = "#504945",
		fg_color = "#928374",
		italic = false, -- false
		strikethrough = false, -- false
		underline = "None", -- 'None' ('Single', 'Double')
		intensity = "Normal", -- 'Normal' ('Half', 'Bold')
	},
	inactive_tab_hover = {
		bg_color = "#7c6f64",
		fg_color = "#bdae93",
		italic = true, -- false
		strikethrough = false, -- false
		underline = "None", -- 'None' ('Single', 'Double')
		intensity = "Normal", -- 'Normal' ('Half', 'Bold')
	},
	-- new_tab = {
	-- bg_color = "#1b1032",
	-- fg_color = "#808080",
	-- italic = false, -- false
	-- strikethrough = false, -- false
	-- underline = "None", -- 'None' ('Single', 'Double')
	-- intensity = "Normal", -- 'Normal' ('Half', 'Bold')
	-- },
	-- new_tab_hover = {
	-- bg_color = "#3b3052",
	-- fg_color = "#909090",
	-- italic = true, -- false
	-- strikethrough = false, -- false
	-- underline = "None", -- 'None' ('Single', 'Double')
	-- intensity = "Normal", -- 'Normal' ('Half', 'Bold')
	-- },
}

-- Customize the fancy tab bar if in use
-- config.window_frame = {
-- 	font = wezterm.font({
-- 		family = "MonaspiceNe",
-- 		weight = "Bold", -- Roboto Bold
-- 	}),
-- 	font_size = 11.0, -- 12
-- 	active_titlebar_bg = "#333333",
-- 	inactive_titlebar_bg = "#333333",
-- }

-- Cursor
config.cursor_blink_rate = 800
config.force_reverse_video_cursor = true
config.default_cursor_style = "BlinkingBlock"

-- Bell
config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_function = "Ease",
	fade_in_duration_ms = 75,
	fade_out_function = "Ease",
	fade_out_duration_ms = 75,
}
config.colors.visual_bell = "#202020"

-- Use scrollback buffer for scrolling through terminal history
config.scrollback_lines = 10000

-- Enable hardware acceleration if available
config.animation_fps = 30
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

-- Automatically reload config when it's changed
config.check_for_updates = true
config.automatically_reload_config = true

-- Mouse
config.swallow_mouse_click_on_pane_focus = true
config.bypass_mouse_reporting_modifiers = "ALT"

-- Keys - Quick Reference:
-- ALT + t: New tab
-- ALT + w: Close tab
-- ALT + ] | [: Previous/Next tab
-- ALT + r | d: Split horizontal/vertical
-- ALT + hjkl: Navigate panes
-- ALT + SHIFT + hjkl: Resize panes
-- ALT + z: Toggle zoom
-- ALT + f: Toggle fullscreen
-- ALT + s: Show workspaces
-- ALT + q: Quite applicatin
-- ALT + /: Searc/h
config.keys = {
	-- Session/Window Management
	{
		key = "s",
		mods = "ALT",
		action = act.ShowLauncherArgs({ flags = "WORKSPACES" }),
	},

	-- Tab Management
	{
		key = "t",
		mods = "ALT",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "w",
		mods = "ALT",
		action = act.CloseCurrentTab({ confirm = true }),
	},
	{
		key = "]",
		mods = "ALT",
		action = act.ActivateTabRelative(1),
	},
	{
		key = "[",
		mods = "ALT",
		action = act.ActivateTabRelative(-1),
	},

	-- Pane Navigation (vim-style)
	{ key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },

	-- Pane Resizing
	{ key = "h", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "j", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "k", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "l", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

	{ key = "z", mods = "ALT", action = act.TogglePaneZoomState },

	-- Quick Actions

	{ key = "d", mods = "ALT", action = act.SplitVertical },
	{ key = "r", mods = "ALT", action = act.SplitHorizontal },

	{ key = "q", mods = "ALT", action = act.QuitApplication },
	{ key = "Enter", mods = "ALT", action = act.ToggleFullScreen },

	{ key = "/", mods = "ALT", action = act.Search({ CaseInSensitiveString = "" }) },
}

-- Workspace Layout Functions
local function single_editor(window, pane)
	-- Main editor pane
	pane:send_text("nvim .\n")

	local right_pane = pane:split({
		direction = "Right",
		size = 0.3,
	})

	local bottom_right = right_pane:split({
		direction = "Bottom",
		size = 0.5,
	})

	-- Terminal commands
	right_pane:send_text("lde status\n")
	bottom_right:send_text("lde logs\n")
end

local function dual_editor(window, pane)
	pane:send_text("nvim .\n")

	-- Terminal on right
	local right_pane = pane:split({
		direction = "Right",
		size = 0.3,
	})

	-- Bottom for git/utilities
	local bottom_pane = right_pane:split({
		direction = "Bottom",
		size = 0.4,
	})

	-- Commands
	right_pane:send_text("lde status\n")
	bottom_pane:send_text("lde logs\n")
end

-- Add keys for layouts
table.insert(config.keys, {
	key = "p",
	mods = "ALT|SHIFT",
	action = act.PromptInputLine({
		description = "Enter project directory",
		action = wezterm.action_callback(function(window, pane, line)
			if line then
				-- Change to project directory
				pane:send_text("cd " .. line .. "\n")
				-- Show layout selector
				window:perform_action(act.InputSelector({
					title = "Select Layout",
					choices = {
						{ label = "Single Editor", id = "single" },
						{ label = "Dual Editor", id = "dual" },
					},
					action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
						if id == "single" then
							single_editor(inner_window, inner_pane)
						elseif id == "dual" then
							dual_editor(inner_window, inner_pane)
						end
					end),
				}))
			end
		end),
	}),
})

-- Direct layout shortcuts
local layout_keys = {
	{ key = "1", mods = "ALT|SHIFT", layout = single_editor },
	{ key = "2", mods = "ALT|SHIFT", layout = dual_editor },
}

for _, layout_key in ipairs(layout_keys) do
	table.insert(config.keys, {
		key = layout_key.key,
		mods = layout_key.mods,
		action = wezterm.action_callback(function(window, pane)
			layout_key.layout(window, pane)
		end),
	})
end

-- Workspace Management
wezterm.on("format-window-title", function(tab, pane, tabs)
	local zoomed = ""
	if tab.active_pane.is_zoomed then
		zoomed = "[Z] "
	end

	local index = ""
	if #tabs > 1 then
		index = string.format("[%d/%d] ", tab.tab_index + 1, #tabs)
	end

	return zoomed .. index .. tab.active_pane.title
end)

return config

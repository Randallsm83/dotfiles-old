local wezterm = require("wezterm")

local act = wezterm.action

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-------------------- Colorscheme ----------------------------

config.colors = {} -- So we can append keys instead of writing a whole new object later

--- Gruvbox
-- https://github.com/morhetz/gruvbox?tab=readme-ov-file#palette
-- fg #ebdbb2, fg0 #fbf1c7, fg1 #ebdbb2, fg2 #d5c4a1, fg3 #bdae93, fg4 #a89984
-- bg #282828, bg0 #282828, bg1 #3c3836, bg2 #504945, bg3 #665c54, bg4 #7c6f64, bg0_soft #32302f, bg0_hard #1d2021
-- normal gray #928374, red #cc241d, green #98971a, yellow #d79921, blue #458588, purple #b16286, aqua #689d6a, orange #d65d0e
-- bright gray #a89984, red #fb4934, green #b8bb26, yellow #fadb2f, blue #83a598, purple #d3869b, aqua #8ec07c, orange #fe8019
--
-- local theme = "GruvboxDark"
-- local theme = "GruvboxDarkHard"
local theme = "Gruvbox Dark (Gogh)"
-- local theme = "Gruvbox Material (Gogh)"
-- local theme = "Gruvbox dark, pale (base16)"
-- local theme = "Gruvbox dark, soft (base16)"
-- local theme = "Gruvbox dark, medium (base16)"
-- local theme = "Gruvbox dark, hard (base16)"

--- Dracula
-- local theme = "Dracula+"
-- local theme = "Dracula (Gogh)"
-- local theme = "Dracula (Official)"

--- One Dark
-- local theme = "One Dark (Gogh)"
-- local theme = "OneDark (base16)"

--- Kanagawa
-- local theme = "Kanagawa"
-- local theme = "Kanagawa (Gogh)"

--- Tokyo Nights
-- local theme = "Tokyo Night"
-- local theme = "Tokyo Night Storm"
-- local theme = "Tokyo Night Moon"

--- Catppuccin
-- local theme = "catppuccin-frappe"
-- local theme = "catppuccin-macchiato"
-- local theme = "catppuccin-mocha"

--- Chalk
-- local theme = "Chalk"
-- local theme = "Chalk (Gogh)"
-- local theme = "Chalk (dark) (terminal.sexy)"

--- Gogh
-- local theme = "Gogh (Gogh)"

config.color_scheme = theme

local scheme = wezterm.color.get_builtin_schemes()[theme]
-- Or for custom scheme
-- local scheme = wezterm.color.load_scheme(wezterm.config_dir .. "/colors/MyKanagawa.toml")

------------------------- Font -----------------------------

config.font_dirs = { wezterm.home_dir .. "/.local/share/fonts" }
config.font = wezterm.font_with_fallback({
  "Hack Nerd Font Mono",
  "FiraCode Nerd Font Mono",
})
config.font_size = 14
config.line_height = 1.1

------------------------- Tabs -----------------------------

--- Tabline
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

-- Set the following that apply_to_config would do, but also
-- sets config.colors to a new object instead off appending its key

config.tab_max_width = 32
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.colors.tab_bar = { background = scheme.background }
config.status_update_interval = 500

tabline.setup({
  options = {
    icons_enabled = true,
    theme = theme,
    color_overrides = {},
    section_separators = {
      left = wezterm.nerdfonts.pl_left_hard_divider,
      right = wezterm.nerdfonts.pl_right_hard_divider,
    },
    component_separators = {
      left = wezterm.nerdfonts.pl_left_soft_divider,
      right = wezterm.nerdfonts.pl_right_soft_divider,
    },
    tab_separators = {
      left = wezterm.nerdfonts.pl_left_hard_divider,
      right = wezterm.nerdfonts.pl_right_hard_divider,
    },
  },
  sections = {
    tabline_a = { "hostname" },
    tabline_b = { "workspace" },
    -- tabline_c = { ' ' },
    tab_active = {
      { "index", zero_indexed = true },
      { "parent", padding = { left = 0, right = 0 } },
      "/",
      { "cwd", padding = { left = 0, right = 1 } },
      { "zoomed", padding = 0 },
    },
    tab_inactive = {
      { "index", zero_indexed = true },
      { "process", padding = { left = 0, right = 1 } },
    },
    tabline_x = { "ram", "cpu" },
    tabline_y = { "battery" },
    tabline_z = { "datetime" },
  },
  extensions = {},
})
-- tabline.apply_to_config(config)

print(tabline.get_colors())
-- Tab Bar Colors
-- config.colors.tab_bar = {
-- Default ('Other', 'Options')
-- background = require("tabline.config").colors.normal_mode.c.bg, --"#282828", -- Not available with fancy tab bar
-- inactive_tab_edge = "#d65d0e", -- Only with fancy tab bar
-- active_tab = {
--   bg_color = "#d65d0e",
--   fg_color = "#d5c4a1",
--   italic = false, -- false
--   strikethrough = false, -- false
--   underline = "None", -- 'None' ('Single', 'Double')
--   intensity = "Normal", -- 'Normal' ('Half', 'Bold')
-- },
-- inactive_tab = {
--   bg_color = "#504945",
--   fg_color = "#928374",
--   italic = false, -- false
--   strikethrough = false, -- false
--   underline = "None", -- 'None' ('Single', 'Double')
--   intensity = "Normal", -- 'Normal' ('Half', 'Bold')
-- },
-- inactive_tab_hover = {
--   bg_color = "#7c6f64",
--   fg_color = "#bdae93",
--   italic = true, -- false
--   strikethrough = false, -- false
--   underline = "None", -- 'None' ('Single', 'Double')
--   intensity = "Normal", -- 'Normal' ('Half', 'Bold')
-- },
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
-- }

-- Customize the fancy tab bar if in use
-- config.window_frame = {
--   font = wezterm.font({
--     family = "Hack Nerd Font",
--     weight = "Bold",
--   }),
--   -- font_size = 12.5, -- 12
--   -- active_titlebar_bg = "#282828",
--   -- inactive_titlebar_bg = "#282828",
-- }

------------------ Windows and Panes -----------------------

-- Window configuration
config.initial_rows = 86
config.initial_cols = 254
config.enable_scroll_bar = false
config.window_decorations = "RESIZE"
config.native_macos_fullscreen_mode = false
config.adjust_window_size_when_changing_font_size = false

config.window_background_opacity = 0.92
config.macos_window_background_blur = 30

-- Window Padding
config.window_padding = { top = 0, left = 0, right = 0, bottom = 0 }

-- Dim inactive panes
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.7 }

-- Pane split color
config.colors.split = scheme.ansi[4]

--------------------------------------------------------------------------------
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
-- ALT + CTRL  + hjkl: Navigate panes
-- ALT + SHIFT + hjkl: Resize panes
-- ALT + z: Toggle zoom
-- ALT + f: Toggle fullscreen
-- ALT + s: Show workspaces
-- ALT + q: Quite application
-- ALT + /: Searc/h
config.keys = {
  -- Session/Window Management
  {
    key = "s",
    mods = "ALT",
    action = act.ShowLauncherArgs({ flags = "WORKSPACES" }),
  }, -- Tab Management
  { key = "t", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "ALT", action = act.CloseCurrentTab({ confirm = true }) },
  { key = "]", mods = "ALT", action = act.ActivateTabRelative(1) },
  { key = "[", mods = "ALT", action = act.ActivateTabRelative(-1) },

  -- Pane Navigation
  { key = "h", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Right") },

  -- Pane Resizing
  {
    key = "h",
    mods = "CTRL|ALT|SHIFT",
    action = act.AdjustPaneSize({ "Left", 5 }),
  },
  {
    key = "j",
    mods = "CTRL|ALT|SHIFT",
    action = act.AdjustPaneSize({ "Down", 5 }),
  },
  { key = "k", mods = "CTRL|ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
  {
    key = "l",
    mods = "CTRL|ALT|SHIFT",
    action = act.AdjustPaneSize({ "Right", 5 }),
  },
  { key = "z", mods = "ALT", action = act.TogglePaneZoomState },

  -- Quick Actions
  { key = "d", mods = "ALT", action = act.SplitVertical },
  { key = "r", mods = "ALT", action = act.SplitHorizontal },

  { key = "q", mods = "ALT", action = act.QuitApplication },
  { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },

  { key = "/", mods = "ALT", action = act.Search({ CaseInSensitiveString = "" }) },
}

-- Workspace Layout Functions
-- local function single_editor(window, pane)
--     -- Main editor pane
--     pane:send_text("nvim .\n")
--
--     local right_pane = pane:split({direction = "Right", size = 0.3})
--
--     local bottom_right = right_pane:split({direction = "Bottom", size = 0.5})
--
--     -- Terminal commands
--     right_pane:send_text("lde status\n")
--     bottom_right:send_text("lde logs\n")
-- end
--
-- local function dual_editor(window, pane)
--     pane:send_text("nvim .\n")
--
--     -- Terminal on right
--     local right_pane = pane:split({direction = "Right", size = 0.3})
--
--     -- Bottom for git/utilities
--     local bottom_pane = right_pane:split({direction = "Bottom", size = 0.4})
--
--     -- Commands
--     right_pane:send_text("lde status\n")
--     bottom_pane:send_text("lde logs\n")
-- end
--
-- -- Add keys for layouts
-- table.insert(config.keys, {
--     key = "p",
--     mods = "ALT|SHIFT",
--     action = act.PromptInputLine({
--         description = "Enter project directory",
--         action = wezterm.action_callback(
--             function(window, pane, line)
--                 if line then
--                     -- Change to project directory
--                     pane:send_text("cd " .. line .. "\n")
--                     -- Show layout selector
--                     window:perform_action(act.InputSelector({
--                         title = "Select Layout",
--                         choices = {
--                             {label = "Single Editor", id = "single"},
--                             {label = "Dual Editor", id = "dual"}
--                         },
--                         action = wezterm.action_callback(
--                             function(inner_window, inner_pane, id, label)
--                                 if id == "single" then
--                                     single_editor(inner_window, inner_pane)
--                                 elseif id == "dual" then
--                                     dual_editor(inner_window, inner_pane)
--                                 end
--                             end)
--                     }))
--                 end
--             end)
--     })
-- })
--
-- -- Direct layout shortcuts
-- local layout_keys = {
--     {key = "1", mods = "ALT|SHIFT", layout = single_editor},
--     {key = "2", mods = "ALT|SHIFT", layout = dual_editor}
-- }
--
-- for _, layout_key in ipairs(layout_keys) do
--     table.insert(config.keys, {
--         key = layout_key.key,
--         mods = layout_key.mods,
--         action = wezterm.action_callback(
--             function(window, pane) layout_key.layout(window, pane) end)
--     })
-- end
--
-- -- Workspace Management
-- wezterm.on("format-window-title", function(tab, pane, tabs)
--     local zoomed = ""
--     if tab.active_pane.is_zoomed then zoomed = "[Z] " end
--
--     local index = ""
--     if #tabs > 1 then
--         index = string.format("[%d/%d] ", tab.tab_index + 1, #tabs)
--     end
--
--     return zoomed .. index .. tab.active_pane.title
-- end)

return config

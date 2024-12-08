local wezterm = require('wezterm')
local M = {}

-- Define custom icons for popular processes
local process_icons = {
  ["vim"] = " ", -- Vim icon
  ["nvim"] = " ", -- Neovim icon
  ["bash"] = " ", -- Bash icon
  ["zsh"] = " ", -- Zsh icon
  ["fish"] = " ", -- Fish icon
  ["htop"] = "ﰍ ", -- Htop icon
  ["python"] = " ", -- Python icon
  ["node"] = " ", -- Node.js icon
  ["ssh"] = " ", -- SSH icon
}

-- Fetch the color for an element from the current color scheme
local function get_color(config, name)
  local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
  return scheme and scheme[name] or 'white'
end

-- Helper: Format strings to a fixed width
local function format_fixed_width(text, width)
  if #text > width then
    local part_length = math.floor((width - 3) / 2)
    return text:sub(1, part_length) .. '...' .. text:sub(-part_length)
  elseif #text < width then
    return text .. string.rep(' ', width - #text)
  end
  return text
end

-- Helper: Get a Nerd Font icon for a process
local function get_process_icon(process)
  return process_icons[process:lower()] or " " -- Default terminal icon
end

-- Tooltip: Elapsed time since tab creation or last activity
local function get_elapsed_time(tab)
  local elapsed = os.time() - tab.creation_time
  local hours = math.floor(elapsed / 3600)
  local minutes = math.floor((elapsed % 3600) / 60)
  local seconds = elapsed % 60
  return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Tab Bar Event
wezterm.on('format-tab-bar', function(tab, tabs, panes, hover, max_width)
  local components = {}

  wezterm.log_info("Custom tab bar event triggered!")
  -- Left Section: CWD/Project with Nerd Font Folder Icon
  local cwd = ''
  local active_pane = tabs[1].active_pane
  if active_pane.current_working_dir then
    local cwd_uri = active_pane.current_working_dir:sub(8) -- Remove 'file://'
    cwd = wezterm.path.split(cwd_uri)
    cwd = cwd[#cwd] or cwd_uri
  end
  cwd = format_fixed_width(cwd, 25) -- Limit to 25 chars
  table.insert(components, {
    Text = string.format(" %s │ ", cwd),
    Foreground = get_color(wezterm.config_builder(), "foreground"),
  })

  -- Middle Section: Tabs
  for _, tab_item in ipairs(tabs) do
    local pane = tab_item.active_pane
    local process = pane.foreground_process_name or '?'
    local hostname = pane:is_remote() and "remote" or wezterm.hostname()
    local process_icon = get_process_icon(process)

    -- Tooltip for hover (full tab title, process, elapsed time)
    if hover and hover.tab_index == tab_item.tab_index then
      local tooltip = string.format(
        "Tab %d: %s [%s]\nElapsed: %s\nCWD: %s",
        tab_item.tab_index + 1,
        process,
        hostname,
        get_elapsed_time(tab_item),
        pane.current_working_dir or "unknown"
      )
      wezterm.log_info(tooltip) -- Debugging hover
    end

    -- Active Tab
    if tab_item.is_active then
      table.insert(components, {
        Text = string.format(" %s*%d: %s [%s]* ", process_icon, tab_item.tab_index + 1, process, hostname),
        Attribute = { Bold = true, Underline = true },
        Foreground = get_color(wezterm.config_builder(), "cursor"),
      })
    else
      -- Inactive Tabs
      local activity_marker = tab_item.has_unseen_output and "" or ""
      table.insert(components, {
        Text = string.format(" %s %d: [%s] %s %s ", activity_marker, tab_item.tab_index + 1, hostname, process, process_icon),
        Foreground = get_color(wezterm.config_builder(), "inactive_tab"),
      })
    end
  end

  -- Right Section: System Info (User, Host, Time)
  local user = os.getenv("USER") or "unknown"
  local host = wezterm.hostname()
  local time = wezterm.strftime("%H:%M:%S")
  local right_info = string.format("  %s@%s │  %s", user, host, time)
  table.insert(components, { Text = right_info, Align = "Right", Foreground = get_color(wezterm.config_builder(), "foreground") })

  return components
end)

-- Apply tab configuration
function M.apply_to_config(config)
  config.enable_tab_bar = true
  config.use_fancy_tab_bar = false
  config.tab_bar_at_bottom = true
  config.show_new_tab_button_in_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = false
  config.tab_max_width = 32

  return config
end

return M

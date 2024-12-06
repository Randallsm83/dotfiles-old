local wez = require("wezterm")
local utils = require("utilities")
local M = {}

local ICONS = {
  workspace = wez.nerdfonts.cod_window,
  process = wez.nerdfonts.cod_server_process,
  arrow = wez.nerdfonts.md_greater_than,
  field = wez.nerdfonts.indent_line,
  dir = wez.nerdfonts.fa_folder,
  clock = wez.nerdfonts.md_clock,
  user = wez.nerdfonts.fa_user,
  host = wez.nerdfonts.cod_terminal,
}

local username = os.getenv("USER") or os.getenv("LOGNAME") or os.getenv("USERNAME")

local function get_cwd(pane)
  local home = os.getenv("HOME") or ""
  local cwd = ""
  local cwd_uri = pane:get_current_working_dir()

  if cwd_uri then
    if type(cwd_uri) == "userdata" and cwd_uri.file_path then
      cwd = cwd_uri.file_path
    else
      cwd_uri = cwd_uri:sub(8)
      local slash = cwd_uri:find "/"
      if slash then
        cwd = cwd_uri:sub(slash):gsub("%%(%x%x)", function(hex)
          return string.char(tonumber(hex, 16))
        end)
      end
    end

    cwd = cwd:gsub(home .. "(.-)$", "~%1")
  end

  return cwd
end

local function get_tab_title(tab_info)
  local title = tab_info.tab_title
  if title and #title > 0 then
    return title
  end
  return utils.basename(tab_info.active_pane.title)
end

function M.apply_to_config(config)
  config.enable_tab_bar = true
  config.use_fancy_tab_bar = false
  config.tab_bar_at_bottom = true
  config.show_new_tab_button_in_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = false
  config.tab_max_width = 32

  local scheme = wez.color.get_builtin_schemes()[config.color_scheme]
  if scheme == nil then
    scheme = wez.color.get_default_colors()
  end

  local colors = {
    tab_bar = {
      background = scheme.background,
      active_tab = {
        bg_color = scheme.background,
        fg_color = scheme.ansi[4],
      },
      inactive_tab = {
        bg_color = scheme.background,
        fg_color = scheme.ansi[8],
      },
    },
  }

  config.colors = config.colors or {}
  config.colors = utils.merge(config.colors, colors)

  return config
end

wez.on("format-tab-title", function(tab, _, _, conf)
  local index = tab.tab_index + 1
  local title = get_tab_title(tab)
  local formatted_title = index .. utils.space(ICONS.arrow, 1) .. title

  local width = conf.tab_max_width - 4
  if #formatted_title > conf.tab_max_width then
    formatted_title = wez.truncate_right(formatted_title, width) .. "…"
  end

  local palette = conf.resolved_palette
  local fg = tab.is_active and palette.tab_bar.active_tab.fg_color or palette.tab_bar.inactive_tab.fg_color
  local bg = palette.tab_bar.background

  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = utils.space(formatted_title, 1, 1) },
  }
end)
-- wez.on("format-tab-title", function(tab, tabs, _, conf)
--   local raw_title = tab.active_pane.title
--   local clean_title = utils.basename(raw_title) or utils.trim(raw_title)
--   local index = tostring(tab.tab_index + 1)
--
--   local formatted_title = utils.space(index .. ":" .. clean_title, 1, 1)
--
--   if #formatted_title > conf.tab_max_width then
--     formatted_title = wez.truncate_right(formatted_title, conf.tab_max_width - 1) .. "… "
--   end
--
--   local palette = conf.resolved_palette
--   local fg = tab.is_active and palette.tab_bar.active_tab.fg_color or palette.tab_bar.inactive_tab.fg_color
--   local bg = tab.is_active and palette.tab_bar.active_tab.bg_color or palette.tab_bar.inactive_tab.bg_color
--
--   return {
--     { Background = { Color = bg } },
--     { Foreground = { Color = fg } },
--     { Text = formatted_title },
--   }
-- end)
wez.on("update-status", function(window, pane)
  local palette = window:effective_config().resolved_palette
  local background = palette.tab_bar.background

  -- Left status: session/workspace context
  local left_status = {
    { Background = { Color = background } },
  }

  -- Current directory
  local cwd = get_cwd(pane)
  if #cwd > 0 then
    local width = window:effective_config().tab_max_width - 4
    local formatted_cwd = utils.space(cwd, 1, 1)
    if #formatted_cwd > window:effective_config().tab_max_width then
      formatted_cwd = "…" .. wez.truncate_left(formatted_cwd, width)
    end
    table.insert(left_status, { Text = string.format(" %s %s%s ", ICONS.dir, formatted_cwd, ICONS.field) })
    -- table.insert(right_status, { Text = string.format(" %s ", ICONS.field) })
  end

  -- -- Session/workspace name - primary context
  -- local workspace = window:active_workspace()
  -- table.insert(left_status, { Text = string.format(" %s %s ", ICONS.workspace, workspace) })
  --
  -- -- Process info - secondary context
  -- local process = pane:get_foreground_process_name()
  -- if process then
  --   process = utils.basename(process)
  --   table.insert(left_status, { Text = string.format(" %s %s", ICONS.process, process) })
  -- end

  window:set_left_status(wez.format(left_status))

  -- Right status: following classic user@host | location | time pattern
  local right_status = {
    { Background = { Color = background } },
  }

  -- Session/workspace name - primary context
  local workspace = window:active_workspace()
  table.insert(right_status, { Text = string.format(" %s %s ", ICONS.workspace, workspace) })

  -- Process info - secondary context
  local process = pane:get_foreground_process_name()
  if process then
    process = utils.basename(process)
    table.insert(right_status, { Text = string.format(" %s %s", ICONS.process, process) })
  end

  -- user@host
  table.insert(right_status, { Text = string.format("%s  %s %s  %s  %s %s ",
    ICONS.user,
    username,
    ICONS.field,
    ICONS.host,
    wez.hostname(),
    ICONS.field
  )})
  -- table.insert(right_status, { Text = string.format(" %s ", ICONS.field) })

  -- Time - always last
  local time = wez.time.now():format "%H:%M"
  table.insert(right_status, { Text = string.format(" %s  %s  ", ICONS.clock, time) })

  window:set_right_status(wez.format(right_status))
end)

-- wez.on("update-status", function(window, pane)
--   local palette = window:effective_config().resolved_palette
--   local background = palette.tab_bar.background
--
--   -- Left status
--   local left_status = {
--     { Background = { Color = background } },
--   }
--
--   -- Workspace with icon
--   local workspace = window:active_workspace()
--   table.insert(left_status, { Text = string.format(" %s %s ", ICONS.workspace, workspace) })
--
--   -- Username
--   table.insert(left_status, { Text = string.format(" %s %s ", ICONS.user, username) })
--
--   -- Hostname
--   table.insert(left_status, { Text = string.format(" %s %s ", ICONS.host, wez.hostname()) })
--
--   -- Process
--   local process = pane:get_foreground_process_name()
--   if process then
--     table.insert(left_status, { Text = string.format(" %s %s ", ICONS.process, utils.basename(process)) })
--   end
--
--   window:set_left_status(wez.format(left_status))
--
--   -- Right status
--   local right_status = {
--     { Background = { Color = background } },
--   }
--
--   -- Directory
--   local cwd = get_cwd(pane)
--   if #cwd > 0 then
--     table.insert(right_status, { Text = string.format(" %s %s ", ICONS.dir, cwd) })
--   end
--
--   -- Add field separator
--   table.insert(right_status, { Text = string.format(" %s ", ICONS.field) })
--
--   -- Time with icon
--   local time = wez.time.now():format "%H:%M"
--   table.insert(right_status, { Text = string.format(" %s %s ", ICONS.clock, time) })
--
--   window:set_right_status(wez.format(right_status))
-- end)
-- wez.on("update-status", function(window, pane)
--   local palette = window:effective_config().resolved_palette
--   -- Left status
--   local left_status = {
--     { Background = { Color = palette.tab_bar.background } },
--   }
--
--   -- Workspace with icon
--   local workspace = window:active_workspace()
--   local formatted_workspace = utils.space(ICONS.workspace .. workspace, 1, 1)
--   table.insert(left_status, { Text = formatted_workspace })
--
--   -- Process
--   local process = pane:get_foreground_process_name()
--   if process then
--     process = utils.basename(process) or utils.trim(process)
--     local formatted_process = utils.space(ICONS.arrow .. process, 1, 1)
--     table.insert(left_status, { Text = formatted_process })
--   end
--
--   window:set_left_status(wez.format(left_status))
--
--   -- Right status
--   local right_status = {
--     { Background = { Color = palette.tab_bar.background } },
--   }
--
--   -- Directory
--   local cwd = get_cwd(pane)
--   if #cwd > 0 then
--     local formatted_cwd = utils.space(ICONS.dir .. cwd, 1, 1)
--     table.insert(right_status, { Text = formatted_cwd })
--   end
--
--   -- Time with icon
--   local time = wez.time.now():format "%H:%M"
--   local formatted_time = utils.space(ICONS.clock .. time, 1, 1)
--   table.insert(right_status, { Text = formatted_time })
--
--   window:set_right_status(wez.format(right_status))
-- end)
-- wez.on("update-status", function(window, pane)
--   -- Left status: workspace and current process
--   local left_status = {}
--
--   -- Workspace
--   local workspace = window:active_workspace()
--   table.insert(left_status, { Text = string.format(" %s %s ", ICONS.workspace, workspace) })
--
--   -- Current process
--   local process = pane:get_foreground_process_name()
--   if process then
--     table.insert(left_status, { Text = string.format(" %s %s ", ICONS.arrow, process) })
--   end
--
--   window:set_left_status(wez.format(left_status))
--
--   -- Right status: hostname, username, cwd, time
--   local right_status = {}
--
--   -- Hostname
--   table.insert(right_status, { Text = " " .. wez.hostname() .. " " })
--   table.insert(right_status, { Text = string.format(" %s %s ", ICONS.hostname, username) })
--
--   -- Username
--   if username then
--     table.insert(right_status, { Text = string.format(" %s %s ", ICONS.user, username) })
--   end
--
--   -- CWD
--   local cwd = get_cwd(pane)
--   if #cwd > 0 then
--     table.insert(right_status, { Text = string.format(" %s %s ", ICONS.dir, cwd) })
--   end
--
--   -- Time
--   local time = wez.time.now():format("%H:%M")
--   table.insert(right_status, { Text = string.format(" %s %s ", ICONS.clock, time) })
--
--   window:set_right_status(wez.format(right_status))
-- end)

return M

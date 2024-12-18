local wez = require("wezterm")
local utils = require("utilities")
local M = {}

-- Get username once since it won't change
local username = os.getenv("USER") or os.getenv("LOGNAME") or os.getenv("USERNAME")

-- Process-specific icons
local PROCESS_ICONS = {
  ["zsh"] = wez.nerdfonts.dev_terminal,
  ["bash"] = wez.nerdfonts.cod_terminal_bash,
  ["fish"] = wez.nerdfonts.dev_terminal,
  ["term"] = wez.nerdfonts.dev_terminal,
  ["ssh"] = wez.nerdfonts.cod_terminal_linux,
  ["sudo"] = wez.nerdfonts.fa_hashtag,
  ["docker"] = wez.nerdfonts.linux_docker,
  ["docker-compose"] = wez.nerdfonts.linux_docker,
  ["kuberlr"] = wez.nerdfonts.linux_docker,
  ["kubectl"] = wez.nerdfonts.linux_docker,
  ["make"] = wez.nerdfonts.seti_makefile,
  ["htop"] = wez.nerdfonts.mdi_chart_donut_variant,
  ["vim"] = wez.nerdfonts.custom_vim,
  ["nvim"] = wez.nerdfonts.custom_vim,
  ["git"] = wez.nerdfonts.dev_git,
  ["wget"] = wez.nerdfonts.mdi_arrow_down_box,
  ["curl"] = wez.nerdfonts.mdi_flattr,
  ["gh"] = wez.nerdfonts.dev_github_badge,
  ["node"] = wez.nerdfonts.dev_nodejs_small,
  ["perl"] = wez.nerdfonts.dev_perl,
  ["python"] = wez.nerdfonts.dev_python,
  ["lua"] = wez.nerdfonts.seti_lua,
  ["go"] = wez.nerdfonts.seti_go,
  ["cargo"] = wez.nerdfonts.dev_rust,
  ["ruby"] = wez.nerdfonts.cod_ruby,
}

-- Status bar icons
local ICONS = {
  workspace = wez.nerdfonts.cod_window,
  arrow = wez.nerdfonts.fa_long_arrow_right,
  field = wez.nerdfonts.indent_line,
  dir = wez.nerdfonts.oct_file_directory,
  clock = wez.nerdfonts.md_calendar_clock,
  user = wez.nerdfonts.fa_user,
  host = wez.nerdfonts.md_at,
}

local function get_process(tab)
  return tab.active_pane.foreground_process_name:match("([^/\\]+)%.exe$")
    or tab.active_pane.foreground_process_name:match("([^/\\]+)$")
end

local function get_process_icon(process)
  return PROCESS_ICONS[process] or wez.nerdfonts.seti_checkbox_unchecked
  -- Show activity marker for inactive tabs with unseen output
  -- if not tab.is_active and active_pane.has_unseen_output then
  -- print(wez.nerdfonts.cod_circled_filled  .. formatted_title)
  -- end
end

local function get_cwd(pane)
  local home = os.getenv("HOME") or ""
  local cwd = ""
  local cwd_uri = pane:get_current_working_dir()

  if cwd_uri then
    if type(cwd_uri) == "userdata" and cwd_uri.file_path then
      cwd = cwd_uri.file_path
    else
      cwd_uri = cwd_uri:sub(8)
      local slash = cwd_uri:find("/")
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

local function basename(path)
  return path:match("[^/]+$") or path
end

function M.apply_to_config(config)
  config.enable_tab_bar = true
  config.use_fancy_tab_bar = false
  config.tab_bar_at_bottom = true
  config.show_new_tab_button_in_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = false
  config.tab_max_width = 50

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
        fg_color = scheme.ansi[6],
      },
    },
  }

  config.colors = config.colors or {}
  config.colors = utils.merge(config.colors, colors)

  return config
end

wez.on("format-tab-title", function(tab, _, _, conf)
  local process = get_process(tab)
  local icon = get_process_icon(process)
  local index = tab.tab_index + 1
  local hostname = wez.hostname()
  local dirname = "Unknown"

  -- local curdir = tab.active_pane.get_current_working_dir
  -- if #curdir > 0 then
  --   dirname = basename(curdir)
  -- end

  local formatted_title = string.format("%s %d %s [%s]", icon, index, process, hostname)

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

wez.on("update-status", function(window, pane)
  local palette = window:effective_config().resolved_palette
  local background = palette.tab_bar.background

  -- Left status
  local left_status = {
    { Background = { Color = background } },
  }

  -- Workspace name
  local workspace = window:active_workspace()
  table.insert(left_status, { Text = string.format(" %s  %s ", ICONS.workspace, workspace) })
  table.insert(left_status, { Text = string.format("%s ", ICONS.field) })

  window:set_left_status(wez.format(left_status))

  -- Right status
  local right_status = {
    { Background = { Color = background } },
  }

  -- Current directory with icon
  local cwd = get_cwd(pane)
  if #cwd > 0 then
    table.insert(right_status, { Text = string.format(" %s  %s ", ICONS.dir, cwd) })
    table.insert(right_status, { Text = string.format("%s ", ICONS.field) })
  end

  -- user@host
  table.insert(
    right_status,
    { Text = string.format(" %s  %s %s %s ", ICONS.user, username, ICONS.host, wez.hostname()) }
  )
  table.insert(right_status, { Text = string.format(" %s ", ICONS.field) })

  -- Time
  local time = wez.time.now():format("%H:%M")
  table.insert(right_status, { Text = string.format(" %s  %s  ", ICONS.clock, time) })

  window:set_right_status(wez.format(right_status))
end)

return M

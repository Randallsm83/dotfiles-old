---@diagnostic disable: undefined-field

local wez = require("wezterm")
local utils = require("utilities")
local M = {}

-- Status bar icons
local ICONS = {
  left_hard = wez.nerdfonts.pl_left_hard_divider,
  left_soft = wez.nerdfonts.pl_left_soft_divider,
  right_hard = wez.nerdfonts.pl_right_hard_divider,
  right_soft = wez.nerdfonts.pl_right_soft_divider,
  honeycomb = wez.nerdfonts.ple_honeycomb,
  honeycomb_outlne = wez.nerdfonts.ple_honeycomb_outline,
  arrow = wez.nerdfonts.fa_long_arrow_right,
  field = wez.nerdfonts.indent_line,
  workspace = wez.nerdfonts.cod_window,
  dir = wez.nerdfonts.oct_file_directory,
  clock = wez.nerdfonts.md_calendar_clock,
  user = wez.nerdfonts.fa_user,
  host = wez.nerdfonts.md_at,
  hourglass = wez.nerdfonts.fa_hourglass,
  dev_terminal = wez.nerdfonts.dev_terminal,
  fa_terminal = wez.nerdfonts.fa_terminal,
  oct_terminal = wez.nerdfonts.fa_terminal,
  tab = wez.nerdfonts.oct_tab,
  copy = wez.nerdfonts.oct_copy,
  resize = wez.nerdfonts.oct_arrow_up_right,
  leader = wez.nerdfonts.oct_rocket,
  search = wez.nerdfonts.cod_search
}

-- Process-specific icons
local PROCESS_ICONS = {
  ["debug"] = wez.nerdfonts.cod_debug_console,
  ["zsh"] = wez.nerdfonts.oct_terminal,
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
  ["ls"] = wez.nerdfonts.cod_list_tree,
  ["eza"] = wez.nerdfonts.cod_list_tree,
}

local function get_process_icon(process)
  return PROCESS_ICONS[process] or ICONS.oct_terminal
end

local function basename(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

wez.on("format-tab-title", function(tab, tabs, _, conf)
  local index = tab.tab_index + 1
  local pane = tab.active_pane
  local process = basename(pane.foreground_process_name)
  local icon = get_process_icon(process)
  local host = wez.hostname()
  local ssh = pane.domain_name:match("^SSH[%w]*:(.+)$")
  if ssh then
    host = ssh
    process = "ssh"
    icon = get_process_icon(process)
  end

  -- Show activity marker for inactive tabs with unseen output
  -- if not tab.is_active and active_pane.has_unseen_output then
  -- print(wez.nerdfonts.cod_circled_filled  .. formatted_title)
  -- end

  local formatted_title = string.format("%s [%s]", process, host)

  local width = conf.tab_max_width - 4
  if #formatted_title > conf.tab_max_width then
    formatted_title = wez.truncate_right(formatted_title, width) .. "…"
  end

  if index < #tabs then
    formatted_title = string.format("%s %s ", formatted_title, ICONS.field)
  end

  local palette = conf.resolved_palette
  local fg = tab.is_active and palette.tab_bar.active_tab.fg_color or palette.tab_bar.inactive_tab.fg_color
  local bg = palette.tab_bar.background

  return {
    { Background = { Color = bg } },
    { Foreground = { Color = palette.ansi[6] } },
    { Text = string.format(" %s  ", icon) },
    { Foreground = { Color = fg } },
    { Text = formatted_title },
  }
end)

wez.on("update-status", function(window, pane)
  local palette = window:effective_config().resolved_palette
  local background = palette.tab_bar.background

  -- TODO: figure out quick select, debug and command palette modes? emit events?
  local status_settings = {
    normal = {
      icon = ICONS.fa_terminal,
      color = palette.ansi[5],
      text = "NORMAL",
    },
    leader = {
      icon = ICONS.leader,
      color = palette.ansi[6],
      text = "LEADER",
    },
    copy_mode = {
      icon = ICONS.copy,
      color = palette.ansi[7],
      text = "COPY  ",
    },
    search_mode = {
      icon = ICONS.search,
      color = palette.ansi[4],
      text = "SEARCH",
    },
    resize_pane = {
      icon = ICONS.resize,
      color = palette.ansi[7],
      text = "RESIZE",
    },
    move_tab = {
      icon = ICONS.tab,
      color = palette.ansi[7],
      text = "MOVE  ",
    },
  }

  local status = "normal"
  if window:active_key_table() then
    status = window:active_key_table()
  elseif window:leader_is_active() then
    status = "leader"
  end

  -- Left status
  local left_status = {
    { Foreground = { Color = background } },
    { Background = { Color = status_settings[status].color } },
  }

  -- Mode status
  table.insert(left_status, { Text = string.format("  %s  %s ", status_settings[status].icon, status_settings[status].text) })
  table.insert(left_status, { Foreground = { Color = status_settings[status].color } })
  table.insert(left_status, { Background = { Color = background } })
  table.insert(left_status, { Text = string.format("%s ", wez.nerdfonts.pl_left_hard_divider)})

  window:set_left_status(wez.format(left_status))

  -- Right status
  local right_status = {
    { Background = { Color = background } },
  }

  -- TODO: move to left side with soft divider like right side of lualine. or maybe hard div i dunno

  -- Mux tardiness
  local meta = pane:get_metadata() or {}
  local secs = 0
  if meta.is_tardy then
    secs = meta.since_last_response_ms / 1000.0
  end
  table.insert(right_status, { Text = string.format(" %s%5.1fs ", ICONS.hourglass, secs) })
  table.insert(right_status, { Text = string.format("%s ", ICONS.field) })

  -- Workspace name
  local workspace = window:active_workspace()
  table.insert(right_status, { Text = string.format(" %s  %s ", ICONS.workspace, workspace) })
  table.insert(right_status, { Text = string.format("%s ", ICONS.field) })

  -- Time
  local time = wez.strftime '%m-%d-%y %H:%M'
  table.insert(right_status, { Text = string.format(" %s  %s  ", ICONS.clock, time) })

  window:set_right_status(wez.format(right_status))
end)

function M.apply_to_config(config)
  print(config.key_tables)
  config.tab_max_width = 32
  config.enable_tab_bar = true
  config.use_fancy_tab_bar = false
  config.tab_bar_at_bottom = true
  config.show_new_tab_button_in_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = false

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

return M

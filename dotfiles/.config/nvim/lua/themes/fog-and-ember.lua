-- Fog & Ember / «Туман и янтарь»
-- Цветовая схема для NvChad Base46.
--
-- Основная палитра перенесена из Ghostty/Alacritty.
-- Дополнительные тёмные и серые оттенки получены из неё
-- для интерфейса редактора.

local M = {}

local c = {
  -- Основные цвета
  bg = "#1B222C",
  bg_dark = "#151A22",
  bg_deep = "#11141A",
  fg = "#EAE6DD",
  fg_soft = "#D5D4CE",
  fg_bright = "#F3F0E8",

  -- Тёмные уровни интерфейса
  bg1 = "#202833",
  bg2 = "#26303B",
  bg3 = "#303946",
  selection = "#3B4854",

  -- Серые
  grey = "#46515D",
  grey_search = "#59616C",
  grey_muted = "#727D89",
  grey_comment = "#82909B",
  grey_light = "#94AEBB",

  -- Normal
  red = "#CF6C73",
  green = "#82A184",
  yellow = "#D0A35D",
  blue = "#86A5B6",
  purple = "#A7849B",
  cyan = "#8DAFB1",

  -- Bright
  bright_red = "#E1848A",
  bright_green = "#9DB79F",
  bright_yellow = "#E3BD75",
  bright_blue = "#94AEBB",
  bright_purple = "#C09AAF",
  bright_cyan = "#9AB8BA",

  -- Специальные
  cursor = "#7895A6",
  ember = "#BF8950",
}

-- Цвета интерфейса NvChad:
-- statusline, tabufline, Telescope, NvimTree, меню и диагностика.
M.base_30 = {
  white = c.fg,

  darker_black = c.bg_dark,
  black = c.bg,
  black2 = c.bg1,

  one_bg = c.bg2,
  one_bg2 = c.bg3,
  one_bg3 = c.selection,

  grey = c.grey,
  grey_fg = c.grey_search,
  grey_fg2 = c.grey_muted,
  light_grey = c.grey_light,

  red = c.red,
  baby_pink = c.bright_red,
  pink = c.bright_purple,

  line = c.bg3,

  green = c.green,
  vibrant_green = c.bright_green,

  nord_blue = c.cursor,
  blue = c.blue,

  yellow = c.yellow,
  sun = c.bright_yellow,

  purple = c.purple,
  dark_purple = c.bright_purple,

  teal = c.cyan,
  orange = c.ember,
  cyan = c.bright_cyan,

  statusline_bg = c.bg1,
  lightbg = c.bg3,

  pmenu_bg = c.blue,
  folder_bg = c.blue,
}

-- Base16 отвечает прежде всего за синтаксис.
M.base_16 = {
  base00 = c.bg,
  base01 = c.bg1,
  base02 = c.bg3,
  base03 = c.grey_muted,

  base04 = c.grey_light,
  base05 = c.fg_soft,
  base06 = c.fg,
  base07 = c.fg_bright,

  base08 = c.red,
  base09 = c.ember,
  base0A = c.yellow,
  base0B = c.green,
  base0C = c.cyan,
  base0D = c.blue,
  base0E = c.purple,
  base0F = c.bright_red,
}

M.type = "dark"

M = require("base46").override_theme(M, "fog-and-ember")

-- Точечная адаптация палитры именно под редактор кода.
M.polish_hl = {
  defaults = {
    Visual = {
      bg = c.selection,
      fg = c.fg_bright,
    },

    Search = {
      bg = c.grey_search,
      fg = c.fg_bright,
    },

    IncSearch = {
      bg = c.ember,
      fg = c.bg_deep,
      bold = true,
    },

    CurSearch = {
      bg = c.ember,
      fg = c.bg_deep,
      bold = true,
    },

    MatchParen = {
      bg = c.selection,
      fg = c.bright_yellow,
      bold = true,
    },
  },

  syntax = {
    Comment = {
      fg = c.grey_comment,
      italic = true,
    },

    String = {
      fg = c.green,
    },

    Function = {
      fg = c.blue,
    },

    Keyword = {
      fg = c.purple,
    },

    Type = {
      fg = c.yellow,
    },

    Number = {
      fg = c.ember,
    },

    Operator = {
      fg = c.cursor,
    },
  },

  treesitter = {
    ["@comment"] = {
      fg = c.grey_comment,
      italic = true,
    },

    ["@string"] = {
      fg = c.green,
    },

    ["@string.escape"] = {
      fg = c.bright_cyan,
    },

    ["@function"] = {
      fg = c.blue,
    },

    ["@function.call"] = {
      fg = c.blue,
    },

    ["@function.method"] = {
      fg = c.blue,
    },

    ["@keyword"] = {
      fg = c.purple,
    },

    ["@keyword.function"] = {
      fg = c.purple,
    },

    ["@type"] = {
      fg = c.yellow,
    },

    ["@type.builtin"] = {
      fg = c.bright_yellow,
    },

    ["@number"] = {
      fg = c.ember,
    },

    ["@boolean"] = {
      fg = c.bright_red,
    },

    ["@property"] = {
      fg = c.cyan,
    },

    ["@operator"] = {
      fg = c.cursor,
    },

    ["@punctuation.bracket"] = {
      fg = c.fg_soft,
    },

    ["@punctuation.delimiter"] = {
      fg = c.grey_light,
    },
  },

  telescope = {
    TelescopeSelection = {
      bg = c.selection,
      fg = c.fg_bright,
    },

    TelescopeMatching = {
      fg = c.bright_yellow,
      bold = true,
    },
  },

  nvimtree = {
    NvimTreeFolderIcon = {
      fg = c.blue,
    },

    NvimTreeOpenedFolderName = {
      fg = c.bright_yellow,
      bold = true,
    },
  },
}

return M

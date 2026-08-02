---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "fog-and-ember",
  theme_toggle = { "fog-and-ember", "gruvbox" },
  transparency = true,

  hl_override = {
    -- основной фон
    Normal       = { bg = "none" },
    NormalNC     = { bg = "none" },
    NormalFloat  = { bg = "none" },
    FloatBorder  = { bg = "none" },
    SignColumn   = { bg = "none" },

    -- номера строк / курсор
    LineNr       = { bg = "none" },
    CursorLine   = { bg = "none" },
    CursorLineNr = { bg = "none" },

    -- статуслайн и разделители
    StatusLine   = { bg = "none" },
    StatusLineNC = { bg = "none" },
    WinSeparator = { bg = "none" },

    -- табы / tabline (если вдруг не устраивает)
    TabLine      = { bg = "none" },
    TabLineFill  = { bg = "none" },
    TabLineSel   = { bg = "none" },

    -- tabufline из NvChad (верхняя панель буферов)
    TbLineFill          = { bg = "none" },
    TbLineBufOn         = { bg = "none" },
    TbLineBufOff        = { bg = "none" },
    TbLineBufOnModified = { bg = "none" },
    TbLineBufOffModified= { bg = "none" },
    TbLineTabOn         = { bg = "none" },
    TbLineTabOff        = { bg = "none" },
    TbLineThemeToggleBtn= { bg = "none" },

    -- NvimTree
    NvimTreeNormal   = { bg = "none" },
    NvimTreeNormalNC = { bg = "none" },

    -- всякое «яркое»
    -- Visual     = { bg = "none" },
    ErrorMsg   = { bg = "none" },
    Folded     = { bg = "none" },
    DiffAdd    = { bg = "none" },
    DiffChange = { bg = "none" },
    DiffDelete = { bg = "none" },
    DiffText   = { bg = "none" },
  },
}

return M

-- -- This file needs to have same structure as nvconfig.lua
-- -- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- -- Please read that file to know all available options :(
--
-- ---@type ChadrcConfig
-- local M = {}
--
-- M.base46 = {
-- 	-- theme = "onedark",
-- 	theme = "gruvchad"
--
-- 	-- hl_override = {
-- 	-- 	Comment = { italic = true },
-- 	-- 	["@comment"] = { italic = true },
-- 	-- },
-- }
--
-- -- M.nvdash = { load_on_startup = true }
-- -- M.ui = {
-- --       tabufline groovbox
-- --          lazyload = false
-- --      }
-- -- }
--
-- return M

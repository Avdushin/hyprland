vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    repo,
    "--branch=stable",
    lazypath,
  }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
-- Base46 хранит скомпилированные цвета в stdpath("data")/base46.
-- Если кэш удалён или конфиг разворачивается на новой системе,
-- создаём его перед первым dofile.
local base46_defaults = vim.g.base46_cache .. "defaults"

if not vim.uv.fs_stat(base46_defaults) then
  require("base46").compile()
end

dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds"
require "notes"

vim.schedule(function()
  require "mappings"
  require "russian_keymap"
  require "visual_surround"
end)

-- vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
-- vim.g.mapleader = " "
--
-- -- bootstrap lazy and all plugins
-- local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
--
-- if not vim.uv.fs_stat(lazypath) then
--   local repo = "https://github.com/folke/lazy.nvim.git"
--   vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
-- end
--
-- vim.opt.rtp:prepend(lazypath)
--
-- local lazy_config = require "configs.lazy"
--
-- -- load plugins
-- require("lazy").setup({
--   {
--     "NvChad/NvChad",
--     lazy = false,
--     branch = "v2.5",
--     import = "nvchad.plugins",
--   },
--
--   { import = "plugins" },
-- }, lazy_config)
--
-- -- load theme
-- dofile(vim.g.base46_cache .. "defaults")
-- dofile(vim.g.base46_cache .. "statusline")
--
-- require "options"
-- require "autocmds"
-- require "notes"
--
-- vim.schedule(function()
--   require "mappings"
-- end)

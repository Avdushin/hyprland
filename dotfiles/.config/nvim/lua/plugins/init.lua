return {
    -- Legacy nvim-treesitter для старого NvChad v2.5.
  -- Внутри установлен патч совместимости с Neovim 0.12.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    pin = true,
  },
  {
    "stevearc/conform.nvim",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
 {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },
  -- === Markdown render (как в Obsidian) ===
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons", -- NvChad обычно уже имеет иконки
    },
    opts = {
      -- Оставляем дефолты — уже красиво работает.
      -- Если захочешь кастомную тему — могу сделать.
    },
  },
  -- === Multicursor (vim-visual-multi) ===
  {
    "mg979/vim-visual-multi",
    branch = "master",
    lazy = false, -- грузим сразу
    init = function()
      -- вырубаем дефолтные бинды плагина
      vim.g.VM_default_mappings = 0

      -- настраиваем всё под Ctrl+D
      vim.g.VM_maps = {
        ["Add Cursor Down"] = "<A-j>",
        ["Add Cursor Up"] = "<A-k>",

        -- как в VS Code / Sublime
        ["Find Under"] = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
        ["Select Next"] = "<C-d>",

        -- назад по совпадениям (Alt+D, чтобы не трогать Ctrl+N)
        ["Select Prev"] = "<A-d>",
      }
    end,
  },
  -- {
  --   "mg979/vim-visual-multi",
  --   branch = "master",
  --   lazy = false, -- грузим сразу, без ленивости
  --   init = function()
  --     -- отключаем дефолтные бинды плагина
  --     vim.g.VM_default_mappings = 0
  --   end,
  --   config = function()
  --     -- Бинды уже после загрузки плагина (Plug- map'ы точно существуют)
  --
  --     -- Ctrl+D: выбрать слово под курсором / следующее вхождение
  --     vim.keymap.set({ "n", "x" }, "<C-d>", "<Plug>(VM-Find-Under)", {
  --       noremap = false,
  --       silent = true,
  --       desc = "Multi-cursor: find next occurrence",
  --     })
  --
  --     -- Alt+D: предыдущее вхождение (назад)
  --     vim.keymap.set({ "n", "x" }, "<A-d>", "<Plug>(VM-Select-Prev)", {
  --       noremap = false,
  --       silent = true,
  --       desc = "Multi-cursor: select previous occurrence",
  --     })
  --   end,
  -- },
  -- === Images in Neovim ===
  {
    "3rd/image.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    build = false, -- чтобы не пытался собирать luarocks-рок
    opts = {
      -- backend = "ueberzug", -- для Alacritty
      backend = "kitty",
      processor = "magick_cli", -- дефолтный вариант через CLI ImageMagick

      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          only_render_image_at_cursor_mode = "popup", -- или "inline"
          floating_windows = false,
          filetypes = { "markdown" },
        },
      },

      max_width = 80,
      max_height = 40,
      max_width_window_percentage = 50,
      max_height_window_percentage = 50,
    },
  },
}

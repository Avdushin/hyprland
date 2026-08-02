return {
  -- сам источник для nvim-cmp
  {
    "tzachar/cmp-tabnine",
    build = "./install.sh", -- скачает бинарник TabNine
    dependencies = "hrsh7th/nvim-cmp",
    event = "InsertEnter", -- грузим только при входе в insert
    config = function()
      local tabnine = require "cmp_tabnine.config"

      tabnine:setup {
        max_lines = 1000,
        max_num_results = 20,
        sort = true,
        run_on_every_keystroke = true,
        snippet_placeholder = "..",
        ignored_file_types = {},
        show_prediction_strength = false,
      }
    end,
  },

  -- допиливаем nvim-cmp, чтобы он знал про источник cmp_tabnine
  {
    "hrsh7th/nvim-cmp",
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      -- добавляем TabNine как один из sources (можешь сместить приоритет)
      table.insert(opts.sources, 1, { name = "cmp_tabnine" })
      return opts
    end,
  },
}

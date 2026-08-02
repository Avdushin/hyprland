return {
  {
    "hrsh7th/nvim-cmp",
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local cmp = require "cmp"

      -- аккуратно расширяем уже существующие mapping'и NvChad
      opts.mapping = vim.tbl_extend("force", opts.mapping or {}, {
        ["<Down>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          else
            fallback()
          end
        end, { "i", "c" }),

        ["<Up>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end, { "i", "c" }),
      })

      return opts
    end,
  },
}

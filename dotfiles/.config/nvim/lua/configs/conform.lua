local options = {
  formatters_by_ft = {
    -- Lua
    lua = { "stylua" },

    -- Web stack
    html = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    json = { "prettier" },
    markdown = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },

    -- Backend languages
    python = { "black" },
    go = { "gofmt" },
    rust = { "rustfmt" },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options

-- local options = {
--   formatters_by_ft = {
--     lua = { "stylua" },
--     -- css = { "prettier" },
--     -- html = { "prettier" },
--   },

--   -- format_on_save = {
--   --   -- These options will be passed to conform.format()
--   --   timeout_ms = 500,
--   --   lsp_fallback = true,
--   -- },
-- }

-- return options

require("nvchad.configs.lspconfig").defaults()

-- Список LSP-серверов, которые надо включить
local servers = {
  "html", -- html-lsp
  "cssls", -- css-lsp

  "tsserver", -- TypeScript / JavaScript
  "jsonls", -- JSON
  "marksman", -- Markdown

  "rust_analyzer", -- Rust
  "gopls", -- Go
  "pyright", -- Python (если пользуешь)
}

vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers

return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {
      "mason-org/mason.nvim",
    },

    opts = {
      ensure_installed = {
        "html-lsp",
        "css-lsp",
        "typescript-language-server",
        "json-lsp",
        "marksman",
        "rust-analyzer",
        "gopls",
        "pyright",
        "emmet-language-server",
      },

      -- Не устанавливаем всё при каждом обычном запуске Neovim.
      -- install.sh вызовет MasonToolsInstallSync сам.
      run_on_start = false,
      auto_update = false,
    },
  },
}

return {
  "nvim-tree/nvim-tree.lua",

  opts = function(_, opts)
    opts = opts or {}
    opts.renderer = opts.renderer or {}

    -- Показываем только имя корневой папки дерева, а не полный путь.
    opts.renderer.root_folder_label = function(path)
      local name = vim.fs.basename(path)
      return "󰉋  " .. (name ~= "" and name or path)
    end

    return opts
  end,
}

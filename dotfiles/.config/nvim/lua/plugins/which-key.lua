return {
  {
    "folke/which-key.nvim",

    -- NvChad использует Ctrl+W для ленивой загрузки WhichKey.
    -- Убираем его, поскольку Ctrl+W у нас закрывает текущий buffer.
    keys = function(_, keys)
      return vim.tbl_filter(function(key)
        local lhs = type(key) == "table" and key[1] or key

        if type(lhs) ~= "string" then
          return true
        end

        return lhs:lower() ~= "<c-w>"
      end, keys)
    end,
  },
}

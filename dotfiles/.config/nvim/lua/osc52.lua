local M = {}

function M.copy(lines, _)
  local text = table.concat(lines, "\n")
  require("osc52").copy(text)
end

function M.paste()
  return { vim.fn.split(vim.fn.getreg('"'), "\n") }, vim.fn.getregtype('"')
end

return M


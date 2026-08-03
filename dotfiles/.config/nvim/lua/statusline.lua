local M = {}

local api = vim.api

local language_names = {
  bash = "Bash",
  c = "C",
  cpp = "C++",
  css = "CSS",
  dockerfile = "Dockerfile",
  go = "Go",
  html = "HTML",
  javascript = "JavaScript",
  javascriptreact = "JSX",
  json = "JSON",
  jsonc = "JSONC",
  lua = "Lua",
  markdown = "Markdown",
  python = "Python",
  rust = "Rust",
  sh = "Shell",
  toml = "TOML",
  typescript = "TypeScript",
  typescriptreact = "TSX",
  yaml = "YAML",
  zsh = "Zsh",
}

local function statusline_bufnr()
  local win = tonumber(vim.g.statusline_winid)

  if win and api.nvim_win_is_valid(win) then
    return api.nvim_win_get_buf(win)
  end

  return api.nvim_get_current_buf()
end

local function lsp_is_attached(bufnr)
  return #vim.lsp.get_clients { bufnr = bufnr } > 0
end

local function filetype_label(filetype)
  local label = language_names[filetype]

  if label then
    return label
  end

  return filetype:gsub("_", " "):gsub("^%l", string.upper)
end

local function filetype_icon(bufnr)
  local ok, devicons = pcall(require, "nvim-web-devicons")

  if not ok then
    return "󰈙"
  end

  local path = api.nvim_buf_get_name(bufnr)
  local filename = path ~= "" and vim.fs.basename(path) or ""
  local extension = filename:match "%.([^%.]+)$"
  local icon = devicons.get_icon(filename, extension, { default = true })

  return icon or "󰈙"
end

-- Язык текущего файла. Галочка слева означает, что к буферу подключён LSP.
function M.language()
  local bufnr = statusline_bufnr()
  local filetype = vim.bo[bufnr].filetype

  if filetype == "" then
    return ""
  end

  local connected = lsp_is_attached(bufnr) and "%#St_lspInfo#  " or ""
  local language = filetype_icon(bufnr) .. " " .. filetype_label(filetype)

  return connected .. "%#St_Lsp# " .. language .. " "
end

-- Диагностика текущего буфера. При отсутствии ошибок показывает вторую галочку.
function M.diagnostics()
  local bufnr = statusline_bufnr()
  local counts = {
    [vim.diagnostic.severity.ERROR] = 0,
    [vim.diagnostic.severity.WARN] = 0,
    [vim.diagnostic.severity.INFO] = 0,
    [vim.diagnostic.severity.HINT] = 0,
  }

  for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
    counts[diagnostic.severity] = (counts[diagnostic.severity] or 0) + 1
  end

  local total = counts[vim.diagnostic.severity.ERROR]
    + counts[vim.diagnostic.severity.WARN]
    + counts[vim.diagnostic.severity.INFO]
    + counts[vim.diagnostic.severity.HINT]

  if total == 0 then
    if lsp_is_attached(bufnr) then
      return "%#St_lspInfo#  clean "
    end

    return ""
  end

  local parts = {}

  if counts[vim.diagnostic.severity.ERROR] > 0 then
    parts[#parts + 1] = "%#St_lspError# " .. counts[vim.diagnostic.severity.ERROR]
  end

  if counts[vim.diagnostic.severity.WARN] > 0 then
    parts[#parts + 1] = "%#St_lspWarning# " .. counts[vim.diagnostic.severity.WARN]
  end

  if counts[vim.diagnostic.severity.HINT] > 0 then
    parts[#parts + 1] = "%#St_lspHints#󰌵 " .. counts[vim.diagnostic.severity.HINT]
  end

  if counts[vim.diagnostic.severity.INFO] > 0 then
    parts[#parts + 1] = "%#St_lspInfo# " .. counts[vim.diagnostic.severity.INFO]
  end

  return " " .. table.concat(parts, " ") .. " "
end

return M

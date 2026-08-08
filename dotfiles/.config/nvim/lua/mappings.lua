require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Go to definition
map("n", "gd", vim.lsp.buf.definition, {
  silent = true,
  desc = "Go to definition",
})

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Toggle file tree with Ctrl+b
map("n", "<C-b>", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })

-- Format code on Ctrl+Shift+I
map("n", "<C-S-i>", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "Format code" })

-- Bottom terminal (Ctrl + `)
-- Сохраняет shell-сессию и установленную вручную высоту окна.
map({ "n", "t" }, "<C-`>", function()
  require("bottom_terminal").toggle()
end, { desc = "Toggle persistent bottom terminal" })

-- Right terminal (Ctrl + e)
map({ "n", "t" }, "<C-e>", function()
  require("nvchad.term").toggle { id = 2, pos = "vsp", size = 0.3 }
end, { desc = "Right terminal" })


-- File search like VS Code: Ctrl + P
map("n", "<C-p>", function()
  require("telescope.builtin").find_files {
    find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
  }
end, { desc = "Find files via ripgrep" })

-- Jump to buffer N (like tabs 1..9)
for i = 1, 9 do
  map("n", "<C-" .. i .. ">", function()
    local bufs = vim.t.bufs or {}
    if bufs[i] then
      vim.api.nvim_set_current_buf(bufs[i])
    end
  end, { desc = "Go to buffer " .. i })
end

-- New buffer (tab) on Ctrl + N
map("n", "<C-n>", function()
  vim.cmd "enew"
end, { desc = "New buffer" })

-- Close current buffer (tab) on Ctrl + W
map("n", "<C-w>", function()
  require("nvchad.tabufline").close_buffer()
end, {
  silent = true,
  nowait = true,
  desc = "Close current buffer",
})

-- Copy relative path of current file to clipboard (Alt + Shift + C)
map("n", "<leader>c", function()
  local path = vim.fn.expand "%"

  if path == "" then
    vim.notify("Текущий буфер не связан с файлом", vim.log.levels.WARN)
    return
  end

  vim.fn.setreg("+", path) -- системный буфер
  vim.fn.setreg("*", path) -- буфер X11/Wayland (на всякий)
  vim.notify("Скопирован путь: " .. path, vim.log.levels.INFO)
end, { desc = "Copy relative file path" })

-- Duplicate current line down
map("n", "<leader>d", "yyp", { desc = "Duplicate line down" })

-- Двигать текущую строку вверх/вниз (NORMAL)
map("n", "<C-S-Down>", ":m .+1<CR>==", opts)
map("n", "<C-S-Up>", ":m .-2<CR>==", opts)

-- Двигать выделение вверх/вниз (VISUAL)
map("v", "<C-S-Down>", ":m '>+1<CR>gv=gv", opts)
map("v", "<C-S-Up>", ":m '<-2<CR>gv=gv", opts)

map("i", "<C-S-Down>", "<Esc>:m .+1<CR>==gi", opts)
map("i", "<C-S-Up>", "<Esc>:m .-2<CR>==gi", opts)

-- Чтобы оборачивать слова в (s) -> ("s")

-- Обернуть содержимое () в кавычки по <leader>"
vim.keymap.set("n", '<leader>"', function()
  vim.cmd.normal { "yi(", bang = true }
  local text = vim.fn.getreg "0"
  vim.cmd.normal { "ci(", bang = true }
  vim.api.nvim_put({ '"' .. text .. '"' }, "c", true, true)
end, { silent = true, desc = 'Wrap () content in ""' })

-- Переключение кавычек (" → ' → ` → ")
vim.keymap.set("n", "<leader>q", function()
  vim.cmd.normal { "yi(", bang = true }
  local text = vim.fn.getreg "0"

  local first = text:sub(1, 1)
  local last = text:sub(-1)
  local body = text
  if (first == '"' or first == "'" or first == "`") and first == last then
    body = text:sub(2, -2)
  end

  local new_q
  if first == '"' then
    new_q = "'"
  elseif first == "'" then
    new_q = "`"
  else
    new_q = '"'
  end

  vim.cmd.normal { "ci(", bang = true }
  vim.api.nvim_put({ new_q .. body .. new_q }, "c", true, true)
end, { silent = true, desc = "Cycle quotes inside ()" })

-- Двигать строку в INSERT, оставаясь в insert-режиме
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- ============================================================
-- Search and replace with Grug FAR
-- ============================================================

-- Определяет разумную область поиска:
-- 1. корень Git-проекта;
-- 2. вне Git — папка текущего файла;
-- 3. для безымянного буфера — текущий рабочий каталог.
local function grug_far_root()
  local file = vim.api.nvim_buf_get_name(0)

  local start
  if file ~= "" then
    start = vim.fs.dirname(file)
  else
    start = vim.fn.getcwd()
  end

  local git_dir = vim.fs.find(".git", {
    path = start,
    upward = true,
    type = "directory",
    limit = 1,
  })[1]

  if git_dir then
    return vim.fs.dirname(git_dir)
  end

  return start
end

local function open_grug_far()
  require("grug-far").open {
    prefills = {
      paths = grug_far_root(),
    },
  }
end

-- Ctrl+Shift+F — найти и заменить в проекте/папке файла
map("n", "<C-S-f>", open_grug_far, {
  silent = true,
  desc = "Find and replace in project",
})

-- Space → s → r — запасное сочетание
map("n", "<leader>sr", open_grug_far, {
  silent = true,
  desc = "Find and replace in project",
})

-- Space → s → f — найти и заменить только в текущем файле
map("n", "<leader>sf", function()
  local file = vim.api.nvim_buf_get_name(0)

  if file == "" then
    vim.notify("Текущий буфер не связан с файлом", vim.log.levels.WARN)
    return
  end

  require("grug-far").open {
    prefills = {
      paths = file,
    },
  }
end, {
  silent = true,
  desc = "Find and replace in current file",
})

-- Space → s → w — подставить слово под курсором
map("n", "<leader>sw", function()
  require("grug-far").open {
    prefills = {
      search = vim.fn.expand "<cword>",
      paths = grug_far_root(),
    },
  }
end, {
  silent = true,
  desc = "Replace word under cursor",
})

-- Toggle Fog & Ember / Gruvbox
-- Space → u → t
map("n", "<leader>ut", function()
  require("base46").toggle_theme()
end, {
  silent = true,
  desc = "Toggle Fog & Ember / Gruvbox",
})

-- Markdown images: toggle image.nvim
-- Space -> m -> i
map("n", "<leader>mi", function()
  local ok, image = pcall(require, "image")

  if not ok then
    vim.notify("image.nvim не загружен", vim.log.levels.ERROR)
    return
  end

  if image.is_enabled() then
    image.disable()
    vim.notify "Изображения Markdown выключены"
  else
    image.enable()
    vim.notify "Изображения Markdown включены"
  end
end, {
  silent = true,
  desc = "Toggle Markdown images",
})

-- Диагностический отчёт image.nvim
map("n", "<leader>mI", "<cmd>ImageReport<cr>", {
  silent = true,
  desc = "Markdown image report",
})

-- BEGIN persistent floating terminal
-- Один терминальный буфер и одна сохраняемая shell-сессия.
local function toggle_persistent_floating_terminal()
  require("floating_terminal").toggle()
end

map({ "n", "t" }, "<C-S-t>", toggle_persistent_floating_terminal, {
  silent = true,
  desc = "Toggle persistent floating terminal",
})

map("n", "<leader>tt", toggle_persistent_floating_terminal, {
  silent = true,
  desc = "Toggle persistent floating terminal",
})
-- END persistent floating terminal

-- ============================================================
-- Find text in current file
-- ============================================================

-- Normal mode: сразу открыть поиск.
map("n", "<C-f>", "/", {
  silent = false,
  desc = "Find text in current file",
})

-- Insert / Visual / Select mode:
-- сначала перейти в Normal mode, затем открыть поиск.
map({ "i", "x", "s" }, "<C-f>", "<Esc>/", {
  silent = false,
  desc = "Find text in current file",
})

-- ============================================================
-- Window splits
-- ============================================================

map("n", "<leader>v", "<cmd>vsplit<CR>", {
  desc = "Vertical split",
})

map("n", "<leader>h", "<cmd>split<CR>", {
  desc = "Horizontal split",
})

-- Resize splits
map("n", "<leader><Right>", "<cmd>vertical resize +5<CR>", {
  desc = "Increase window width",
})

map("n", "<leader><Left>", "<cmd>vertical resize -5<CR>", {
  desc = "Decrease window width",
})

map("n", "<leader><Down>", "<cmd>resize +3<CR>", {
  desc = "Increase window height",
})

map("n", "<leader><Up>", "<cmd>resize -3<CR>", {
  desc = "Decrease window height",
})

map("n", "<leader>=", "<cmd>wincmd =<CR>", {
  desc = "Equalize splits",
})

-- ============================================================
-- Save
-- ============================================================

map({ "n", "i" }, "<C-s>", "<cmd>w<CR>", {
  desc = "Save file",
})

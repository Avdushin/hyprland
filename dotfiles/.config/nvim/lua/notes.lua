local M = {}
local uv = vim.uv or vim.loop
local notes_root = vim.fs.normalize(vim.fn.expand("~/Workspace/notes"))
local inbox = notes_root .. "/inbox"
local draft = notes_root .. "/draft.md"

local function ensure_dirs()
  vim.fn.mkdir(inbox, "p")
end

local function edit(path)
  ensure_dirs()
  vim.cmd.edit(vim.fn.fnameescape(path))
end

local function slug(title)
  title = vim.trim(title or "")
  title = title:gsub("[/\\:%z]", "-"):gsub("%s+", "-")
  title = title:gsub("%-+", "-"):gsub("^%-", ""):gsub("%-$", "")
  if title == "" then
    title = "note"
  end
  return title
end

vim.api.nvim_create_user_command("Draft", function()
  edit(draft)
end, {})

vim.api.nvim_create_user_command("Note", function(opts)
  local title = opts.args
  if title == "" then
    title = vim.fn.input("Название заметки: ")
  end
  local filename = os.date("%Y-%m-%d_%H-%M-%S_") .. slug(title) .. ".md"
  local path = inbox .. "/" .. filename
  edit(path)
  if vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_get_current_line() == "" then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "# " .. (title ~= "" and title or "Заметка"),
      "",
      "Создано: " .. os.date("%Y-%m-%d %H:%M"),
      "",
    })
    vim.cmd("startinsert!")
  end
end, { nargs = "*" })

vim.api.nvim_create_user_command("Notes", function()
  ensure_dirs()
  require("telescope.builtin").find_files({ cwd = notes_root, hidden = true, prompt_title = "Notes" })
end, {})

vim.api.nvim_create_user_command("Scratch", function()
  vim.cmd.enew()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "scratch://" .. os.date("%Y%m%d-%H%M%S"))
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].undofile = false
  vim.bo[buf].filetype = "markdown"
  vim.cmd("startinsert!")
end, {})

vim.api.nvim_create_user_command("ClipEdit", function()
  vim.cmd.enew()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "clipedit://" .. os.date("%Y%m%d-%H%M%S"))
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].undofile = false
  vim.bo[buf].filetype = "text"
  local text = vim.fn.getreg("+")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
  vim.bo[buf].modified = false
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      vim.fn.setreg("+", table.concat(lines, "\n"))
      vim.bo[buf].modified = false
      vim.notify("Текст скопирован обратно в clipboard")
    end,
  })
end, {})

local autosave = vim.api.nvim_create_augroup("WorkbenchNotesAutosave", { clear = true })
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertLeave" }, {
  group = autosave,
  callback = function(args)
    local name = vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf))
    if name:sub(1, #notes_root) ~= notes_root then
      return
    end
    if vim.bo[args.buf].modified and vim.bo[args.buf].modifiable and vim.bo[args.buf].buftype == "" then
      pcall(vim.api.nvim_buf_call, args.buf, function()
        vim.cmd("silent update")
      end)
    end
  end,
})

vim.keymap.set("n", "<leader>nd", "<cmd>Draft<cr>", { desc = "Open draft" })
vim.keymap.set("n", "<leader>nn", "<cmd>Note<cr>", { desc = "New note" })
vim.keymap.set("n", "<leader>nf", "<cmd>Notes<cr>", { desc = "Find notes" })
vim.keymap.set("n", "<leader>ns", "<cmd>Scratch<cr>", { desc = "Temporary scratch" })
vim.keymap.set("n", "<leader>nc", "<cmd>ClipEdit<cr>", { desc = "Edit clipboard" })

return M

local M = {}

local state = {
  buf = nil,
  win = nil,
}

local function valid_buf()
  return state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

local function valid_win()
  return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function window_config()
  local width = math.max(40, math.floor(vim.o.columns * 0.82))
  local height = math.max(10, math.floor(vim.o.lines * 0.72))

  width = math.min(width, vim.o.columns - 4)
  height = math.min(height, vim.o.lines - 4)

  return {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
  }
end

local function close_window()
  if valid_win() then
    vim.api.nvim_win_close(state.win, true)
  end

  state.win = nil
end

local function set_window_options()
  if not valid_win() then
    return
  end

  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"
end

local function create_terminal_buffer()
  state.buf = vim.api.nvim_create_buf(false, true)

  vim.bo[state.buf].bufhidden = "hide"
  vim.bo[state.buf].buflisted = false
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].filetype = "FloatingTerminal"

  state.win = vim.api.nvim_open_win(state.buf, true, window_config())

  set_window_options()

  vim.fn.termopen(vim.o.shell, {
    on_exit = function()
      close_window()

      if valid_buf() then
        pcall(vim.api.nvim_buf_delete, state.buf, {
          force = true,
        })
      end

      state.buf = nil
    end,
  })
end

local function show_existing_buffer()
  state.win = vim.api.nvim_open_win(state.buf, true, window_config())

  set_window_options()
end

function M.toggle()
  if valid_win() then
    close_window()
    return
  end

  if valid_buf() then
    show_existing_buffer()
  else
    create_terminal_buffer()
  end

  vim.cmd "startinsert"
end

function M.close()
  close_window()
end

return M

local M = {}

local api = vim.api

local state = {
  buf = nil,
  win = nil,
  job = nil,
  height = nil,
}

local group = api.nvim_create_augroup("PersistentBottomTerminal", { clear = true })

local function valid_buf()
  return state.buf and api.nvim_buf_is_valid(state.buf)
end

local function valid_win()
  return state.win and api.nvim_win_is_valid(state.win)
end

local function default_height()
  return math.max(8, math.floor(vim.o.lines * 0.3))
end

local function remember_height()
  if valid_win() then
    state.height = api.nvim_win_get_height(state.win)
  end
end

local function configure_window()
  local win = state.win

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].statuscolumn = ""
  vim.wo[win].winfixheight = false
end

local function open_window()
  local visible_win = valid_buf() and vim.fn.bufwinid(state.buf) or -1

  if visible_win ~= -1 then
    state.win = visible_win
    api.nvim_set_current_win(visible_win)
    return
  end

  vim.cmd "botright split"
  state.win = api.nvim_get_current_win()
  api.nvim_win_set_buf(state.win, state.buf)

  local max_height = math.max(3, vim.o.lines - 4)
  local height = math.min(state.height or default_height(), max_height)
  api.nvim_win_set_height(state.win, height)

  configure_window()
end

local function close_window()
  if not valid_win() then
    state.win = nil
    return
  end

  remember_height()
  api.nvim_win_close(state.win, true)
  state.win = nil
end

local function reset_state()
  state.buf = nil
  state.win = nil
  state.job = nil
end

local function create_terminal()
  state.buf = api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = "hide"
  vim.bo[state.buf].buflisted = false
  vim.bo[state.buf].swapfile = false

  open_window()

  local buf = state.buf
  state.job = vim.fn.termopen({ vim.o.shell }, {
    detach = false,
    on_exit = function()
      vim.schedule(function()
        if state.buf ~= buf then
          return
        end

        if valid_win() then
          api.nvim_win_close(state.win, true)
        end

        if api.nvim_buf_is_valid(buf) then
          api.nvim_buf_delete(buf, { force = true })
        end

        reset_state()
      end)
    end,
  })

  vim.bo[state.buf].filetype = "PersistentBottomTerminal"

  api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = state.buf,
    once = true,
    callback = function()
      if state.buf == buf then
        reset_state()
      end
    end,
  })
end

api.nvim_create_autocmd("WinResized", {
  group = group,
  callback = remember_height,
})

function M.toggle()
  if valid_win() then
    close_window()
    return
  end

  if not valid_buf() then
    create_terminal()
  else
    open_window()
  end

  vim.cmd "startinsert"
end

return M

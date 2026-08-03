-- Последовательное оборачивание Visual-выделения.
--
-- После оборачивания исходный текст остаётся выделенным:
--
--   text
--   "text"
--   ""text""
--   """text"""
--
-- Для Shift+V и нескольких строк обрамление размещается
-- на отдельных строках и увеличивается при каждом нажатии.

local wrappers = {
  ['"'] = { open = '"', close = '"' },
  ["'"] = { open = "'", close = "'" },
  ["`"] = { open = "`", close = "`" },

  ["("] = { open = "(", close = ")" },
  [")"] = { open = "(", close = ")" },

  ["["] = { open = "[", close = "]" },
  ["]"] = { open = "[", close = "]" },

  ["{"] = { open = "{", close = "}" },
  ["}"] = { open = "{", close = "}" },

  ["<"] = { open = "<", close = ">" },
  [">"] = { open = "<", close = ">" },

  -- Физические клавиши русской раскладки.
  ["э"] = { open = "'", close = "'" },
  ["Э"] = { open = '"', close = '"' },

  ["ё"] = { open = "`", close = "`" },
  ["Ё"] = { open = "`", close = "`" },

  ["х"] = { open = "[", close = "]" },
  ["ъ"] = { open = "[", close = "]" },

  ["Х"] = { open = "{", close = "}" },
  ["Ъ"] = { open = "{", close = "}" },

  -- Физические клавиши < и > в русской раскладке.
  ["Б"] = { open = "<", close = ">" },
  ["Ю"] = { open = "<", close = ">" },
}

local esc = vim.api.nvim_replace_termcodes(
  "<Esc>",
  true,
  false,
  true
)

local function leave_visual_mode()
  vim.api.nvim_feedkeys(esc, "nx", false)
end

local function normalize_range(anchor, cursor)
  local first = {
    row = anchor[2],
    col = anchor[3] - 1,
  }

  local last = {
    row = cursor[2],
    col = cursor[3] - 1,
  }

  if first.row > last.row
    or (first.row == last.row and first.col > last.col)
  then
    first, last = last, first
  end

  return first, last
end

local function byte_after_character(line, byte_col)
  local character_index = vim.fn.charidx(line, byte_col)
  local next_byte = vim.fn.byteidx(line, character_index + 1)

  if next_byte < 0 then
    return #line
  end

  return next_byte
end

local function select_characterwise(win, first, last)
  vim.api.nvim_win_call(win, function()
    vim.api.nvim_win_set_cursor(win, {
      first.row,
      first.col,
    })

    vim.cmd "normal! v"

    vim.api.nvim_win_set_cursor(win, {
      last.row,
      last.col,
    })
  end)
end

local function select_linewise(win, first_row, last_row)
  vim.api.nvim_win_call(win, function()
    vim.api.nvim_win_set_cursor(win, {
      first_row,
      0,
    })

    vim.cmd "normal! V"

    vim.api.nvim_win_set_cursor(win, {
      last_row,
      0,
    })
  end)
end

local function wrap_characterwise(buf, win, first, last, wrapper)
  local last_line = vim.api.nvim_buf_get_lines(
    buf,
    last.row - 1,
    last.row,
    false
  )[1] or ""

  local close_col = byte_after_character(
    last_line,
    last.col
  )

  -- Сначала вставляем закрывающий символ, чтобы позиция начала
  -- выделения ещё не успела сдвинуться.
  vim.api.nvim_buf_set_text(
    buf,
    last.row - 1,
    close_col,
    last.row - 1,
    close_col,
    { wrapper.close }
  )

  vim.api.nvim_buf_set_text(
    buf,
    first.row - 1,
    first.col,
    first.row - 1,
    first.col,
    { wrapper.open }
  )

  local new_first = {
    row = first.row,
    col = first.col + #wrapper.open,
  }

  local new_last = {
    row = last.row,
    col = last.col,
  }

  -- Если выделение находится на одной строке, открывающий символ
  -- сдвинул также конец выделения.
  if first.row == last.row then
    new_last.col = new_last.col + #wrapper.open
  end

  select_characterwise(
    win,
    new_first,
    new_last
  )
end

local function wrap_single_linewise(buf, win, row, wrapper)
  local line = vim.api.nvim_buf_get_lines(
    buf,
    row - 1,
    row,
    false
  )[1] or ""

  -- Не включаем в оборачивание отступ и пробелы в конце.
  local without_trailing_spaces = line:gsub("%s+$", "")
  local first_nonblank = without_trailing_spaces:find "%S"

  -- Пустая строка.
  if not first_nonblank then
    local col = #line

    vim.api.nvim_buf_set_text(
      buf,
      row - 1,
      col,
      row - 1,
      col,
      { wrapper.open .. wrapper.close }
    )

    vim.api.nvim_win_set_cursor(
      win,
      {
        row,
        col + #wrapper.open,
      }
    )

    return
  end

  local start_col = first_nonblank - 1
  local close_col = #without_trailing_spaces

  local character_count = vim.fn.strchars(
    without_trailing_spaces
  )

  local last_character_col = vim.fn.byteidx(
    without_trailing_spaces,
    character_count - 1
  )

  vim.api.nvim_buf_set_text(
    buf,
    row - 1,
    close_col,
    row - 1,
    close_col,
    { wrapper.close }
  )

  vim.api.nvim_buf_set_text(
    buf,
    row - 1,
    start_col,
    row - 1,
    start_col,
    { wrapper.open }
  )

  select_characterwise(
    win,
    {
      row = row,
      col = start_col + #wrapper.open,
    },
    {
      row = row,
      col = last_character_col + #wrapper.open,
    }
  )
end

local function repeated_token_count(line, indent, token)
  if line:sub(1, #indent) ~= indent then
    return nil
  end

  local rest = line:sub(#indent + 1)

  if rest == "" then
    return nil
  end

  local count = 0

  while rest:sub(1, #token) == token do
    count = count + 1
    rest = rest:sub(#token + 1)
  end

  if rest ~= "" then
    return nil
  end

  return count
end

local function wrap_multiline_linewise(
  buf,
  win,
  first_row,
  last_row,
  wrapper
)
  local first_line = vim.api.nvim_buf_get_lines(
    buf,
    first_row - 1,
    first_row,
    false
  )[1] or ""

  local indent = first_line:match "^%s*" or ""
  local line_count = vim.api.nvim_buf_line_count(buf)

  local above
  local below

  if first_row > 1 then
    above = vim.api.nvim_buf_get_lines(
      buf,
      first_row - 2,
      first_row - 1,
      false
    )[1]
  end

  if last_row < line_count then
    below = vim.api.nvim_buf_get_lines(
      buf,
      last_row,
      last_row + 1,
      false
    )[1]
  end

  local open_count = above
      and repeated_token_count(
        above,
        indent,
        wrapper.open
      )
    or nil

  local close_count = below
      and repeated_token_count(
        below,
        indent,
        wrapper.close
      )
    or nil

  -- Выделение уже находится между такими же обрамляющими
  -- строками. Просто добавляем ещё по одному символу.
  if open_count
    and close_count
    and open_count == close_count
  then
    local next_count = open_count + 1

    vim.api.nvim_buf_set_lines(
      buf,
      first_row - 2,
      first_row - 1,
      false,
      {
        indent
          .. string.rep(
            wrapper.open,
            next_count
          ),
      }
    )

    vim.api.nvim_buf_set_lines(
      buf,
      last_row,
      last_row + 1,
      false,
      {
        indent
          .. string.rep(
            wrapper.close,
            next_count
          ),
      }
    )

    select_linewise(
      win,
      first_row,
      last_row
    )

    return
  end

  -- Первое оборачивание. Закрывающую строку добавляем первой,
  -- чтобы индексы выделенного текста не изменились раньше времени.
  vim.api.nvim_buf_set_lines(
    buf,
    last_row,
    last_row,
    false,
    {
      indent .. wrapper.close,
    }
  )

  vim.api.nvim_buf_set_lines(
    buf,
    first_row - 1,
    first_row - 1,
    false,
    {
      indent .. wrapper.open,
    }
  )

  -- После добавления верхней строки исходный текст сдвинулся вниз.
  select_linewise(
    win,
    first_row + 1,
    last_row + 1
  )
end

local function surround_selection(wrapper)
  return function()
    local mode = vim.fn.mode()

    if mode == "\22" then
      vim.notify(
        "Блочное выделение Ctrl+V пока не поддерживается",
        vim.log.levels.WARN
      )
      return
    end

    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()

    local anchor = vim.fn.getpos "v"
    local cursor = vim.fn.getpos "."

    local first, last = normalize_range(
      anchor,
      cursor
    )

    leave_visual_mode()

    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf)
        or not vim.api.nvim_win_is_valid(win)
        or vim.api.nvim_win_get_buf(win) ~= buf
      then
        return
      end

      -- Shift+V.
      if mode == "V" then
        if first.row == last.row then
          wrap_single_linewise(
            buf,
            win,
            first.row,
            wrapper
          )
        else
          wrap_multiline_linewise(
            buf,
            win,
            first.row,
            last.row,
            wrapper
          )
        end

        return
      end

      -- Обычное v.
      wrap_characterwise(
        buf,
        win,
        first,
        last,
        wrapper
      )
    end)
  end
end

for key, wrapper in pairs(wrappers) do
  vim.keymap.set(
    "x",
    key,
    surround_selection(wrapper),
    {
      silent = true,
      desc = "Repeatedly surround selection",
    }
  )
end

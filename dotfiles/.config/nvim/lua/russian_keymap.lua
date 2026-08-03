-- Обычные команды Normal/Visual mode на русской раскладке:
-- ц, пв, нн, Space+ы+к и т. п. трактуются как w, gd, yy, Space+s+r.
vim.opt.langmap = table.concat({
  "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ",
  "фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz",
}, ",")
vim.opt.langremap = false

-- langmap не является универсальным решением для Ctrl-сочетаний,
-- поэтому дублируем Ctrl+A..Z для русских физических клавиш отдельно.
local ctrl_keys = {
  { "a", "ф", "Ф" },
  { "b", "и", "И" },
  { "c", "с", "С" },
  { "d", "в", "В" },
  { "e", "у", "У" },
  { "f", "а", "А" },
  { "g", "п", "П" },
  { "h", "р", "Р" },
  { "i", "ш", "Ш" },
  { "j", "о", "О" },
  { "k", "л", "Л" },
  { "l", "д", "Д" },
  { "m", "ь", "Ь" },
  { "n", "т", "Т" },
  { "o", "щ", "Щ" },
  { "p", "з", "З" },
  { "q", "й", "Й" },
  { "r", "к", "К" },
  { "s", "ы", "Ы" },
  { "t", "е", "Е" },
  { "u", "г", "Г" },
  { "v", "м", "М" },
  { "w", "ц", "Ц" },
  { "x", "ч", "Ч" },
  { "y", "н", "Н" },
  { "z", "я", "Я" },
}

local modes = { "n", "x", "s", "o", "i", "c", "t" }

local function map_ctrl(lhs, rhs, description)
  -- Поддержка модификаторов для Unicode зависит от терминала.
  -- pcall не даёт конфигу упасть на терминале без такой поддержки.
  pcall(vim.keymap.set, modes, lhs, rhs, {
    remap = true,
    silent = true,
    desc = description,
  })
end

for _, key in ipairs(ctrl_keys) do
  local english, russian, russian_upper = unpack(key)

  map_ctrl("<C-" .. russian .. ">", "<C-" .. english .. ">", "Ctrl+" .. english .. " on RU layout")
  map_ctrl("<C-S-" .. russian .. ">", "<C-S-" .. english .. ">", "Ctrl+Shift+" .. english .. " on RU layout")
  map_ctrl("<C-" .. russian_upper .. ">", "<C-S-" .. english .. ">", "Ctrl+Shift+" .. english .. " on RU layout")
end

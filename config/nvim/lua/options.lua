require "nvchad.options"

-- add your own options here
local o = vim.o

o.relativenumber = true   -- relative line numbers (with number from NvChad)
o.scrolloff = 8           -- keep cursor away from screen edges
o.wrap = false
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.smartindent = true
o.undofile = true         -- persistent undo
o.ignorecase = true
o.smartcase = true

-- o.cursorlineopt = "both"  -- enable cursorline

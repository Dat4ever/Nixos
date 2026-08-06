-- Enable line numbers and relative numbers to jump to other lines on the screen using relative counts and cursorline for standing line
vim.opt.number = true
vim.opt.relativenumber = true

-- Undo changes after exiting and reopening the file
vim.opt.undofile = true

-- 2 spaces for tab size, and tab key to insert spaces instead
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Copy paste integration
vim.opt.clipboard = "unnamedplus"

-- Leader key
vim.g.mapleader = " "

-- Other settings
require("lsp")
require("terminalcolor")
require("netrw")
require("statusline")

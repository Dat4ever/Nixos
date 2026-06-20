require("config.lazy")

-- Enable line numbers and relative numbers to jump to other lines on the screen using relative counts
vim.opt.number = true
vim.opt.relativenumber = true

-- Undo changes after exiting and reopening the file
vim.opt.undofile = true

-- Improved window-splitting behavior
vim.opt.splitbelow = true
vim.opt.splitright = true

-- The default leader key is \, but using the Space bar is way more convenient
vim.g.mapleader = " "

-- 2 spaces for tab size, and tab key to insert spaces instead
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 0

-- Copy paste integration
vim.opt.clipboard = "unnamedplus"

-- Terminal colors
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "VertSplit", { bg = "none" })

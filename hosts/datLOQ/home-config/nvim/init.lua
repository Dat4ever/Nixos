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

-- Ctrl + h/j/k/l and Ctrl + arrow keys to change focus
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<C-Left>", "<C-w>h")
vim.keymap.set("n", "<C-Down>", "<C-w>j")
vim.keymap.set("n", "<C-Up>", "<C-w>k")
vim.keymap.set("n", "<C-Right>", "<C-w>l")

-- <Leader> + e for open left netrw
vim.keymap.set("n", "<leader>e", ":Lexplore<cr>", { silent = true })

-- <Leader> + g for grep
vim.keymap.set("n", "<leader>g", function()
	vim.ui.input({ prompt = "Grep: " }, function(pattern)
		if pattern then
			vim.cmd("silent grep! " .. vim.fn.fnameescape(pattern))
			vim.cmd("copen")
		end
	end)
end, { silent = true })

-- <Leader> + f for find
vim.keymap.set("n", "<leader>f", ":find ", { silent = false })

-- <Leader> + d for diagnostics
vim.keymap.set("n", "<leader>d", function()
  vim.diagnostic.setqflist()
  vim.cmd("copen")
end, { silent = true })

-- Other settings
require("lsp")
require("terminalcolor")
require("netrw")
require("statusline")
require("find&grep")

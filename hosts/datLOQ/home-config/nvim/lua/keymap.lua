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
vim.keymap.set( "n", "<leader>e", ":Lexplore<cr>", { silent = true })

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

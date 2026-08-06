vim.g.netrw_liststyle = 3 -- tree view
vim.g.netrw_banner = 0 -- hide top banner
vim.g.netrw_winsize = 25 -- fix the left split width
vim.g.netrw_browse_split = 0 -- open files in previous window
vim.g.netrw_altfile = 1 -- keep the alternative file correct

-- <Leader> + e for open left netrw
vim.keymap.set( "n", "<leader>e", ":Lexplore<cr>", { silent = true })

-- Ctrl + h/j/k/l and Ctrl + arrow keys to change focus
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<C-Left>", "<C-w>h")
vim.keymap.set("n", "<C-Down>", "<C-w>j")
vim.keymap.set("n", "<C-Up>", "<C-w>k")
vim.keymap.set("n", "<C-Right>", "<C-w>l")

vim.lsp.enable({
	"vimls",         -- Vim
	"lua_ls",        -- Lua
	"rust_analyzer", -- Rust
	"clangd",        -- C / C++
	"nixd",          -- Nix
	"bashls",        -- Bash
	"pyright",       -- Python
	"gopls",         -- Go
	"jdtls",         -- Java
})

vim.o.updatetime = 300
vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		vim.diagnostic.open_float(nil, {
			focusable = false,
			border = "single",
		})
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client ~= nil and client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end
	end,
})

vim.cmd("set completeopt+=noselect")
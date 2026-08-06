-- Parsers are installed declaratively via home-manager into `~/.local/share/nvim/site/parser/*.so` (see tree-sitter-grammars packages referenced in home.nix).

-- Map filetypes whose parser name differs from the filetype.
local parser_aliases = {
	objc = "objc",
	objcpp = "objc",
	help = "vimdoc",
	checkhealth = "vimdoc",
}

-- Enable syntax highlighting and indent for every filetype that has an installed tree-sitter parser.
vim.api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		local ft = ev.filetype
		if ft == nil or ft == "" then
			return
		end
		local parser = parser_aliases[ft] or ft
		if vim.treesitter.language.add(parser, { silent = true }) then
			vim.treesitter.start(ev.buf)
			pcall(vim.treesitter.indent.enable, ev.buf)
		end
	end,
})

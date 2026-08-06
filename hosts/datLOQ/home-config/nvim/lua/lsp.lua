-- language servers
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

-- Show diagnostics when cursor hovers
vim.o.updatetime = 300
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        return
      end
    end
    vim.diagnostic.open_float(nil, {
      focusable = false,
      border = "single",
      scope = "cursor",
    })
  end,
})

-- Autocompletion
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client ~= nil and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})
vim.cmd("set completeopt+=noselect")

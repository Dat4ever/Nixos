-- Neovim theme colors
local bg      = "__colorbackground1__"
local bg2     = "__colorbackground2__"
local bg3     = "__colorbackground3__"
local fg      = "__colorforeground1__"
local fg2     = "__colorforeground2__"
local muted   = "__colormuted__"
local accent  = "__coloraccent__"
local cyan    = "__colorbrightcyan__"
local green   = "__colorbrightgreen__"
local yellow  = "__colorbrightyellow__"
local red     = "__colorred__"
local magenta = "__colorbrightmagenta__"

-- Highlight groups
vim.api.nvim_set_hl(0, "StatusModeNormal",  { bg = accent,  fg = bg, bold = true })
vim.api.nvim_set_hl(0, "StatusModeInsert",  { bg = green,   fg = bg, bold = true })
vim.api.nvim_set_hl(0, "StatusModeVisual",  { bg = magenta, fg = bg, bold = true })
vim.api.nvim_set_hl(0, "StatusModeCommand", { bg = yellow,  fg = bg, bold = true })
vim.api.nvim_set_hl(0, "StatusModeReplace", { bg = red,     fg = bg, bold = true })
vim.api.nvim_set_hl(0, "StatusFile",        { bg = bg2,     fg = fg, bold = true })
vim.api.nvim_set_hl(0, "StatusModified",    { bg = bg2,     fg = yellow, bold = true })
vim.api.nvim_set_hl(0, "StatusInfo",        { bg = bg2,     fg = cyan })
vim.api.nvim_set_hl(0, "StatusBase",        { bg = bg,      fg = fg2 })
vim.api.nvim_set_hl(0, "StatusGitBranch",   { bg = bg2,     fg = green })

-- Diagnostic counters (statusline)
vim.api.nvim_set_hl(0, "StatusDiagError", { bg = bg2, fg = red,    bold = true })
vim.api.nvim_set_hl(0, "StatusDiagWarn",  { bg = bg2, fg = yellow })
vim.api.nvim_set_hl(0, "StatusDiagInfo",  { bg = bg2, fg = cyan })
vim.api.nvim_set_hl(0, "StatusDiagHint",  { bg = bg2, fg = green })

-- Diagnostic signs with theme colors
vim.api.nvim_set_hl(0, "DiagnosticError", { fg = red })
vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = yellow })
vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = cyan })
vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = green })

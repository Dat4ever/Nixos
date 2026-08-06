local modes = {
  n = "NORMAL",
  i = "INSERT",
  v = "VISUAL",
  V = "V-LINE",
  ["\22"] = "V-BLOCK",
  c = "COMMAND",
  t = "TERMINAL",
  R = "REPLACE",
  s = "SELECT",
  S = "S-LINE",
  ["\19"] = "S-BLOCK",
}

function _G._statusline()
  local mode = modes[vim.fn.mode()] or vim.fn.mode():upper()
  local ft = vim.bo.filetype ~= "" and vim.bo.filetype .. " " or ""
  local diag = ""
  local counts = vim.diagnostic.count(0) or {}
  local labels = { " ", " ", " ", "󰛨 " }
  local hls = { "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint" }
  for i = 1, 4 do
    if counts[i] and counts[i] > 0 then
      diag = diag .. "%#" .. hls[i] .. "#" .. labels[i] .. counts[i] .. "%* "
    end
  end
  return " " .. mode .. " %f%m %=" .. diag .. ft .. "%l:%c"
end

vim.api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function()
    vim.cmd("redrawstatus!")
  end,
})

vim.o.statusline = "%!v:lua._statusline()"

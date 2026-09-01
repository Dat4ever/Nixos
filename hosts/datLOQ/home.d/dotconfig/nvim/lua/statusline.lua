-- Statusline (highlight groups come from the theme file written by theme-switch)

-- Git branch
local git_branch = ""
vim.api.nvim_create_autocmd({"BufEnter", "BufWritePost"}, {
  callback = function()
    local ok, job = pcall(vim.fn.jobstart, "git -C " .. vim.fn.expand("%:h") .. " rev-parse --abbrev-ref HEAD 2>/dev/null", {
      on_stdout = function(_, data)
        git_branch = vim.trim(data[1] or "")
        vim.cmd("redrawstatus")
      end,
      stdout_buffered = true,
    })
    if not ok then git_branch = "" end
  end,
})

-- Statusline
function _G.ThemeStatusline()
  local mode_map = {
    n  = { "NORMAL",  "StatusModeNormal" },
    i  = { "INSERT",  "StatusModeInsert" },
    v  = { "VISUAL",  "StatusModeVisual" },
    V  = { "V-LINE",  "StatusModeVisual" },
    ["\22"] = { "V-BLOCK", "StatusModeVisual" },
    c  = { "COMMAND", "StatusModeCommand" },
    R  = { "REPLACE", "StatusModeReplace" },
  }
  local m = mode_map[vim.fn.mode()] or { vim.fn.mode():upper(), "StatusModeNormal" }

  local filename = vim.fn.expand("%:t")
  if filename == "" then filename = "[No Name]" end

  local ft = vim.bo.filetype
  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local total = vim.fn.line("$")

  local parts = {}

  -- Mode
  table.insert(parts, "%#" .. m[2] .. "# " .. m[1] .. " ")

  -- Filename
  table.insert(parts, "%#StatusFile# " .. filename .. " ")

  -- Modified flag
  if vim.bo.modified then
    table.insert(parts, "%#StatusModified# + ")
  end

  -- Git branch
  if git_branch ~= "" then
    table.insert(parts, "%#StatusGitBranch# " .. git_branch .. " ")
  end

  -- Right side: filetype + position
  table.insert(parts, "%=")
  table.insert(parts, "%#StatusInfo# " .. ft .. " ")
  table.insert(parts, "%#StatusBase# " .. line .. ":" .. col .. " /" .. total .. " ")

  return table.concat(parts)
end

vim.opt.statusline = "%!v:lua.ThemeStatusline()"

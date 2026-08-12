vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
    tmpl = "gotmpl",
  },
})

return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Eğer ensure_installed tablosu yoksa, boş bir tablo olarak başlat
      if not opts.ensure_installed then
        opts.ensure_installed = {}
      end
      
      -- İstediğin dilleri güvenle ekle
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "lua",
        "nix",
        "rust",
      })
    end,
  },
}

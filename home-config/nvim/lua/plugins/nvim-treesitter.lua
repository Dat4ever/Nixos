return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  priority = 1000, 
  opts = {
    highlight = { 
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = { enable = true },
  },
  config = function(_, opts)
    local status, ts = pcall(require, "nvim-treesitter.configs")
    if not status then 
      return 
    end
    ts.setup(opts)
  end
}

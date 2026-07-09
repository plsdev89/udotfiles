return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- format on save
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Treesitter: syntax-aware highlighting/indentation for common languages.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim", "vimdoc", "lua", "bash",
        "html", "css", "javascript", "typescript", "tsx", "json", "yaml", "toml",
        "python", "rust", "go", "c", "markdown", "markdown_inline",
      },
    },
  },

  -- LazyGit integration (mapped to <leader>gg in mappings.lua).
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}

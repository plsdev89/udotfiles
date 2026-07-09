local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    -- Uncomment after installing the tools (e.g. via Mason or npm/pip):
    -- css = { "prettier" },
    -- html = { "prettier" },
    -- javascript = { "prettier" },
    -- typescript = { "prettier" },
    -- json = { "prettier" },
    -- python = { "isort", "black" },
    -- sh = { "shfmt" },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options

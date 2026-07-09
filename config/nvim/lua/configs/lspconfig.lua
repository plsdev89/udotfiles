require("nvchad.configs.lspconfig").defaults()

-- Servers to enable. Install their binaries with :Mason (e.g. lua_ls, html,
-- cssls). Missing binaries are simply inactive — no error.
local servers = { "html", "cssls", "lua_ls" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers

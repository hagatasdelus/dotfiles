---@type vim.lsp.Config
return {
    -- cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc", "json5" },
    settings = {
        json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
            format = { enable = true },
        },
    },
}

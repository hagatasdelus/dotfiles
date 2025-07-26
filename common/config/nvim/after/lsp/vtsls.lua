---@type vim.lsp.Config
return {
    settings = {
        typescript = {
            preferences = { preferTypeOnlyAutoImports = true },
            preferGoToSourceDefinition = true,
            importModuleSpecifier = "relative",
            inlayHints = {
                parameterNames = {
                    enabled = "literals",
                    suppressWhenArgumentMatchesName = true,
                },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
            },
        },
        javascript = {
            preferGoToSourceDefinition = true,
        },
    },
    on_attach = function(client, bufnr)
        vim.lsp.completion.enable(true, client.id, bufnr, {
            convert = function(item)
                return { abbr = item.label:gsub("%b()", "") }
            end,
        })
    end,
    ---@param bufnr number
    ---@param callback fun(root_dir?: string)
    root_dir = function(bufnr, callback)
        local path = vim.api.nvim_buf_get_name(bufnr)
        if path == "" then
            return
        end
        local ts_marker = { "package.json" }
        local ts_root = vim.fs.find(ts_marker,
            { path = vim.fs.dirname(vim.fs.normalize(path)), upward = true, type = "file" })
        if #ts_root > 0 then
            return callback(vim.fs.dirname(ts_root[1]))
        end
    end,

}

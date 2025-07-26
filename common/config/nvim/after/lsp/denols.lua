---@type vim.lsp.Config
return {
    workspace_required = true,
    settings = {
        deno = {
            lint = true,
            unstable = false,
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
        local deno_marker = { "deno.json", "deno.jsonc", "deps.ts" }
        local deno_root = vim.fs.find(deno_marker,
            { path = vim.fs.dirname(vim.fs.normalize(path)), upward = true, type = "file" })
        if #deno_root > 0 then
            return callback(vim.fs.dirname(deno_root[1]))
        end
    end,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
    },
}

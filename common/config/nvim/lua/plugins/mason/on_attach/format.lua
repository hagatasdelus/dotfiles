local M = {}

M.autoformat = true

function M.format(opts)
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if vim.b.autoformat == false and not (opts and opts.force) then
        return
    end

    local line, col = unpack(vim.api.nvim_win_get_cursor(win))

    vim.lsp.buf.format({
        bufnr = buf,
        timeout_ms = 2000,
        filter = function(client)
            if not client.supports_method("textDocument/formatting", buf) then
                return false
            end

            local settings = client.config.settings
            if
                settings ~= nil
                and (
                    (type(settings.format) == "boolean"
                        and settings.format == false)
                    or
                    (type(settings.format) == "table"
                        and settings.format.enable == false)
                )
            then
                return false
            end
            Snacks.notify.info("Format on save", { title = client.name })
            return true
        end,
    })

    line = math.min(line, vim.fn.line("$"))
    vim.api.nvim_win_set_cursor(win, { line, col })
end

function M.toggle()
    if vim.b.autoformat == false then
        vim.b.autoformat = nil
        M.autoformat = true
    else
        M.autoformat = not M.autoformat
    end
    if M.autoformat then
        Snacks.notify.info("Enabled format on save", { title = "Format" })
        vim.b.autoformat = nil
    else
        Snacks.notify.warn("Disabled format on save", { title = "Format" })
        vim.b.autoformat = false
    end
end

function M.enable()
    vim.b.autoformat = nil
    M.autoformat = true
    Snacks.notify.info("Enabled format on save", { title = "Format" })
end

function M.disable()
    M.autoformat = false
    Snacks.notify.warn("Disabled format on save", { title = "Format" })
end

function M.on_attach(client, bufnr)
    if client.server_capabilities.documentFormattingProvider then
        vim.api.nvim_create_user_command("FormatToggle", M.toggle, { nargs = 0 })
        vim.api.nvim_create_user_command("FormatEnable", M.enable, { nargs = 0 })
        vim.api.nvim_create_user_command("FormatDisable", M.disable, { nargs = 0 })
        vim.api.nvim_create_user_command("Format", M.format, { nargs = 0 })

        vim.api.nvim_create_autocmd("BufWritePre", {
            group = vim.api.nvim_create_augroup("LspFormat." .. bufnr, {}),
            buffer = bufnr,
            callback = function()
                if vim.b.autoformat ~= false and not to_bool(vim.v.cmdbang) then
                    M.format()
                end
            end,
        })
    end
end

return M

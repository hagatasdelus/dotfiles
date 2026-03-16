vim.api.nvim_create_user_command("Mo", function(opts)
    local file = opts.args ~= "" and opts.args or vim.api.nvim_buf_get_name(0)

    if file == "" or vim.fn.filereadable(file) == 0 then
        Snacks.notify.error(
            "File does not exist or has not been saved yet: " .. (file == "" and "No Name" or file),
            { title = "Mo" }
        )
        return
    end

    vim.system({ "mo", file }, { text = true }, function(obj)
        vim.schedule(function()
            if obj.code == 0 then
                Snacks.notify.info("Opened: " .. file, { title = "Mo" })
            else
                Snacks.notify.error("Failed to start Mo: " .. obj.stderr, { title = "Mo" })
            end
        end)
    end)
end, { nargs = "?", complete = "file", desc = "Preview Markdown file with mo" })

vim.api.nvim_create_user_command("MoShutdown", function()
    vim.system({ "mo", "--shutdown" }, { text = true }, function(obj)
        vim.schedule(function()
            if obj.code == 0 then
                Snacks.notify.info("Mo server shut down successfully", { title = "Mo" })
            else
                Snacks.notify.error("Failed to shutdown Mo: " .. obj.stderr, { title = "MoShutdown" })
            end
        end)
    end)
end, { desc = "Shutdown the mo server" })

vim.api.nvim_create_user_command("MoStatus", function()
    vim.system({ "mo", "--status" }, { text = true }, function(obj)
        vim.schedule(function()
            if obj.code == 0 then
                Snacks.notify.info(obj.stderr, { title = "MoStatus" })
            else
                Snacks.notify.error("Failed to get status: " .. obj.stderr, { title = "MoStatus" })
            end
        end)
    end)
end, { desc = "Check the status of mo servers" })

vim.api.nvim_create_user_command("MoRestart", function()
    vim.system({ "mo", "--restart" }, { text = true }, function(obj)
        vim.schedule(function()
            if obj.code == 0 then
                Snacks.notify.info("Mo server restarted successfully", { title = "MoRestart" })
            else
                Snacks.notify.error("Failed to restart Mo: " .. obj.stderr, { title = "MoRestart" })
            end
        end)
    end)
end, { desc = "Restart the running mo server" })

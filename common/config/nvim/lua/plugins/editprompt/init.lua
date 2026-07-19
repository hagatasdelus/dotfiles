local helpers = require("plugins.editprompt.helpers")

local editprompt_group = vim.api.nvim_create_augroup("Editprompt", { clear = true })

---Set up keymaps specific to the editprompt buffer.
---@param bufnr integer buffer number
local function setup_keymaps(bufnr)
    local editprompt = require("editprompt")
    local map_opts = { silent = true, nowait = true, buffer = bufnr }

    vim.keymap.set({ "n", "i" }, "<C-g>", "<Cmd>quit!<CR>", map_opts)
    vim.keymap.set("i", "<C-a>", "<C-g>U<Home>", map_opts)
    vim.keymap.set("i", "<C-e>", "<C-g>U<End>", map_opts)
    vim.keymap.set("n", "q", function()
        helpers.send_buffer_auto_send()
    end, map_opts)
    vim.keymap.set({ "n", "i" }, "<CR>", function()
        return helpers.handle_cr(bufnr)
    end, vim.tbl_extend("force", map_opts, { expr = true }))
    vim.keymap.set({ "n", "i" }, "<C-c>", function()
        helpers.send_buffer_auto_send()
    end, map_opts)
    vim.keymap.set({ "n", "i" }, "g<C-c>", function()
        editprompt.input()
    end, map_opts)
    vim.keymap.set("x", "<C-c>", function()
        editprompt.input_visual_auto_send()
    end, map_opts)
    vim.keymap.set("x", "g<C-c>", function()
        editprompt.input_visual()
    end, map_opts)
    vim.keymap.set("n", "ZZ", function()
        helpers.send_buffer_auto_send()
    end, map_opts)
    vim.keymap.set({ "n", "i" }, "<C-o>", "<Nop>", map_opts)

    for digit = 1, 9 do
        local text = tostring(digit)
        vim.keymap.set("n", text, function()
            helpers.press_key(text)
        end, map_opts)
    end

    vim.keymap.set("n", "<C-p>", function()
        editprompt.history_prev()
    end, map_opts)
    vim.keymap.set("n", "<Up>", function()
        editprompt.history_prev()
    end, map_opts)
    vim.keymap.set("n", "<C-n>", function()
        editprompt.history_next()
    end, map_opts)
    vim.keymap.set("n", "<Down>", function()
        editprompt.history_next()
    end, map_opts)

    vim.keymap.set("i", "<C-p>", function()
        if vim.fn.pumvisible() == 1 then
            return "<C-p>"
        end
        vim.schedule(function()
            editprompt.history_prev()
        end)
        return ""
    end, vim.tbl_extend("force", map_opts, { expr = true }))
    vim.keymap.set("i", "<C-n>", function()
        if vim.fn.pumvisible() == 1 then
            return "<C-n>"
        end
        vim.schedule(function()
            editprompt.history_next()
        end)
        return ""
    end, vim.tbl_extend("force", map_opts, { expr = true }))
    vim.keymap.set("i", "<Up>", function()
        vim.schedule(function()
            editprompt.history_prev()
        end)
        return ""
    end, vim.tbl_extend("force", map_opts, { expr = true }))
    vim.keymap.set("i", "<Down>", function()
        vim.schedule(function()
            editprompt.history_next()
        end)
        return ""
    end, vim.tbl_extend("force", map_opts, { expr = true }))

    vim.keymap.set("n", "<C-q>", function()
        helpers.stash_buffer_to_history()
        vim.schedule(function()
            helpers.move_cursor_to_start(bufnr)
        end)
    end, map_opts)
    vim.keymap.set("i", "<C-q>", function()
        vim.schedule(function()
            helpers.stash_buffer_to_history()
            helpers.move_cursor_to_start(bufnr)
        end)
    end, map_opts)

    vim.keymap.set("n", "<C-d>", function()
        if helpers.is_buffer_blank(bufnr) then
            vim.cmd("quit!")
            return
        end
        -- Fallback to default scroll behavior
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-d>", true, false, true), "n", false)
    end, map_opts)

    vim.keymap.set("i", "<C-d>", function()
        if helpers.is_buffer_blank(bufnr) then
            vim.schedule(function()
                vim.cmd("quit!")
            end)
            return ""
        end
        return "<C-d>"
    end, vim.tbl_extend("force", map_opts, { expr = true }))
end

return {
    "https://github.com/eetann/editprompt.nvim",
    cond = function()
        return helpers.is_editprompt()
    end,
    lazy = false,
    dependencies = {
        { "https://github.com/folke/snacks.nvim" },
    },
    init = function()
        if not helpers.is_editprompt() then
            return
        end

        vim.g.editprompt = 1
        vim.api.nvim_create_autocmd({ "FileType" }, {
            group = editprompt_group,
            pattern = { "markdown" },
            callback = function(ev)
                local bufnr = ev.buf

                -- Keep it minimal
                helpers.apply_mode_opts()
                vim.bo[bufnr].filetype = "markdown.editprompt"
                vim.opt_local.virtualedit = "block"

                setup_keymaps(bufnr)

                vim.cmd("startinsert")
            end,
        })
    end,
    config = function()
        local editprompt = require("editprompt")

        editprompt.setup({
            cmd = "editprompt",
            picker = "snacks",
            before_input = function(content)
                return helpers.normalize_content(content)
            end,
            on_success = function(content, _, ctx)
                if helpers.should_save_clipboard(content) then
                    vim.fn.system("pbcopy", content)
                end
                if ctx.auto_send then
                    editprompt.stash_pop_latest()
                end
            end,
            on_error = function(_, _, result)
                Snacks.notify.error("editprompt failed: " .. (result.stderr or "unknown error"))
            end,
        })
    end,
}

local M = {}

local function config_dir()
    return vim.fs.joinpath(vim.fn.stdpath("config"), "goda-cmp")
end

local function binary()
    local name = vim.fn.has("win32") == 1 and "goda-cmp.exe" or "goda-cmp"
    return vim.fs.joinpath(vim.fn.stdpath("cache"), "goda-cmp", name)
end

local function pum_visible()
    return vim.fn.exists("*pum#visible") == 1 and vim.fn["pum#visible"]() == 1
end

local function pum_selected()
    if not pum_visible() then
        return false
    end
    local info = vim.fn["pum#complete_info"]({ "selected" })
    return type(info) == "table" and (info.selected or -1) >= 0
end

local function skk_active()
    return require("plugins.goda.skkelua").active()
end

local function manual_complete(sources)
    local options = sources and { sources = sources } or nil
    return vim.fn["goda_cmp#map#manual_complete"](options)
end

local function setup_build()
    vim.g["goda_cmp#config_dir"] = config_dir()

    vim.api.nvim_create_user_command("GodaCmpBuild", function()
        vim.fn["goda_cmp#build"]()
    end, { desc = "Build the goda-cmp configuration" })

    vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("config.goda_cmp.build", { clear = true }),
        pattern = vim.fs.joinpath(config_dir(), "*.go"),
        callback = function()
            vim.fn["goda_cmp#build"]()
        end,
    })

    if vim.fn.executable(binary()) == 0 then
        vim.fn["goda_cmp#build"]()
    end
end

local function setup_pum()
    vim.fn["pum#set_option"]({
        auto_select = false,
        border = "rounded",
        max_height = 20,
        max_width = 80,
        preview = true,
        preview_border = "rounded",
        preview_height = 20,
        preview_width = 60,
        previewer = "goda_cmp#get_previewer",
        use_setline = false,
    })
end

local function insert_mappings()
    local map = function(lhs, rhs)
        vim.keymap.set("i", lhs, rhs, { expr = true, silent = true })
    end

    map("<Tab>", function()
        if skk_active() then
            return ""
        end
        if pum_visible() then
            return "<Cmd>call pum#map#insert_relative(+1)<CR>"
        end
        return "<Tab>"
    end)

    map("<S-Tab>", function()
        if skk_active() then
            return ""
        end
        if pum_visible() then
            return "<Cmd>call pum#map#insert_relative(-1)<CR>"
        end
        return "<S-Tab>"
    end)

    map("<C-n>", function()
        if pum_visible() then
            if skk_active() then
                return "<Cmd>call pum#map#select_relative(+1)<CR>"
            end
            return "<Cmd>call pum#map#insert_relative(+1)<CR>"
        end
        if skk_active() then
            return manual_complete({ "skkelua" })
        end
        return manual_complete()
    end)

    map("<C-p>", function()
        if pum_visible() then
            if skk_active() then
                return "<Cmd>call pum#map#select_relative(-1)<CR>"
            end
            return "<Cmd>call pum#map#insert_relative(-1)<CR>"
        end
        if skk_active() then
            return manual_complete({ "skkelua" })
        end
        return manual_complete()
    end)

    map("<Down>", function()
        if pum_visible() then
            if skk_active() then
                return "<Cmd>call pum#map#select_relative(+1)<CR>"
            end
            return "<Cmd>call pum#map#insert_relative(+1)<CR>"
        end
        return "<Down>"
    end)

    map("<Up>", function()
        if pum_visible() then
            if skk_active() then
                return "<Cmd>call pum#map#select_relative(-1)<CR>"
            end
            return "<Cmd>call pum#map#insert_relative(-1)<CR>"
        end
        return "<Up>"
    end)

    map("<C-b>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#scroll_preview(-4)<CR>"
        end
        return "<C-b>"
    end)

    map("<C-f>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#scroll_preview(+4)<CR>"
        end
        return "<C-f>"
    end)

    map("<C-l>", function()
        return manual_complete()
    end)

    map("<C-e>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#cancel()<CR>"
        end
        return "<C-e>"
    end)

    map("<C-y>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#confirm()<CR>"
        end
        return "<C-y>"
    end)

    map("<CR>", function()
        if pum_selected() then
            return "<Cmd>call pum#map#confirm()<CR>"
        end
        return "<CR>"
    end)
end

local function cmdline_mappings()
    local map = function(lhs, rhs)
        vim.keymap.set("c", lhs, rhs, { expr = true, silent = true })
    end

    map("<Tab>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#insert_relative(+1)<CR>"
        end
        return manual_complete()
    end)

    map("<S-Tab>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#insert_relative(-1)<CR>"
        end
        return manual_complete()
    end)

    map("<C-n>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#insert_relative(+1)<CR>"
        end
        return "<C-n>"
    end)

    map("<C-p>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#insert_relative(-1)<CR>"
        end
        return "<C-p>"
    end)

    map("<C-b>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#scroll_preview(-4)<CR>"
        end
        return "<C-b>"
    end)

    map("<C-f>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#scroll_preview(+4)<CR>"
        end
        return "<C-f>"
    end)

    map("<C-l>", function()
        return manual_complete()
    end)

    map("<C-e>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#cancel()<CR>"
        end
        return "<C-e>"
    end)

    map("<C-y>", function()
        if pum_visible() then
            return "<Cmd>call pum#map#confirm()<CR>"
        end
        return "<C-y>"
    end)

    map("<CR>", function()
        if pum_selected() then
            return "<Cmd>call pum#map#confirm()<CR>"
        end
        return "<CR>"
    end)
end

local function setup_cmdline()
    vim.api.nvim_create_autocmd("CmdlineEnter", {
        group = vim.api.nvim_create_augroup("config.goda_cmp.cmdline", { clear = true }),
        callback = function()
            vim.fn["goda_cmp#enable_cmdline"]()
        end,
    })
end

function M.setup()
    setup_build()
    setup_pum()
    require("plugins.goda.skkelua").setup()
    insert_mappings()
    cmdline_mappings()
    setup_cmdline()
    vim.fn["goda_cmp#enable"]()
end

return M

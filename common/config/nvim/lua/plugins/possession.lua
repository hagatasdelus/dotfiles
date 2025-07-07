return {
    "jedrzejboczar/possession.nvim",
    cond = not is_on_vscode(),
    cmd = {
        "PossessionLoadCurrent",
    },
    config = function()
        local Path = require("plenary.path")
        local session_dir = (Path:new(vim.fn.stdpath("state")) / "possession"):absolute()

        require("possession").setup({
            session_dir = session_dir,
            silent = true,
            load_silent = true,
            autosave = {
                current = true,
                on_load = true,
                on_quit = true,
            },
        })

        vim.api.nvim_create_user_command("PossessionSaveCurrent", function()
            local tmp_name = vim.uv.cwd():gsub("/", "__")
            vim.cmd("PossessionSave!" .. tmp_name)
        end, { force = true })

        vim.api.nvim_create_user_command("PossessionLoadCurrent", function()
            local tmp_name = vim.uv.cwd():gsub("/", "__")
            vim.cmd("PossessionLoad" .. tmp_name)
        end, { force = true })

        vim.api.nvim_create_augroup("vimrc_possession", { clear = true })
        vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
            group = "vimrc_possession",
            pattern = "*",
            command = "PossessionSaveCurrent",
        })
    end,
}

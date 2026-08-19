local GH_OWNER = "hagatasdelus"

local get_ghq_root
do
    local cache = nil

    ---Get the ghq root path (cached on first call, throws error on failure).
    ---@return string
    get_ghq_root = function()
        if cache then
            return cache
        end

        if vim.fn.executable("ghq") == 1 then
            local result = vim.system({ "ghq", "root" }, { text = true }):wait()
            if result.code == 0 and result.stdout and vim.trim(result.stdout) ~= "" then
                cache = vim.fs.normalize(vim.trim(result.stdout))
                return cache
            end
        end

        local git_result = vim.system({ "git", "config", "get", "ghq.root" }, { text = true }):wait()
        if git_result.code == 0 and git_result.stdout and vim.trim(git_result.stdout) ~= "" then
            cache = vim.fs.normalize(vim.trim(git_result.stdout))
            return cache
        end

        error("Failed to get ghq root via 'ghq root' or 'git config get ghq.root'")
    end
end

vim.api.nvim_create_user_command("QuickLook", function()
    -- get current buffer absolute path
    local current_bf_abspath = vim.fn.expand("%:p")
    require("core.utils").open_file_with_quicklook(current_bf_abspath)
end, { nargs = 0, force = true })

vim.api.nvim_create_user_command("Restart", function()
    if vim.v.count > 0 then
        vim.cmd("restart")
        return
    end

    -- cleanup session-unfriendly buffers (e.g., terminal)
    local bufname = vim.api.nvim_list_bufs()
    for _, buf in ipairs(bufname) do
        if vim.bo[buf].buftype == "terminal" then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end
    local session_file = vim.fs.joinpath(tostring(vim.fn.stdpath("state")), "session.vim")
    vim.cmd(string.format("mksession! %s | :restart +xa source %s", session_file, session_file))
end, { desc = "Restart current Neovim session" })

vim.api.nvim_create_user_command("OpenUrl", function(opts)
    local function get_repo_from_cwd()
        local cwd = vim.fs.normalize(vim.fn.getcwd())
        local owner, repo = cwd:match("github%.com/([^/]+)/([^/]+)")
        if owner and repo then
            return owner .. "/" .. repo
        end
        return nil
    end
    local function build_url(target)
        if target:match("^[%w%-]+/[%w%%._%-]+$") then
            return "https://github.com/" .. target
        end

        if target:match("^[%w%-%._]+$") and not target:match("%.") then
            return "https://github.com/" .. GH_OWNER .. "/" .. target
        end

        if not target:match("^https?://") then
            return "https://" .. target
        end

        return target
    end

    local target = opts.args
    if target == "" then
        local repo = get_repo_from_cwd()
        if repo then
            target = repo
        else
            Snacks.notify.error(
                "No URL provided and current directory is not a GitHub repository",
                { title = "OpenUrl" }
            )
            return
        end
    end
    local url = build_url(target)

    local ok, ret, err = pcall(vim.ui.open, url)
    if not ok then
        Snacks.notify.error(
            "An Internal error occurred when opening the browser" .. tostring(ret),
            { title = "OpenUrl" }
        )
        return
    end
    if not ret and err then
        Snacks.notify.error("Failed to open URL: " .. tostring(err), { title = "OpenUrl" })
        return
    end
    Snacks.notify.info("Opened URL: " .. url, { title = "OpenUrl" })
end, { nargs = "?", desc = "Open URL or GitHub repository in the default browser" })

vim.api.nvim_create_user_command("Browse", function(opts)
    local query = opts.args
    if query == "" then
        Snacks.notify.error("No search query provided", { title = "Browse" })
        return
    end
    local search_url = "https://duckduckgo.com/?q=" .. query
    local ok, ret, err = pcall(vim.ui.open, search_url)
    if not ok then
        Snacks.notify.error(
            "An Internal error occurred when opening the browser" .. tostring(ret),
            { title = "Browse" }
        )
        return
    end
    if not ret and err then
        Snacks.notify.error("Failed to open URL: " .. tostring(err), { title = "Browse" })
        return
    end
    Snacks.notify.info("Opened Browser with search query: " .. query, { title = "Browse" })
end, { nargs = "*", desc = "Open Browser and search for the query" })

vim.api.nvim_create_user_command("EditConfig", function()
    vim.cmd.edit(vim.fn.stdpath("config"))
end, { nargs = 0 })

vim.api.nvim_create_user_command("Daily", function(opts)
    local ok, ghq_root = pcall(get_ghq_root)
    if not ok then
        Snacks.notify.error("Daily: " .. tostring(ghq_root), { title = "Daily" })
        return
    end

    local date = (opts.args ~= "") and opts.args or os.date("%Y-%m-%d")
    if date == "yesterday" then
        date = os.date("%Y-%m-%d", os.time() - 86400)
    end
    local diary_dir = vim.fs.joinpath(ghq_root, "github.com", GH_OWNER, "life/daily/diary")
    local file_path = vim.fs.joinpath(diary_dir, date .. ".md")

    if vim.fn.isdirectory(diary_dir) == 0 then
        vim.fn.mkdir(diary_dir, "p")
    end

    local is_new = vim.fn.filereadable(file_path) == 0
    vim.cmd.edit(vim.fn.fnameescape(file_path))

    if is_new then
        local template = {
            "---",
            string.format('title: "%sの日記"', date),
            string.format('pubDate: "%s"', date),
            "---",
            "",
            "## 今日やったこと",
            "",
            "## 明日以降やりたいこと",
            "",
        }
        vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
    end
end, { nargs = "?", desc = "Open daily note" })

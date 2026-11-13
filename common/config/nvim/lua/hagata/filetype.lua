vim.filetype.add({
    extension = {
        mdx = "markdown",
        jax = "help",
    },
    filename = {
        [".envrc"] = "sh",
        ["tsconfig.json"] = "jsonc",
        ["mdx"] = "markdown",
    },
    pattern = {
        [".*/%.%a+rc%.local"] = "sh",

        [".*/%.git/config"] = "gitconfig",
        [".*/%.git/.*%.conf"] = "gitconfig",
        [".*/git/config"] = "gitconfig",
        [".*/git/.*%.conf"] = "gitconfig",

        [".*/%.git/ignore"] = "gitignore",
        [".*/git/ignore"] = "gitignore",

        [".*"] = {
            function(_, bufnr)
                local shebang = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
                if not shebang or shebang:sub(1, 2) ~= "#!" then
                    return
                end

                shebang = shebang:gsub("%s+", " ")

                local idx_space = shebang:find(" ")
                local path = string.sub(shebang, 3, idx_space and idx_space - 1 or nil)
                if path == "/usr/bin/env" then
                    if
                        vim.startswith(shebang, "#!/usr/bin/env deno")
                        or vim.startswith(shebang, "#!/usr/bin/env -S deno")
                    then
                        return "typescript"
                    end
                end

                local cmd = vim.fs.basename(path)
                if cmd == "deno" then
                    return "typescript"
                end
            end,
            { priority = -math.huge },
        },
    },
})

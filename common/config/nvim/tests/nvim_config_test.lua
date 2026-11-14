-- Regression tests for the nvim config migration.
--
--   DOTFILES_DIR=... nvim --headless --clean -l common/config/nvim/tests/nvim_config_test.lua
--
-- The tests load the config modules directly. Real plugins are stubbed where needed.
local repo = assert(os.getenv("DOTFILES_DIR"), "DOTFILES_DIR is required")
local nvim_dir = repo .. "/common/config/nvim"

package.path = string.format("%s/lua/?.lua;%s/lua/?/init.lua;", nvim_dir, nvim_dir) .. package.path

local failures = 0

local function check(name, actual, expected)
    if actual == expected then
        print(string.format("  ok   %s", name))
        return
    end
    failures = failures + 1
    print(
        string.format("  FAIL %s\n       expected: %s\n       actual:   %s", name, tostring(expected), tostring(actual))
    )
end

local function check_deep(name, actual, expected)
    if vim.deep_equal(actual, expected) then
        print(string.format("  ok   %s", name))
        return
    end
    failures = failures + 1
    print(
        string.format(
            "  FAIL %s\n       expected: %s\n       actual:   %s",
            name,
            vim.inspect(expected),
            vim.inspect(actual)
        )
    )
end

local function check_true(name, actual)
    check(name, not not actual, true)
end

local function check_false(name, actual)
    check(name, not not actual, false)
end

local function section(name)
    print("\n" .. name)
end

local function stub(target, key, value)
    local previous = target[key]
    target[key] = value
    return function()
        target[key] = previous
    end
end

local function save_loaded(name, value)
    local previous = package.loaded[name]
    package.loaded[name] = value
    return function()
        package.loaded[name] = previous
    end
end

local function require_or_fail(name)
    local ok, value = pcall(require, name)
    check_true("require " .. name, ok)
    if not ok then
        print("    " .. tostring(value))
    end
    return ok and value or nil
end

local function mapping(lhs, mode)
    return vim.fn.maparg(lhs, mode or "n", false, true)
end

local function command_exists(name)
    return vim.fn.exists(":" .. name) == 2
end

section("1. structure")
check_false("lua/core removed", vim.fn.isdirectory(nvim_dir .. "/lua/core") == 1)
check_false("lua/config removed", vim.fn.isdirectory(nvim_dir .. "/lua/config") == 1)
check_true("lua/hagata exists", vim.fn.isdirectory(nvim_dir .. "/lua/hagata") == 1)
check_true("hagata/lsp/on_attach exists", vim.fn.isdirectory(nvim_dir .. "/lua/hagata/lsp/on_attach") == 1)
check_false("plugins/mason/on_attach removed", vim.fn.isdirectory(nvim_dir .. "/lua/plugins/mason/on_attach") == 1)
check_false("lua/plugins.lua not created", vim.fn.filereadable(nvim_dir .. "/lua/plugins.lua") == 1)
check_false("require core", pcall(require, "core"))
check_false("require core.utils", pcall(require, "core.utils"))
check_false("lua/config/init.lua removed", vim.fn.filereadable(nvim_dir .. "/lua/config/init.lua") == 1)
if vim.fn.filereadable(nvim_dir .. "/lua/config/init.lua") == 0 then
    check_false("require config", pcall(require, "config"))
end
check_false("require plugins root", pcall(require, "plugins"))

local hagata_init = table.concat(vim.fn.readfile(nvim_dir .. "/lua/hagata/init.lua"), "\n")
check_false("hagata/init.lua does not require lsp", hagata_init:find('require("hagata.lsp")', 1, true) ~= nil)

local loaded, loaded_error = pcall(require, "hagata")
check_true("require hagata", loaded)
if not loaded then
    print("    " .. tostring(loaded_error))
    print(string.format("%d failed", failures))
    vim.cmd("cquit 1")
    return
end

section("2. env and fn helpers")
local fn = require("hagata.fn")
local env = require("hagata.env")
check("to_bool nil", fn.to_bool(nil), false)
check("to_bool true", fn.to_bool(true), true)
check("to_bool false", fn.to_bool(false), false)
check("to_bool 0", fn.to_bool(0), false)
check("to_bool 1", fn.to_bool(1), true)
check("to_bool string true", fn.to_bool("true"), true)
check("to_bool string TRUE", fn.to_bool("TRUE"), true)
check("to_bool string false", fn.to_bool("false"), false)
check("to_bool table", fn.to_bool({}), false)
check("is_vscode nil", env.is_vscode(), false)
vim.g.vscode = 1
check("is_vscode 1", env.is_vscode(), true)
vim.g.vscode = nil
check("is_macos", env.is_macos(), vim.uv.os_uname().sysname == "Darwin")
check("lambda", fn.lambda("a,b:a+b")(2, 3), 5)

section("3. base")
check("loaded_2html_plugin", vim.g.loaded_2html_plugin, 1)
check("loaded_getscript", vim.g.loaded_getscript, 1)
check("loaded_netrw", vim.g.loaded_netrw, 1)
check("loaded_tar", vim.g.loaded_tar, 1)
check("loaded_zip", vim.g.loaded_zip, 1)
check("loaded_gtags", vim.g.loaded_gtags, 1)
check("did_indent_on", vim.g.did_indent_on, 1)
check("did_install_default_menus", vim.g.did_install_default_menus, 1)
check("loaded_gzip delegated to lazy", vim.g.loaded_gzip, nil)
check("loaded_matchparen delegated to lazy", vim.g.loaded_matchparen, nil)
check("loaded_netrwPlugin delegated to lazy", vim.g.loaded_netrwPlugin, nil)
check("loaded_remote_plugins delegated to lazy", vim.g.loaded_remote_plugins, nil)
check("loaded_shada_plugin delegated to lazy", vim.g.loaded_shada_plugin, nil)
check("loaded_spellfile_plugin delegated to lazy", vim.g.loaded_spellfile_plugin, nil)
check("loaded_tarPlugin delegated to lazy", vim.g.loaded_tarPlugin, nil)
check("loaded_tutor_mode_plugin delegated to lazy", vim.g.loaded_tutor_mode_plugin, nil)
check("loaded_zipPlugin delegated to lazy", vim.g.loaded_zipPlugin, nil)

section("4. options")
check("mapleader", vim.g.mapleader, " ")
check("maplocalleader", vim.g.maplocalleader, "\\")
check("swapfile", vim.o.swapfile, false)
check("hidden", vim.o.hidden, true)
check("fenc", vim.o.fenc, "utf-8")
check("cursorline", vim.o.cursorline, true)
check("cursorcolumn", vim.o.cursorcolumn, true)
check("whichwrap", vim.o.whichwrap, "b,s,h,l,[,],<,>,~")
check("virtualedit", vim.o.virtualedit, "block")
check("clipboard", vim.o.clipboard, "unnamedplus")
check("wildmenu", vim.o.wildmenu, true)
check("laststatus", vim.o.laststatus, 2)
check("confirm", vim.o.confirm, true)
check("hlsearch", vim.o.hlsearch, true)
check("incsearch", vim.o.incsearch, true)
check("matchtime", vim.o.matchtime, 1)
check("termguicolors", vim.o.termguicolors, true)
check("background", vim.o.background, "dark")
check("shiftwidth", vim.o.shiftwidth, 4)
check("tabstop", vim.o.tabstop, 4)
check("expandtab", vim.o.expandtab, true)
check("autoindent", vim.o.autoindent, true)
check("smartindent", vim.o.smartindent, true)
check("backspace", vim.o.backspace, "indent,eol,start")
check("number", vim.o.number, true)
check("wrap", vim.o.wrap, true)
check("showtabline", vim.o.showtabline, 2)
check("visualbell", vim.o.visualbell, true)
check("errorbells", vim.o.errorbells, false)
check("showmatch", vim.o.showmatch, true)
check("list", vim.o.list, true)
check("listchars tab", vim.o.listchars:find("tab:▸▹┊", 1, true) ~= nil, true)
check("pumblend", vim.o.pumblend, 10)
check("signcolumn", vim.o.signcolumn, "yes")
check("splitright", vim.o.splitright, true)
check("diagnostic severity_sort", vim.diagnostic.config().severity_sort, true)
check("diagnostic virtual_text", vim.diagnostic.config().virtual_text, true)

section("5. keymaps")
check("ss", mapping("ss").rhs, "^")
check(";;", mapping(";;").rhs, "$")
check("x", mapping("x", "x").rhs, '"_x')
check("X", mapping("X", "x").rhs, '"_d$')
check("Y", mapping("Y").rhs, "y$")
check("U", mapping("U").rhs, "<C-r>")
check("p", mapping("p").rhs, "]p`]")
check("P", mapping("P").rhs, "]P`]")
check("gV", mapping("gV", "x").rhs, "`[v`]")
check("M", mapping("M").rhs, [[expand('<cword>') =~# 'end' ? '%' : 'g%']])
check("zz", mapping("zz").rhs, "zz<Plug>(zsub1)")
check("quote text object", mapping('a"', "x").rhs, '2i"')
check("move line up", type(mapping("<C-k>").callback), "function")
check("duplicate line", mapping("<Space>g").rhs, "<Cmd>copy.<CR>")
check("tabfirst", mapping("th").rhs, "<Cmd>tabfirst<CR>")
check("tabprevious", mapping("tj").rhs, "<Cmd>tabprevious<CR>")
check("tabnext", mapping("tk").rhs, "<Cmd>tabnext<CR>")
check("tablast", mapping("tl").rhs, "<Cmd>tablast<CR>")
check("tabe", mapping("tt").rhs, "<Cmd>tabe .<CR>")
check("tabclose", mapping("tq").rhs, "<Cmd>tabclose<CR>")
check("substitute", mapping("S").rhs, [[:%s/\V\<<C-r><C-w>\>//g<Left><Left>]])
check("search", mapping("/").rhs, "/\\v")
check("backward search", mapping("?").rhs, "/\\V")
check("terminal escape", mapping("<C-[><C-[>", "t").rhs, [[<C-\><C-n>]])
check("visual <", mapping("<", "x").rhs, "<gv")
check("visual >", mapping(">", "x").rhs, ">gv")
check("smart insert", type(mapping("i").callback), "function")
check("smart insert expr", mapping("i").expr, 1)
check("smart append", type(mapping("A").callback), "function")
check("cnoreabbrev tn", vim.fn.execute("cnoreabbrev tn"):find("tn%s+%*%s+tabnew") ~= nil, true)
check("cnoreabbrev vs", vim.fn.execute("cnoreabbrev vs"):find("vs%s+%*%s+vsplit") ~= nil, true)
check("cnoreabbrev rst", vim.fn.execute("cnoreabbrev rst"):find("rst%s+%*%s+Restart") ~= nil, true)

section("6. filetype")
check("mdx extension", vim.filetype.match({ filename = "foo.mdx" }), "markdown")
check("jax extension", vim.filetype.match({ filename = "foo.jax" }), "help")
check(".envrc filename", vim.filetype.match({ filename = ".envrc" }), "sh")
check("tsconfig filename", vim.filetype.match({ filename = "tsconfig.json" }), "jsonc")
check("mdx filename", vim.filetype.match({ filename = "mdx" }), "markdown")
check(".zshrc.local pattern", vim.filetype.match({ filename = ".zshrc.local" }), "sh")
check(".git/config pattern", vim.filetype.match({ filename = ".git/config" }), "gitconfig")
check(".git/ignore pattern", vim.filetype.match({ filename = ".git/ignore" }), "gitignore")

local function filetype_from_contents(filename, lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local filetype = vim.filetype.match({ filename = filename, buf = buf })
    vim.api.nvim_buf_delete(buf, { force = true })
    return filetype
end

check("deno shebang", filetype_from_contents("script", { "#!/usr/bin/env deno" }), "typescript")
check("deno shebang with -S", filetype_from_contents("script", { "#!/usr/bin/env -S deno" }), "typescript")

section("7. autocmds")
local autocmds = vim.api.nvim_get_autocmds({ group = "augroup_global" })
local events = {}
for _, autocmd in ipairs(autocmds) do
    events[autocmd.event] = true
end
check_true("TermOpen", events.TermOpen)
check_true("BufReadPost", events.BufReadPost)
check_true("TextYankPost", events.TextYankPost)

section("8. commands")
for _, name in ipairs({ "QuickLook", "Restart", "OpenUrl", "Browse", "EditConfig", "Daily" }) do
    check_true("command " .. name, command_exists(name))
end

local utils = require("hagata.utils")
local quicklook_path
local restore_quicklook = stub(utils, "open_file_with_quicklook", function(path)
    quicklook_path = path
end)
vim.cmd("QuickLook")
restore_quicklook()
check("QuickLook dispatches", quicklook_path, vim.fn.expand("%:p"))

section("9. utils")
local debounced = {}
local debounce = utils.debounce(function(value)
    debounced[#debounced + 1] = value
end, 20)
debounce(1)
debounce(2)
vim.wait(500, function()
    return #debounced > 0
end)
check("debounce coalesces", #debounced, 1)
check("debounce keeps last argument", debounced[1], 2)

local restore_executable = stub(vim.fn, "executable", function()
    return 0
end)
local notify_message
local restore_notify = stub(vim, "notify", function(message, level)
    notify_message = { message = message, level = level }
end)
utils.open_file_with_quicklook("/tmp/a b")
restore_notify()
restore_executable()
check("QuickLook unavailable message", notify_message.message, "QuickLook is not available on this system.")
check("QuickLook unavailable level", notify_message.level, vim.log.levels.ERROR)

restore_executable = stub(vim.fn, "executable", function(name)
    return name == "qlmanage" and 1 or 0
end)
local quicklook_command
local restore_cmd = stub(vim, "cmd", function(command)
    quicklook_command = command
end)
utils.open_file_with_quicklook("/tmp/a b")
restore_cmd()
restore_executable()
check("QuickLook command uses qlmanage", quicklook_command:find("qlmanage", 1, true) ~= nil, true)
check("QuickLook command quotes path", quicklook_command:find("'/tmp/a b'", 1, true) ~= nil, true)
check("utils.on_attach removed", utils.on_attach, nil)

section("10. lazy")
local lazy_module = require_or_fail("hagata.lazy")
if lazy_module then
    check("lazy.install", type(lazy_module.install), "function")
    check("lazy.setup", type(lazy_module.setup), "function")

    local restore_fs_stat = stub(vim.uv, "fs_stat", function()
        return {}
    end)
    local restore_system = stub(vim.fn, "system", function()
        error("lazy.nvim should not be cloned when it already exists")
    end)
    local install_ok, install_error = pcall(lazy_module.install)
    restore_system()
    restore_fs_stat()
    check_true("lazy.install skips existing install", install_ok)
    if not install_ok then
        print("    " .. tostring(install_error))
    end

    local lazy_options
    local restore_lazy = save_loaded("lazy", {
        setup = function(options)
            lazy_options = options
        end,
    })
    restore_fs_stat = stub(vim.uv, "fs_stat", function()
        return {}
    end)
    local setup_ok, setup_error = pcall(lazy_module.setup)
    restore_fs_stat()
    restore_lazy()
    check_true("lazy.setup runs", setup_ok)
    if not setup_ok then
        print("    " .. tostring(setup_error))
    end
    check("lazy defaults.lazy", lazy_options.defaults.lazy, true)
    check("lazy spec import", lazy_options.spec[1].import, "plugins")
    check("lazy concurrency", lazy_options.concurrency, 10)
    check("lazy dev.path", lazy_options.dev.path, "~/ghq/github.com/hagatasdelus/")
    check("lazy install.missing", lazy_options.install.missing, true)
    check("lazy install.colorscheme", lazy_options.install.colorscheme[1], "backpack")
    check("lazy checker.enabled", lazy_options.checker.enabled, false)
    check("lazy performance.cache.enabled", lazy_options.performance.cache.enabled, false)
    check("lazy performance.cache typo removed", lazy_options.performance.cache.enalbed, nil)
    local disabled_plugins = vim.tbl_get(lazy_options.performance, "rtp", "disabled_plugins") or {}
    check_deep("lazy rtp.disabled_plugins", disabled_plugins, {
        "gzip",
        "matchparen",
        "netrwPlugin",
        "rplugin",
        "shada",
        "spellfile",
        "tarPlugin",
        "tutor",
        "zipPlugin",
    })
    for _, name in ipairs(disabled_plugins) do
        local files = vim.fn.globpath(vim.env.VIMRUNTIME .. "/plugin", name .. ".*", false, true)
        check_true("lazy disabled plugin exists: " .. name, #files > 0)
    end
end

section("11. lsp servers")
local servers = require_or_fail("hagata.lsp.servers")
if servers then
    check_deep("servers", servers, {
        "efm",
        "yamlls",
        "jsonls",
        "taplo",
        "denols",
        "vtsls",
        "html",
        "lua_ls",
        "stylua",
        "pyright",
        "ruff",
        "tinymist",
    })
end

section("12. lsp setup")
local lsp = require_or_fail("hagata.lsp")
if servers and lsp then
    local config_calls = {}
    local enable_calls = {}
    local restore_lsp_config = stub(vim.lsp, "config", function(name, config)
        config_calls[#config_calls + 1] = { name = name, config = config }
    end)
    local restore_lsp_enable = stub(vim.lsp, "enable", function(names)
        enable_calls[#enable_calls + 1] = names
    end)
    lsp.setup()
    restore_lsp_enable()
    restore_lsp_config()
    check("lsp.config star", config_calls[1].name, "*")
    check("lsp capabilities", type(config_calls[1].config.capabilities), "table")
    check_deep("lsp.enable servers", enable_calls[1], servers)
    check_true("LspDiagnosticReset command", command_exists("LspDiagnosticReset"))

    local attach_calls = {}
    local restore_on_attach = save_loaded("hagata.lsp.on_attach", function(client, bufnr)
        attach_calls[#attach_calls + 1] = { client = client, bufnr = bufnr }
    end)
    local fake_client = { name = "test-client" }
    local restore_get_client = stub(vim.lsp, "get_client_by_id", function()
        return fake_client
    end)
    local attach_bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[attach_bufnr].filetype = "lua"
    vim.api.nvim_exec_autocmds("LspAttach", { buffer = attach_bufnr, data = { client_id = 1 } })
    check("LspAttach calls on_attach", #attach_calls, 1)
    check("LspAttach client", attach_calls[1].client, fake_client)
    check("LspAttach bufnr", attach_calls[1].bufnr, attach_bufnr)
    check("LspAttach omnifunc", vim.bo[attach_bufnr].omnifunc, "v:lua.vim.lsp.omnifunc")
    vim.bo[attach_bufnr].filetype = "oil"
    vim.api.nvim_exec_autocmds("LspAttach", { buffer = attach_bufnr, data = { client_id = 1 } })
    check("LspAttach ignores oil buffers", #attach_calls, 1)
    restore_get_client()
    restore_on_attach()
    vim.api.nvim_buf_delete(attach_bufnr, { force = true })
end

section("13. lsp on_attach")
local on_attach = require_or_fail("hagata.lsp.on_attach")
if on_attach then
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo[bufnr].filetype = "lua"
    local client = {
        name = "test-client",
        server_capabilities = {
            documentFormattingProvider = true,
            foldingRangeProvider = true,
        },
        supports_method = function(_, method)
            return method == "textDocument/formatting" or method == "textDocument/foldingRange"
        end,
        config = { settings = {} },
    }
    on_attach(client, bufnr)
    check("gd mapping", type(mapping("gd").callback), "function")
    check("gD mapping", type(mapping("gD").callback), "function")
    check("K mapping", type(mapping("K").callback), "function")
    check("signature help mapping", type(mapping("gk").callback), "function")
    check("workspace folder mapping", type(mapping("<leader>wa").callback), "function")
    check("format mapping", type(mapping("<leader><space>").callback), "function")
    check("diagnostic float mapping", type(mapping("<leader>ef").callback), "function")
    check("diagnostic jump mapping", mapping("[d").rhs, "<Cmd>lua vim.diagnostic.jump({count=-1, float=true})<CR>")
    check("diagnostic next mapping", mapping("]d").rhs, "<Cmd>lua vim.diagnostic.jump({count=1, float=true})<CR>")
    check("diagnostic loclist mapping", type(mapping("<leader>q").callback), "function")
    check("lspsaga finder mapping", mapping("<leader>lf").rhs, "<Cmd>Lspsaga finder<cr>")
    check("lspsaga hover mapping", mapping("<leader>lh").rhs, "<Cmd>Lspsaga hover_doc<cr>")
    check("lspsaga outline mapping", mapping("<leader>lo").rhs, "<Cmd>Lspsaga outline<cr>")
    check("lspsaga rename mapping", mapping("<leader>lr").rhs, "<Cmd>Lspsaga rename<cr>")
    check("lspsaga code action mapping", mapping("<leader>la").rhs, "<Cmd>Lspsaga code_action<cr>")
    check_true("Format command", command_exists("Format"))
    check_true("FormatToggle command", command_exists("FormatToggle"))
    check_true("FormatEnable command", command_exists("FormatEnable"))
    check_true("FormatDisable command", command_exists("FormatDisable"))
    check("foldmethod", vim.wo.foldmethod, "expr")
    check("foldexpr", vim.wo.foldexpr, "v:lua.vim.lsp.foldexpr()")
    check("foldlevel", vim.wo.foldlevel, 99)
    check("foldlevelstart", vim.o.foldlevelstart, 99)
    check("foldenable", vim.wo.foldenable, true)
    local format_autocmds = vim.api.nvim_get_autocmds({ group = "LspFormat." .. bufnr })
    check("format autocmd", #format_autocmds, 1)
    check("format autocmd event", format_autocmds[1].event, "BufWritePre")

    local format = require("hagata.lsp.on_attach.format")
    local format_options
    local restore_format = stub(vim.lsp.buf, "format", function(options)
        format_options = options
    end)
    local snacks = {
        notify = {
            info = function() end,
            warn = function() end,
            error = function() end,
        },
    }
    local previous_snacks = _G.Snacks
    _G.Snacks = snacks
    format.format()
    restore_format()
    check("format bufnr", format_options.bufnr, bufnr)
    check("format timeout", format_options.timeout_ms, 2000)
    check(
        "format filter accepts formatting client",
        format_options.filter({
            name = "test",
            supports_method = function()
                return true
            end,
            config = { settings = {} },
        }),
        true
    )
    check(
        "format filter rejects client without capability",
        format_options.filter({
            name = "test",
            supports_method = function()
                return false
            end,
            config = { settings = {} },
        }),
        false
    )
    check(
        "format filter rejects disabled format",
        format_options.filter({
            name = "test",
            supports_method = function()
                return true
            end,
            config = { settings = { format = false } },
        }),
        false
    )

    format.toggle()
    check("format toggle disables", vim.b.autoformat, false)
    format.enable()
    check("format enable clears buffer flag", vim.b.autoformat, nil)
    format.disable()
    check("format disable", format.autoformat, false)
    _G.Snacks = previous_snacks

    local fold = require("hagata.lsp.on_attach.fold")
    vim.wo.foldmethod = "manual"
    fold.on_attach({
        supports_method = function()
            return false
        end,
    }, bufnr)
    check("fold leaves unsupported client unchanged", vim.wo.foldmethod, "manual")
    vim.api.nvim_buf_delete(bufnr, { force = true })
end

section("14. plugin specs")
local mason_spec = require_or_fail("plugins.mason")
if mason_spec then
    check("mason spec count", #mason_spec, 2)
    check("mason repository", mason_spec[1][1], "https://github.com/mason-org/mason.nvim")
    check(
        "mason-lspconfig dependency",
        vim.tbl_contains(mason_spec[1].dependencies, "https://github.com/mason-org/mason-lspconfig.nvim"),
        true
    )
    check("mason event", mason_spec[1].event[1], "BufReadPre")
    check("mason cmd", mason_spec[1].cmd, "Mason")
    check("mason config", type(mason_spec[1].config), "function")
    check("lspconfig repository", mason_spec[2][1], "https://github.com/neovim/nvim-lspconfig")
    check(
        "schemastore dependency",
        vim.tbl_contains(mason_spec[2].dependencies, "https://github.com/b0o/schemastore.nvim"),
        true
    )
    check("lspconfig event", mason_spec[2].event[1], "BufReadPre")
    check("lspconfig init removed", mason_spec[2].init, nil)
    check("lspconfig config", type(mason_spec[2].config), "function")

    local mason_setup_calls = 0
    local mason_lspconfig_options
    local restore_mason = save_loaded("mason", {
        setup = function()
            mason_setup_calls = mason_setup_calls + 1
        end,
    })
    local restore_mason_lspconfig = save_loaded("mason-lspconfig", {
        setup = function(options)
            mason_lspconfig_options = options
        end,
    })
    mason_spec[1].config()
    restore_mason_lspconfig()
    restore_mason()
    check("mason.setup calls", mason_setup_calls, 1)
    if servers then
        check_deep("mason-lspconfig ensure_installed", mason_lspconfig_options.ensure_installed, servers)
    end
    check("mason-lspconfig automatic_installation", mason_lspconfig_options.automatic_installation, true)

    local lsp_setup_calls = 0
    local restore_hagata_lsp = save_loaded("hagata.lsp", {
        setup = function()
            lsp_setup_calls = lsp_setup_calls + 1
        end,
    })
    mason_spec[2].config()
    restore_hagata_lsp()
    check("lspconfig config calls hagata.lsp.setup", lsp_setup_calls, 1)
end

check_true("fyler actions load", pcall(require, "plugins.fyler.actions"))
check_true("oil custom actions load", pcall(require, "plugins.oil.custom_actions"))

section("15. plugin spec modules")
local spec_files = vim.fn.glob(nvim_dir .. "/lua/plugins/*.lua", false, true)
vim.list_extend(spec_files, vim.fn.glob(nvim_dir .. "/lua/plugins/*/init.lua", false, true))
for _, file in ipairs(spec_files) do
    local module = file
        :gsub("^" .. vim.pesc(nvim_dir .. "/lua/"), "")
        :gsub("%.lua$", "")
        :gsub("/init$", "")
        :gsub("/", ".")
    local ok, error_message = pcall(require, module)
    check_true("load " .. module, ok)
    if not ok then
        print("    " .. tostring(error_message))
    end
end

section("16. stale references")
local lua_files = vim.fn.glob(nvim_dir .. "/lua/**/*.lua", false, true)
vim.list_extend(lua_files, vim.fn.glob(nvim_dir .. "/after/**/*.lua", false, true))
vim.list_extend(lua_files, { nvim_dir .. "/init.lua" })
for _, file in ipairs(lua_files) do
    local contents = table.concat(vim.fn.readfile(file), "\n")
    local relative = file:gsub("^" .. vim.pesc(nvim_dir .. "/"), "")
    check_false(relative .. " has require(core)", contents:find('require("core', 1, true) ~= nil)
    check_false(relative .. " has require(config)", contents:find('require("config', 1, true) ~= nil)
    check_false(relative .. " has plugins.mason.on_attach", contents:find("plugins.mason.on_attach", 1, true) ~= nil)
end

print("")
if failures == 0 then
    print("all passed")
    vim.cmd("qa!")
else
    print(string.format("%d failed", failures))
    vim.cmd("cquit 1")
end

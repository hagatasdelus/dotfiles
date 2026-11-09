-- Tests the goda-cmp migration without loading the real plugins.
--
--   DOTFILES_DIR=... nvim --headless --clean -c "luafile scripts/tests/goda_cmp_test.lua"
--
-- goda.vim, goda-cmp.vim, pum.vim and skkelua are stubbed.
local repo = assert(os.getenv("DOTFILES_DIR"), "DOTFILES_DIR is required")

package.path = string.format("%s/common/config/nvim/lua/?.lua;%s/common/config/nvim/lua/?/init.lua;", repo, repo)
    .. package.path

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

local function stub_fn(name, fn)
    local previous = vim.fn[name]
    vim.fn[name] = fn
    return function()
        vim.fn[name] = previous
    end
end

_G.is_on_vscode = function()
    return false
end

print("1. lazy.nvim spec")
local spec = require("plugins.goda")
check("spec is a list", type(spec), "table")
local cmp_spec = assert(spec[1], "goda-cmp spec is missing")
check("repository", cmp_spec[1], "https://github.com/Shougo/goda-cmp.vim")
check("enabled", cmp_spec.enabled, true)
check("InsertEnter event", vim.tbl_contains(cmp_spec.event, "InsertEnter"), true)
check("CmdlineEnter event", vim.tbl_contains(cmp_spec.event, "CmdlineEnter"), true)
check("goda.vim dependency", vim.tbl_contains(cmp_spec.dependencies, "https://github.com/Shougo/goda.vim"), true)
check("pum.vim dependency", vim.tbl_contains(cmp_spec.dependencies, "https://github.com/Shougo/pum.vim"), true)
check("config function", type(cmp_spec.config), "function")

print("\n2. cmp setup")
local configured = {}
local pum_options
local built = 0
local enabled = 0

local restore = {
    stub_fn("executable", function()
        return 0
    end),
    stub_fn("goda_cmp#build", function()
        built = built + 1
        configured.build = true
    end),
    stub_fn("goda_cmp#enable", function()
        enabled = enabled + 1
        configured.enable = true
    end),
    stub_fn("pum#set_option", function(options)
        pum_options = options
        configured.pum = true
    end),
}

local cmp = require("plugins.goda.cmp")
cmp.setup()

check("config_dir", vim.g["goda_cmp#config_dir"], vim.fs.joinpath(vim.fn.stdpath("config"), "goda-cmp"))
check("build called", built, 1)
check("enable called", enabled, 1)
check("pum configured", configured.pum, true)
check("pum border", pum_options.border, "rounded")
check("pum preview", pum_options.preview, true)
check("pum previewer", pum_options.previewer, "goda_cmp#get_previewer")
check("GodaCmpBuild command", vim.fn.exists(":GodaCmpBuild"), 2)

for _, lhs in ipairs({
    "<Tab>",
    "<S-Tab>",
    "<C-n>",
    "<C-p>",
    "<Down>",
    "<Up>",
    "<C-b>",
    "<C-f>",
    "<C-l>",
    "<C-e>",
    "<CR>",
}) do
    local mapping = vim.fn.maparg(lhs, "i", false, true)
    check("insert mapping " .. lhs, type(mapping) == "table" and mapping.lhs ~= nil, true)
end

for _, rhs in ipairs(restore) do
    rhs()
end

print("\n3. skkelua vim_status patch")
local skk = {
    is_enabled = function()
        return true
    end,
    phase = function()
        return "henkan"
    end,
    get_pre_edit = function()
        return "▽かんじ"
    end,
    get_prefix = function()
        return "かんじ"
    end,
    vim_status = function()
        return {
            prevInput = "▽かんじ",
            completeType = "pum.vim",
            completeInfo = { pum_visible = true, selected = 0 },
            mode = "i",
        }
    end,
    complete_callback = function(midasi, word, type_)
        configured.complete_callback = { midasi = midasi, word = word, type = type_ }
    end,
    handle = function(name, opts)
        configured.handle = { name = name, opts = opts }
    end,
}
package.loaded["skkelua"] = skk
package.loaded["skkelua.store"] = {
    get_context = function()
        return { mode = "henkan", state = { henkanFeed = "かんじ", type = "henkan" } }
    end,
}

local skkelua = require("plugins.goda.skkelua")
skkelua.setup()

local restore_pum = stub_fn("pum#visible", function()
    return true
end)
local restore_item = stub_fn("pum#current_item", function()
    return { abbr = "[辞書登録]", word = "▽かんじ" }
end)

local status = skk.vim_status()
check("complete type", status.completeType, "pum.vim")
check("selected", status.completeInfo.selected, 0)
check(
    "register item",
    type(status.completeInfo.items) == "table"
        and status.completeInfo.items[1].user_data.nvim.lsp.completion_item.data.register,
    true
)

vim.fn["pum#current_item"] = function()
    return { abbr = "漢字", word = "漢字" }
end
status = skk.vim_status()
check("non register item", status.completeInfo.items, nil)

restore_item()
restore_pum()

print("\n4. skkelua source")
local list = {
    items = {
        {
            label = "漢字",
            textEdit = { newText = "漢字" },
            data = { skkelua = true, midasi = "かんじ", word = "漢字", type = "okurinasi" },
            sortText = "00001",
        },
        {
            label = "[辞書登録]",
            textEdit = { newText = "▽かんじ" },
            data = { skkelua = true, register = true },
            sortText = "00002",
        },
    },
}
package.loaded["skkelua.lsp"] = {
    _make_completion_list = function()
        return list
    end,
}

local gathered = skkelua.gather({
    context = { input = "abc▽かんじ", bufnr = 1, lnum = 1, col = 13, filetype = "markdown" },
})
check("gather start", gathered.start, 3)
check("gather item count", #gathered.items, 2)
check("gather word", gathered.items[1].word, "漢字")
check("gather abbr", gathered.items[1].abbr, "漢字")
check("gather kind", gathered.items[1].kind, "Text")
check("gather sort_text", gathered.items[1].sort_text, "00001")
check("gather data", gathered.items[1].data.word, "漢字")
check("register word", gathered.items[2].word, "▽かんじ")
check("register abbr", gathered.items[2].abbr, "[辞書登録]")
check("register data", gathered.items[2].data.register, true)

check("position", skkelua.position({ context = { input = "abc▽かんじ" } }), 3)
check("position without preedit", skkelua.position({ context = { input = "abc" } }), -1)

skkelua.complete({ data = { midasi = "かんじ", word = "漢字", type = "okurinasi" } })
check_deep(
    "complete_callback",
    configured.complete_callback,
    { midasi = "かんじ", word = "漢字", type = "okurinasi" }
)

skkelua.complete({ data = { register = true } })
vim.wait(1000, function()
    return configured.handle ~= nil
end)
check("register handle", configured.handle and configured.handle.opts["function"], "registerWord")

print("\n5. sources dispatcher")
local sources = require("plugins.goda.sources")
local dispatched = sources.gather({ name = "skkelua", context = { input = "abc▽かんじ" } })
check("dispatch gather", dispatched.start, 3)
check("dispatch position", sources.position({ name = "skkelua", context = { input = "abc▽かんじ" } }), 3)

print("\n6. nvim_lsp conversion")
local nvim_lsp = require("plugins.goda.nvim_lsp")
local conversion = nvim_lsp._convert_item({
    label = "Println",
    kind = 3,
    detail = "func(a ...any) (n int, err error)",
    documentation = { kind = "markdown", value = "Println formats" },
    filterText = "Println",
    sortText = "0001",
    textEdit = {
        range = { start = { line = 0, character = 6 }, ["end"] = { line = 0, character = 9 } },
        newText = "Println",
    },
}, "hello.World", "utf-16")
check("lsp word", conversion.word, "Println")
check("lsp abbr", conversion.abbr, "Println")
check("lsp kind", conversion.kind, "Function")
check("lsp info", conversion.info, "func(a ...any) (n int, err error)\n\nPrintln formats")
check("lsp filter_text", conversion.filter_text, "Println")
check("lsp sort_text", conversion.sort_text, "0001")
check("lsp start", conversion.start, 6)

local snippet = nvim_lsp._convert_item({
    label = "if",
    kind = 15,
    insertTextFormat = 2,
    textEdit = {
        range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } },
        newText = "if (${1:condition}) {\n\t$0\n}",
    },
}, "hello", "utf-8")
check("snippet word", snippet.word, "if (condition) {")
check("snippet data", snippet.data.snippet, "if (${1:condition}) {\n\t$0\n}")
check("lsp utf8 position", nvim_lsp._character("😀a", "utf-8"), 5)
check("lsp utf16 position", nvim_lsp._character("😀a", "utf-16"), 3)
check("lsp utf32 position", nvim_lsp._character("😀a", "utf-32"), 2)
local astral = nvim_lsp._convert_item({
    label = "x",
    kind = 1,
    textEdit = {
        range = { start = { line = 0, character = 3 }, ["end"] = { line = 0, character = 3 } },
        newText = "x",
    },
}, "😀ab", "utf-16")
check("lsp utf16 start", astral.start, 5)

print("\n7. nvim_lua source")
local nvim_lua = require("plugins.goda.nvim_lua")
local api_items = nvim_lua._items("vim", "vim.api")
check(
    "nvim_lua has nvim_get_current_buf",
    (function()
        for _, item in ipairs(api_items) do
            if item.word == "nvim_get_current_buf" then
                return true
            end
        end
        return false
    end)(),
    true
)
check("nvim_lua kind", api_items[1].kind ~= nil, true)

print("\n8. luasnip source")
local if_condition = function(line)
    return line:match("^if") ~= nil
end
package.loaded["luasnip"] = {
    get_snippets = function(filetype)
        if filetype ~= "lua" then
            return {}
        end
        return {
            { trigger = "if", id = 1, effective_priority = 100 },
            { trigger = "for", id = 2, effective_priority = 50 },
            { trigger = "hidden", id = 3, hidden = true },
        }
    end,
    get_id_snippet = function(id)
        if id == 1 then
            return {
                trigger = "if",
                id = 1,
                name = "if",
                show_condition = if_condition,
                get_docstring = function()
                    return "if doc"
                end,
            }
        end
        if id == 2 then
            return { trigger = "for", id = 2, name = "for" }
        end
        return nil
    end,
}
package.loaded["luasnip.util.util"] = {
    get_snippet_filetypes = function()
        return { "lua" }
    end,
}
local luasnip = require("plugins.goda.luasnip")
local if_items = luasnip.gather({ context = { input = "if", filetype = "lua" } })
check("luasnip start", if_items.start, 0)
check("luasnip condition matched", #if_items.items, 2)
check("luasnip priority", if_items.items[1].data.priority, 100)
local for_items = luasnip.gather({ context = { input = "for", filetype = "lua" } })
check("luasnip condition filtered", #for_items.items, 1)
check("luasnip condition filtered word", for_items.items[1].word, "for")
local resolved = luasnip.resolve({ data = { snip_id = 1, filetype = "lua" } })
check("luasnip resolve", type(resolved) == "table" and resolved.info:match("if doc") ~= nil, true)

print("\n9. completion keymaps")
local manual_calls = {}
local restore_manual = stub_fn("goda_cmp#map#manual_complete", function(options)
    manual_calls[#manual_calls + 1] = { options = options }
    return "<C-l>"
end)

local exists_names = {
    "*pum#visible",
    "*pum#current_item",
    "*goda_cmp#complete",
    "*goda_cmp#hide",
    "*goda_cmp#_shown",
}
local previous_exists = vim.fn.exists
vim.fn.exists = function(name)
    for _, candidate in ipairs(exists_names) do
        if name == candidate then
            return 1
        end
    end
    return previous_exists(name)
end

local pum = { visible = true }
local restore_visible = stub_fn("pum#visible", function()
    return pum.visible
end)

local function insert_callback(lhs)
    local mapping = vim.fn.maparg(lhs, "i", false, true)
    if type(mapping) == "table" and type(mapping.callback) == "function" then
        return mapping.callback
    end
    return nil
end

local function call_map(lhs)
    local callback = insert_callback(lhs)
    if not callback then
        return "<missing>"
    end
    return callback()
end

skk.phase = function()
    return "henkan"
end
check("Tab moves selection while converting", call_map("<Tab>"), "<Cmd>call pum#map#insert_relative(+1)<CR>")
check("S-Tab moves selection while converting", call_map("<S-Tab>"), "<Cmd>call pum#map#insert_relative(-1)<CR>")
check("C-n selects next while converting", call_map("<C-n>"), "<Cmd>call pum#map#select_relative(+1)<CR>")
check("C-p selects previous while converting", call_map("<C-p>"), "<Cmd>call pum#map#select_relative(-1)<CR>")
check("C-y confirms selection", call_map("<C-y>"), "<Cmd>call pum#map#confirm()<CR>")

skk.phase = function()
    return "input"
end
check("C-n inserts next without SKK", call_map("<C-n>"), "<Cmd>call pum#map#insert_relative(+1)<CR>")
check("C-p inserts previous without SKK", call_map("<C-p>"), "<Cmd>call pum#map#insert_relative(-1)<CR>")

local item = { word = "漢字" }
local notified
local restore_item = stub_fn("pum#current_item", function()
    return item
end)
local previous_notify = vim.notify
vim.notify = function(message)
    notified = message
end
local notify_map = insert_callback("<C-X><CR>")
check("C-X CR insert mapping", type(notify_map), "function")
if notify_map then
    notify_map()
end
check("C-X CR notifies current item", notified, vim.inspect(item))
local cmdline_notify = vim.fn.maparg("<C-X><CR>", "c", false, true)
check("C-X CR cmdline mapping", type(cmdline_notify) == "table" and type(cmdline_notify.callback), "function")
vim.notify = previous_notify
restore_item()

pum.visible = false
local restore_col = stub_fn("col", function()
    return 6
end)
local restore_getline = stub_fn("getline", function()
    return "hello"
end)
check("Tab completes manually after a word", call_map("<Tab>"), "<C-l>")
check("Tab manual sources without SKK", manual_calls[#manual_calls].options, nil)
restore_getline()
restore_getline = stub_fn("getline", function()
    return "hello "
end)
check("Tab is literal after whitespace", call_map("<Tab>"), "<Tab>")
restore_getline()

skk.phase = function()
    return "henkan"
end
restore_getline = stub_fn("getline", function()
    return "hello"
end)
check("Tab completes manually while converting", call_map("<Tab>"), "<C-l>")
check_deep("Tab manual sources while converting", manual_calls[#manual_calls].options, { sources = { "skkelua" } })
restore_getline()
restore_col()

check("S-Tab is literal without pum", call_map("<S-Tab>"), "<S-Tab>")
check("C-n completes manually without pum", call_map("<C-n>"), "<C-l>")
check_deep("C-n manual sources while converting", manual_calls[#manual_calls].options, { sources = { "skkelua" } })

restore_visible()
restore_manual()

print("\n10. skkelua handled")
local hide_count = 0
local completed_options
local shown = { items = { { word = "漢字" } }, sources = { "skkelua" }, seq = 1 }
local restore_hide = stub_fn("goda_cmp#hide", function()
    hide_count = hide_count + 1
end)
local restore_complete = stub_fn("goda_cmp#complete", function(options)
    completed_options = options
end)
local restore_shown = stub_fn("goda_cmp#_shown", function()
    return shown
end)

local function fire_handled()
    vim.api.nvim_exec_autocmds("User", { pattern = "skkelua-handled" })
end

skk.phase = function()
    return "input"
end
fire_handled()
vim.wait(100, function()
    return hide_count == 1
end)
check("hides stale popup after conversion", hide_count, 1)

shown = { items = {}, sources = { "nvim_lsp" }, seq = 1 }
fire_handled()
vim.wait(50)
check("keeps popup from other sources", hide_count, 1)

shown = { items = { { word = "漢字" } }, sources = { "skkelua" }, seq = 1 }
skk.phase = function()
    return "henkan"
end
fire_handled()
vim.wait(100, function()
    return completed_options ~= nil
end)
check_deep("completes while converting", completed_options, { sources = { "skkelua" } })
check("does not hide while converting", hide_count, 1)

restore_shown()
restore_complete()
restore_hide()
vim.fn.exists = previous_exists

print("")
if failures == 0 then
    print("all passed")
    vim.cmd("qa!")
else
    print(string.format("%d failed", failures))
    vim.cmd("cquit 1")
end

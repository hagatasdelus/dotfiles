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
    return 1
end)
local restore_item = stub_fn("pum#current_item", function()
    return { abbr = "[辞書登録]", word = "▽かんじ" }
end)

local status = skk.vim_status()
check("complete type", status.completeType, "pum.vim")
check("selected", status.completeInfo.selected, 0)
check("register item", status.completeInfo.items[1].user_data.nvim.lsp.completion_item.data.register, true)

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

print("")
if failures == 0 then
    print("all passed")
    vim.cmd("qa!")
else
    print(string.format("%d failed", failures))
    vim.cmd("cquit 1")
end

return {
    "https://github.com/delphinus/md-render.nvim",
    version = "*",
    dependencies = {
        { "https://github.com/nvim-tree/nvim-web-devicons", version = "*" },
        { "https://github.com/delphinus/budoux.lua", version = "*" },
    },
    keys = {
        { "<Leader>mp", "<Plug>(md-render-preview)", desc = "Markdown preview (toggle)" },
        { "<Leader>mt", "<Plug>(md-render-preview-tab)", desc = "Markdown preview in tab (toggle)" },
        { "<Leader>md", "<Plug>(md-render-deno)", desc = "Markdown render demo" },
    },
}

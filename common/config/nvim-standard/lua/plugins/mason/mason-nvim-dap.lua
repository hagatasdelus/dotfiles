return {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
        "williamboman/mason.nvim",
        "mfussenegger/nvim-dap",
    },
    opts = {
        ensure_installed = {
            "python",
            "js",
            "javadbg",
            "javatest",
        },
        handlers = {},
    },
}

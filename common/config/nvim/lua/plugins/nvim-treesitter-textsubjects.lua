return {
    "https://github.com/RRethy/nvim-treesitter-textsubjects",
    config = function()
        require("nvim-treesitter-textsubjects").configue({
            prev_selection = ",", -- (Optional) keymap to select the previous selection
            keymaps = {
                ["."] = "textsubjects-smart",
                [";"] = "textsubjects-container-outer",
                ["i;"] = {
                    "textsubjects-container-inner",
                    desc = "Select inside containers (classes, functions, etc,)",
                },
            },
        })
    end,
}

---@type LazySpec
return {
    "https://github.com/windwp/nvim-autopairs",
    enabled = true,
    event = "InsertEnter",
    opts = function()
        return {
            break_undo = false,
            map_c_h = true,
        }
    end,
    config = function(_, opts)
        local autopairs = require("nvim-autopairs")
        autopairs.setup(opts)
    end,
}

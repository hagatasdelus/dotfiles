local Ascii = {
    nvim_3d_italic = {
        [[                                   __                ]],
        [[      ___     ___    ___   __  __ /\_\    ___ ___    ]],
        [[     / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
        [[    /\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
        [[    \ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
        [[     \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
    },
}

return {
    "goolord/alpha-nvim",
    event = { "VimEnter" },
    opts = function()
        local theta = require("alpha.themes.theta")
        local dashboard = require("alpha.themes.dashboard")
        theta.header.val = Ascii.nvim_3d_italic
        theta.buttons.val = {
            dashboard.button("e", "  New file", "<Cmd>enew<CR>"),
            dashboard.button("s", "  Restore Session", '<Cmd>lua require("persistence").load()<CR>'),
            dashboard.button("f", "  Files", "<Cmd>Telescope smart_open<CR>"),
            dashboard.button(".", "󰈙  Explorer", "<Cmd>Neotree toggle<CR>"),
            dashboard.button("r", "  MRU", "<Cmd>Telescope oldfiles<CR>"),
            dashboard.button("z", "󰒲  Lazy", "<Cmd>Lazy<CR>"),
            dashboard.button("q", "󰅚  Quit", "<Cmd>q<CR>"),
        }
        return theta.config
    end,
    config = function(_, opts)
        require("alpha").setup(opts)
    end,
}

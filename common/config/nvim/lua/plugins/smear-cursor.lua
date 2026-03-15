return {
    "https://github.com/sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
        stiffness = 0.7,
        trailing_stiffness = 0.6,
        stiffness_insert_mode = 0.7,
        trailing_stiffness_insert_mode = 0.7,
        matrix_pixel_threshold = 0.5,
        damping = 0.95,
        damping_insert_mode = 0.95,
        time_interval = 7,
    },
}

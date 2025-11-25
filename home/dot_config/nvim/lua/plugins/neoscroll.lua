return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy",
  opts = {
    -- Smooth animation easing function
    easing_function = "quadratic",
    -- Hide cursor during scroll animation
    hide_cursor = true,
    -- Stop scrolling on input
    stop_eof = true,
    -- Respect scrolloff option
    respect_scrolloff = false,
    cursor_scrolls_alone = true,
  },
  config = function(_, opts)
    local neoscroll = require("neoscroll")
    neoscroll.setup(opts)

    -- Configure smooth mouse scrolling
    -- Scroll 2 lines per mouse wheel event with animation
    local keymap = {
      ["<ScrollWheelUp>"] = function()
        neoscroll.scroll(-2, { move_cursor = true, duration = 100 })
      end,
      ["<ScrollWheelDown>"] = function()
        neoscroll.scroll(2, { move_cursor = true, duration = 100 })
      end,
    }

    local modes = { "n", "v", "x" }
    for key, func in pairs(keymap) do
      vim.keymap.set(modes, key, func)
    end
  end,
}

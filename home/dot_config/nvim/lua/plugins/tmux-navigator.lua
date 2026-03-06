return {
  -- Zellij navigation (active when inside zellij)
  {
    "swaits/zellij-nav.nvim",
    lazy = true,
    event = "VeryLazy",
    cond = function() return vim.fn.getenv("ZELLIJ") ~= vim.NIL end,
    keys = {
      { "<c-h>", "<cmd>ZellijNavigateLeftTab<cr>",  { silent = true, desc = "navigate left or tab" } },
      { "<c-j>", "<cmd>ZellijNavigateDown<cr>",     { silent = true, desc = "navigate down" } },
      { "<c-k>", "<cmd>ZellijNavigateUp<cr>",       { silent = true, desc = "navigate up" } },
      { "<c-l>", "<cmd>ZellijNavigateRightTab<cr>", { silent = true, desc = "navigate right or tab" } },
    },
    opts = {},
  },
  -- Tmux navigation (custom edge-aware replacement for vim-tmux-navigator)
  -- Switches tmux windows at pane boundaries instead of stopping at the edge.
  -- Uses keys spec so lazy.nvim overrides LazyVim's default <C-h/j/k/l> maps.
  {
    name = "tmux-nav",
    dir = vim.fn.stdpath("config"),
    cond = function() return vim.fn.getenv("TMUX") ~= vim.NIL end,
    keys = {
      { "<c-h>", function() require("config.tmux-nav").navigate("h") end, desc = "navigate left or prev window" },
      { "<c-j>", function() require("config.tmux-nav").navigate("j") end, desc = "navigate down" },
      { "<c-k>", function() require("config.tmux-nav").navigate("k") end, desc = "navigate up" },
      { "<c-l>", function() require("config.tmux-nav").navigate("l") end, desc = "navigate right or next window" },
      { "<c-\\>", function() require("config.tmux-nav").navigate_previous() end, desc = "last pane" },
    },
  },
}

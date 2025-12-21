return {
  -- https://github.com/folke/snacks.nvim
  "folke/snacks.nvim",
  opts = {
    ---@class snacks.dim.Config
    dim = {
      ---@type snacks.scope.Config
      scope = {
        min_size = 9,
        max_size = 25,
        siblings = true,
      },
      -- animate scopes. Enabled by default for Neovim >= 0.10
      -- Works on older versions but has to trigger redraws during animation.
      ---@type snacks.animate.Config|{enabled?: boolean}
      animate = {
        enabled = false, -- it really lags behind
        easing = "outQuad",
        duration = {
          step = 20, -- ms per step
          total = 200, -- maximum duration
        },
      },
      -- what buffers to dim
      filter = function(buf)
        return vim.g.snacks_dim ~= false and vim.b[buf].snacks_dim ~= false and vim.bo[buf].buftype == ""
      end,
    },
    gh = { enabled = true },
    image = { enabled = true },
    picker = {
      sources = {
        files = { hidden = true },
        grep = { hidden = true },
        explorer = { hidden = true, ignored = true },
      },
    },
    explorer = {
      ignored = true,
      hidden = true,
    },
    zen = {},
  },
  keys = {
    {
      "<leader>gi",
      function()
        Snacks.picker.gh_issue()
      end,
      desc = "GitHub Issues (open)",
    },
    {
      "<leader>gI",
      function()
        Snacks.picker.gh_issue({ state = "all" })
      end,
      desc = "GitHub Issues (all)",
    },
    {
      "<leader>gp",
      function()
        Snacks.picker.gh_pr()
      end,
      desc = "GitHub Pull Requests (open)",
    },
    {
      "<leader>gP",
      function()
        Snacks.picker.gh_pr({ state = "all" })
      end,
      desc = "GitHub Pull Requests (all)",
    },
  },
}

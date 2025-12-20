-- Completion configuration
local cached_api_key = nil

return {
  {
    "milanglacier/minuet-ai.nvim",
    config = function()
      require("minuet").setup({
        provider = "openai_compatible",
        request_timeout = 2.5,
        throttle = 1500, -- Increase to reduce costs and avoid rate limits
        debounce = 600, -- Increase to reduce costs and avoid rate limits
        provider_options = {
          openai_compatible = {
            api_key = function()
              if not cached_api_key then
                cached_api_key = vim.fn.system("op read op://Private/OpenRouter/minuet-api-token"):gsub("%s+$", "")
              end
              return cached_api_key
            end,
            end_point = "https://openrouter.ai/api/v1/chat/completions",
            model = "moonshotai/kimi-k2",
            name = "Openrouter",
            optional = {
              max_tokens = 56,
              top_p = 0.9,
              provider = {
                -- Prioritize throughput for faster completion
                sort = "throughput",
              },
            },
          },
        },
      })
    end,
  },
  { "nvim-lua/plenary.nvim" },
  -- optional, if you are using virtual-text frontend, nvim-cmp is not required.
  -- { "hrsh7th/nvim-cmp" },
  -- Configure blink.cmp (LazyVim default)
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      -- opts.enabled = function()
      --   -- Disable in markdown files
      --   return vim.bo.filetype ~= "markdown"
      -- end
      opts.keymap = opts.keymap or {}
      opts.keymap["<A-y>"] = require("minuet").make_blink_map()

      opts.sources = opts.sources or {}
      opts.sources.default = { "minuet" }
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.minuet = {
        name = "minuet",
        module = "minuet.blink",
        async = true,
        timeout_ms = 3000,
        score_offset = 50,
      }

      opts.completion = opts.completion or {}
      opts.completion.trigger = opts.completion.trigger or {}
      opts.completion.trigger.prefetch_on_insert = false

      return opts
    end,
  },
}

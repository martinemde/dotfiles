-- Completion configuration
--
local openrouter = {
  name = "OpenRouter",
  model = "mistralai/codestral-2508",
  api_key = "OPENROUTER_API_KEY", -- Fetches this key
  -- api_key = function()
  --   if not cached_api_key then
  --     cached_api_key = vim.fn.system("op read op://Private/OpenRouter/minuet-api-token"):gsub("%s+$", "")
  --   end
  --   return cached_api_key
  -- end,
  end_point = "https://openrouter.ai/api/v1/chat/completions",
  optional = {
    max_tokens = 128,
    top_p = 0.95,
    provider = {
      -- Prioritize throughput for faster completion
      sort = "throughput",
    },
  },
}
-- Was attempting to make model selection pickable
-- gemini = vim.tbl_deep_extend("force", {}, openrouter, {
--   name = "Gemini 3 Flash Preview",
--   model = "google/gemini-3-flash-preview",
-- }),
-- kimi = vim.tbl_deep_extend("force", {}, openrouter, {
--   name = "Kimi K2",
--   model = "moonshotai/kimi-k2",
-- }),
-- grok = vim.tbl_deep_extend("force", {}, openrouter, {
--   name = "Grok Code Fast 1",
--   model = "x-ai/grok-code-fast-1", -- Haven't seen it work yet
-- }),
-- qwen = vim.tbl_deep_extend("force", {}, openrouter, {
--   name = "Qwen-3-coder-free",
--   model = "qwen/qwen3-coder:free",
-- }),

return {
  {
    "milanglacier/minuet-ai.nvim",
    config = function()
      require("minuet").setup({
        provider = "openai_compatible",
        request_timeout = 2.5,
        throttle = 1500, -- Increase to reduce costs and avoid rate limits
        debounce = 600, -- Increase to reduce costs and avoid rate limits
        add_single_line_entry = true,
        provider_options = {
          openai_compatible = openrouter,
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
      opts.keymap.preset = "super-tab"
      opts.keymap["<C-CR>"] = require("minuet").make_blink_map()

      opts.sources = opts.sources or {}
      -- opts.sources.default = { "minuet" }
      opts.sources.default = { "lsp", "path", "buffer", "snippets", "minuet" }
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.minuet = {
        name = "minuet",
        module = "minuet.blink",
        async = true,
        timeout_ms = 3000,
        score_offset = 50,
      }

      opts.completion.ghost_text = {
        enabled = true,
      }
      -- opts.completion.menu.auto_show = false
      -- opts.completion.list.selection.preselect = false

      -- opts.completion = opts.completion or {}
      -- opts.completion.trigger = opts.completion.trigger or {}
      -- opts.completion.trigger.prefetch_on_insert = true

      return opts
    end,
  },
}

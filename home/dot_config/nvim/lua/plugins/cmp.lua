return {
  {

    "saghen/blink.cmp",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      sources = {
        default = { "lsp", "path", "buffer", "snippets" },
      },
      keymap = {
        preset = "super-tab",
        ["<Tab>"] = {
          "snippet_forward",
          function() -- sidekick next edit suggestion
            return require("sidekick").nes_jump_or_apply()
          end,
          function() -- if you are using Neovim's native inline completions
            return vim.lsp.inline_completion.get()
          end,
          "fallback",
        },
        ["<S-Tab>"] = {
          "snippet_backward",
          function() -- sidekick previous edit suggestion
            return require("sidekick").nes_jump_or_apply()
          end,
          "fallback",
        },
        ["<C-CR>"] = {
          function() -- Manually trigger copilot NES and show completions
            require("sidekick.nes").update() -- Request copilot suggestions
            require("blink.cmp").show() -- Show completion menu
          end,
        },
      },
    },
  },
}

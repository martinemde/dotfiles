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
      },
    },
  },
}

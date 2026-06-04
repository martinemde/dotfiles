-- Guard LazyVim's ts-context-commentstring integration against parser-less buffers.
--
-- LazyVim's coding/mini-comment extra points mini.comment's `custom_commentstring`
-- straight at `ts_context_commentstring.calculate_commentstring()`. That call throws
-- (E5108: attempt to index local 'language_tree') in any buffer whose filetype maps
-- to a tree-sitter language with no installed parser -- e.g. `.env` files (filetype
-- `env`, for which no grammar exists). The plugin reads `vim.treesitter.get_parser()`
-- (nil here) and indexes it before reaching its own nil-check.
--
-- Wrapping the call in pcall turns that throw into the buffer's own commentstring
-- (`# %s` for env files) -- the right answer when there's no parser to do
-- context-aware comment detection. Mirrors the extra's existing `or vim.bo.commentstring`.
return {
  {
    "nvim-mini/mini.comment",
    opts = {
      options = {
        custom_commentstring = function()
          local ok, commentstring = pcall(function()
            return require("ts_context_commentstring.internal").calculate_commentstring()
          end)
          return (ok and commentstring) or vim.bo.commentstring
        end,
      },
    },
  },
}

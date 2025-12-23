-- The version for lazy.nvim and LazyVim will default to the latest stable release.
-- If you'd rather use the latest development version, add the code below to your specs:
-- https://www.lazyvim.org/configuration/lazy.nvim
return {
  { "folke/lazy.nvim", version = false },
  { "LazyVim/LazyVim", version = false },
  -- Disable the following plugins
  { "nvim-mini/mini.pairs", enabled = false },
  --
  -- Ensure the following plugins are installed
  -- No configuration needed
  "gbprod/yanky.nvim", -- https://www.lazyvim.org/extras/coding/yanky
  "smjonas/inc-rename.nvim", -- https://www.lazyvim.org/extras/editor/inc-rename
  "ThePrimeagen/refactoring.nvim", -- https://www.lazyvim.org/extras/editor/refactoring
  "monaqa/dial.nvim", -- https://www.lazyvim.org/extras/editor/dial
  "folke/edgy.nvim", -- https://www.lazyvim.org/extras/ui/edgy
  {
    "bezhermoso/tree-sitter-ghostty",
    build = "make nvim_install",
  },
}

-- This editor is for reading and editing text, not a language-tool installer.
return {
  { "neovim/nvim-lspconfig", enabled = false },
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "folke/lazydev.nvim", enabled = false },
  { "stevearc/conform.nvim", enabled = false },
  { "mfussenegger/nvim-lint", enabled = false },
  { "saghen/blink.cmp", enabled = false },
  { "hrsh7th/nvim-cmp", enabled = false },
  -- Markdown rendering stays in Neovim; no separate browser-preview installer.
  { "iamcco/markdown-preview.nvim", enabled = false },
}

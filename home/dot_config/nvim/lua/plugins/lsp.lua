return {
  -- add any tools you want to have installed below
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "copilot-language-server",
        "gitleaks",
        "hadolint",
        "markdown-oxide", -- Obsidian Markdown
        "markdownlint-cli2",
        "prettier",
        "pyright",
        "rubocop",
        "ruby-lsp",
        "rust-analyzer",
        "shellcheck",
        "shfmt",
        "stylua",
        "svelte-language-server",
        "tailwindcss-language-server",
      },
    },
  },
}

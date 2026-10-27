-- Copilot LSP configuration for sidekick.nvim
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#copilot
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        copilot = {
          -- Disable Copilot autocomplete, including native inline completions.
          enabled = false,
          -- brew install github-copilot-cli
          filetypes = {
            "lua",
            "javascript",
            "typescript",
            "python",
            "ruby",
            "go",
            "rust",
            "java",
            "c",
            "cpp",
            "sh",
            "bash",
            "zsh",
            "yaml",
            "json",
            "markdown",
          },
        },
      },
    },
  },
}

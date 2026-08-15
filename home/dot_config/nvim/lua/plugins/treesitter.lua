return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Avoid starting parser downloads that the headless bootstrap process
      -- would terminate on exit. Normal Neovim sessions still ensure them.
      if vim.env.LAZY_BOOTSTRAP_RESTORE == "1" then
        opts.ensure_installed = {}
        return
      end

      vim.list_extend(opts.ensure_installed or {}, {
        "bash",
        "comment",
        "dockerfile",
        "editorconfig",
        "ghostty",
        "gotmpl",
        "html",
        "javascript",
        "json",
        "lua",
        "luadoc",
        "mermaid",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "ruby",
        "rust",
        "svelte",
        "tmux",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "yaml",
        "zig",
        "zsh",
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    opts = {
      mode = "topline",
    },
  },
}

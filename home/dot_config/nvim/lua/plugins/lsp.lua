return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
        config = function()
          require("lsp_lines").setup()
          vim.diagnostic.config({
            virtual_text = false,
            virtual_lines = true,
          })

          Snacks.toggle({
            name = "Virtual Lines",
            get = function()
              local config = vim.diagnostic.config() ---@cast config -nil
              return not not config.virtual_lines
            end,
            set = function(state)
              vim.diagnostic.config({
                virtual_text = not state,
                virtual_lines = state,
              })
            end,
          }):map("<leader>uv")
        end,
      },
    },
    opts = {
      diagnostics = {
        virtual_text = false,
        virtual_lines = true,
      },
    },
  },
  -- add any tools you want to have installed below
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "bash-language-server", -- Bash LSP
        "copilot-language-server", -- Tab completions and Next Edit Suggestions from GitHub Copilot
        "docker-compose-language-service", -- Docker Compose LSP
        "dockerfile-language-server", -- Dockerfile LSP
        "eslint-lsp", -- ESLint LSP
        "gitleaks", -- Secret scanning
        "gofumpt", -- Go code formatter
        "goimports", -- Go import formatter
        "golangci-lint", -- Go linter
        "gopls", -- Go LSP
        "hadolint", -- Dockerfile linter
        "herb-language-server", -- HTML+ERB for Ruby on Rails
        "json-lsp", -- JSON LSP
        "lua-language-server", -- Lua LSP
        "markdown-oxide", -- Obsidian Markdown
        "markdown-toc", -- Markdown table of contents generator
        "markdownlint-cli2", -- Markdown linter
        "marksman", -- Markdown LSP
        "prettier", -- Code formatter
        "pyright", -- Python LSP
        "rubocop", -- Ruby linter and formatter
        "ruby-lsp", -- Ruby LSP
        "ruff", -- Python linter
        "rust-analyzer", -- Rust LSP
        "shellcheck", -- Shell script linter
        "shfmt", -- Shell script formatter
        "stylua", -- Lua formatter
        "svelte-language-server", -- Svelte LSP
        "tailwindcss-language-server", -- Tailwind CSS LSP
        "terraform-ls", -- Terraform LSP
        "tflint", -- Terraform linter
        "tree-sitter-cli", -- Tree-sitter parser generator
        "yaml-language-server", -- YAML LSP
        "zls", -- Zig LSP
      },
    },
  },
}

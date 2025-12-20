return {
  -- Add fzf-lua picker for LazyVim
  {
    "ibhagwan/fzf-lua",
    -- LazyVim will use this as the picker
    lazy = false,
    opts = {
      -- Show hidden files by default in all pickers
      files = {
        fd_opts = "--color=never --type f --hidden --follow --exclude .git",
      },
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git/'",
      },
    },
  },
}

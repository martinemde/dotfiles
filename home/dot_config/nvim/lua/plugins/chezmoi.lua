return {
  "alker0/chezmoi.vim",
  {
    "xvzc/chezmoi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "ChezmoiEdit" },
    opts = {
      edit = {
        force = false, -- default
        watch = true, -- Automatically apply changes when editing dotfiles
      },
      notification = {
        on_open = true, -- default
        on_apply = true, -- default
        on_watch = true, -- notify when a dotfile will be auto applied
      },
    },
  },
}

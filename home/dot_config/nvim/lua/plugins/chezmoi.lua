return {
  "alker0/chezmoi.vim",
  {
    "xvzc/chezmoi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "ChezmoiEdit" },
    opts = {
      edit = {
        watch = true,
        force = false,
      },
      notification = {
        on_open = true,
        on_apply = true,
        on_watch = true,
      },
    },
  },
}

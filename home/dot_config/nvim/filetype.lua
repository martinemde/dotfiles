-- Custom filetype detection
vim.filetype.add({
  pattern = {
    -- MDSvex: Markdown preprocessor for Svelte (similar to MDX for React)
    ["*.svx"] = "markdown",
    ["*.ghostty"] = "ghostty",
  },
})

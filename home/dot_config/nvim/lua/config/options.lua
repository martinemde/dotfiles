-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Automatically reload files when changed outside of Neovim
vim.opt.autoread = true

vim.opt.list = true
vim.opt.listchars = {
  trail = "⋅",
  nbsp = "⋅",
}

-- Start server for remote file opening via hyperlinks
-- This allows terminal hyperlinks to open files in existing nvim instance
if vim.fn.has("nvim") == 1 and vim.fn.serverstart then
  local server_addr = "/tmp/nvimsocket"
  -- Only start server if not already running and not in nested nvim
  if vim.fn.serverlist() == {} and not vim.env.NVIM then
    vim.fn.serverstart(server_addr)
  end
end
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

local o = vim.opt

-- Start server for remote file opening via hyperlinks
-- This allows terminal hyperlinks to open files in existing nvim instance
if vim.fn.has("nvim") == 1 and vim.fn.serverstart then
  local server_addr = "/tmp/nvimsocket"
  -- Only start server if not already running and not in nested nvim
  if vim.fn.serverlist() == {} and not vim.env.NVIM then
    vim.fn.serverstart(server_addr)
  end
end

-- Editor options

o.number = true -- Print the line number in front of each line
o.relativenumber = false -- Show the line number relative to the line with the cursor in front of each line.
o.clipboard = "unnamedplus" -- uses the clipboard register for all operations except yank.
o.syntax = "on" -- When this option is set, the syntax with this name is loaded.
o.autoindent = true -- Copy indent from current line when starting a new line.
o.cursorline = true -- Highlight the screen line of the cursor with CursorLine.
o.expandtab = true -- In Insert mode: Use the appropriate number of spaces to insert a <Tab>.
o.shiftwidth = 2 -- Number of spaces to use for each step of (auto)indent.
o.tabstop = 2 -- Number of spaces that a <Tab> in the file counts for.
o.encoding = "UTF-8" -- Sets the character encoding used inside Vim.
o.ruler = true -- Show the line and column number of the cursor position, separated by a comma.
o.mouse = "a" -- Enable the use of the mouse. "a" you can use on all modes
o.title = true -- When on, the title of the window will be set to the value of 'titlestring'
o.hidden = true -- When on a buffer becomes hidden when it is |abandon|ed
o.wildmenu = true -- When 'wildmenu' is on, command-line completion operates in an enhanced mode.
o.showcmd = true -- Show (partial) command in the last line of the screen. Set this option off if your terminal is slow.
o.showmatch = true -- When a bracket is inserted, briefly jump to the matching one.
o.inccommand = "split" -- When nonempty, shows the effects of :substitute, :smagic, :snomagic and user commands with the :command-preview flag as you type.
o.termguicolors = true
o.autoread = true -- Automatically reload files when changed outside of Neovim
o.list = true -- Show certain invisible characters
o.listchars = {
  trail = "⋅",
  nbsp = "⋅",
  tab = "› ",
}

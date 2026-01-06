-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Git commit rulers for best practices (50 chars for subject, 72 for body)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.colorcolumn = "50,72"
  end,
})

-- Automatically check for file changes when focus returns or buffer is entered
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "TermClose", "TermLeave" }, {
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Chezmoi template filetype detection with base language support
-- Detects base filetype from pattern like .json.tmpl, .yaml.tmpl, etc.
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.tmpl",
  callback = function()
    local filename = vim.fn.expand("%:t")

    -- Extract base filetype from patterns like .json.tmpl, .yaml.tmpl, .sh.tmpl
    local base_ft = filename:match("%.([^.]+)%.tmpl$")

    -- Normalize some extensions to their proper filetypes
    local ft_map = {
      sh = "bash",
      yml = "yaml",
      zsh = "bash",
    }

    if base_ft then
      base_ft = ft_map[base_ft] or base_ft
      -- Set compound filetype: base.gotmpl (e.g., json.gotmpl, yaml.gotmpl)
      vim.bo.filetype = base_ft .. ".gotmpl"

      -- Store base language for injection queries
      vim.b.gotmpl_base_lang = base_ft
    else
      -- No base extension detected, just use gotmpl
      vim.bo.filetype = "gotmpl"
      vim.b.gotmpl_base_lang = nil
    end
  end,
})


-- tmux-nav.lua — edge-aware tmux/vim navigation
--
-- Replaces vim-tmux-navigator with a custom implementation that switches
-- tmux windows at pane boundaries (left→previous-window, right→next-window).

local M = {}

local pane_flag = { h = "-L", j = "-D", k = "-U", l = "-R" }
local edge_var = { h = "pane_at_left", l = "pane_at_right" }
local window_cmd = { h = "previous-window", l = "next-window" }

-- Which axis (1=row, 2=col) each direction moves along, and expected sign.
local dir_axis = { h = { 2, -1 }, l = { 2, 1 }, k = { 1, -1 }, j = { 1, 1 } }

local function tmux(cmd)
  vim.fn.system("tmux " .. cmd)
end

local function at_tmux_edge(dir)
  local var = edge_var[dir]
  if not var then return false end
  return vim.trim(vim.fn.system("tmux display-message -p '#{" .. var .. "}'")) == "1"
end

--- Navigate in direction (h/j/k/l), crossing vim splits then tmux panes/windows.
function M.navigate(dir)
  local cur_win = vim.api.nvim_get_current_win()
  local cur_pos = vim.api.nvim_win_get_position(cur_win)

  vim.cmd("wincmd " .. dir)

  local new_win = vim.api.nvim_get_current_win()
  if new_win ~= cur_win then
    -- wincmd moved us — verify it went in the right direction
    local new_pos = vim.api.nvim_win_get_position(new_win)
    local axis, sign = unpack(dir_axis[dir])
    local delta = new_pos[axis] - cur_pos[axis]
    if delta * sign > 0 then return end
    -- Moved wrong way (wrapped) or sideways — undo and fall through to tmux
    vim.api.nvim_set_current_win(cur_win)
  end

  -- Reached vim edge — hand off to tmux
  if at_tmux_edge(dir) and window_cmd[dir] then
    tmux(window_cmd[dir])
  else
    tmux("select-pane " .. pane_flag[dir] .. "Z")
  end
end

function M.navigate_previous()
  tmux("select-pane -lZ")
end

function M.setup()
  local map = vim.keymap.set
  local opts = { silent = true }

  map("n", "<C-h>", function() M.navigate("h") end, opts)
  map("n", "<C-j>", function() M.navigate("j") end, opts)
  map("n", "<C-k>", function() M.navigate("k") end, opts)
  map("n", "<C-l>", function() M.navigate("l") end, opts)
  map("n", "<C-\\>", function() M.navigate_previous() end, opts)
end

return M

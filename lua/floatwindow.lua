local M = {}

--- @class floating.Opts
--- @field buf integer
--- @field win integer

--- @class window.Opts
--- @field buf integer
--- @field height number?
--- @field width number?
--- @field border string?
--- @field title string?

--- comment
--- @param opts window.Opts
--- @return floating.Opts
M.create_floating_window = function(opts)
  local win_width = vim.api.nvim_win_get_width(0) -- Current window width
  local win_height = vim.api.nvim_win_get_height(0) -- Current window height

  -- Calculate 80% of the current window size
  local float_width = math.floor(win_width * 0.8)
  local float_height = math.floor(win_height * 0.8)

  -- Calculate the position of the floating window
  local row = math.floor((win_height - float_height) / 2)
  local col = math.floor((win_width - float_width) / 2)

  local buf = nil

  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  -- Define the configuration for the floating window
  local win_config = {
    relative = "editor",
    width = opts.width or float_width,
    height = opts.height or float_height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border or "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)

  return { buf = buf, win = win }
end

--- @class state.Floating
--- @field floating floating.Opts

--- @class text.Window.Opts
--- @field state state.Floating
--- @field text string

--- Takes text as argument to create a floating window
--- @param opts text.Window.Opts
M.create_floating_text_window = function(opts)
  if not vim.api.nvim_win_is_valid(opts.state.floating.win) then
    opts.state.floating = M.create_floating_window({ buf = opts.state.floating.buf })
  else
    vim.api.nvim_win_hide(opts.state.floating.win)
  end

  local lines = vim.split(opts.text, "\n")

  -- Clear the buffer first
  vim.api.nvim_buf_set_lines(opts.state.floating.buf, 0, -1, false, {})

  vim.api.nvim_buf_set_lines(opts.state.floating.buf, 0, #lines, false, lines)

  vim.api.nvim_buf_set_keymap(
    opts.state.floating.buf,
    "n",
    "<ESC><ESC>",
    "<Cmd>q<CR>",
    { noremap = true, silent = true }
  )
end

return M

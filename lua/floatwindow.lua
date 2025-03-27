local M = {}

--- @class floating.Opts
--- @field buf integer
--- @field win integer

--- @class window.Opts
--- @field floating floating.Opts
--- @field opts vim.api.keyset.win_config?
--- @field enter boolean|nil

--- Takes options as argument to create a floating window
--- @param opts window.Opts
--- @return floating.Opts
M.create_floating_window = function(opts)
  local win_width = vim.api.nvim_win_get_width(0)   -- Current window width
  local win_height = vim.api.nvim_win_get_height(0) -- Current window height

  -- Calculate 80% of the current window size
  local float_width = math.floor(win_width * 0.8)
  local float_height = math.floor(win_height * 0.8)

  -- Calculate the position of the floating window
  local row = math.floor((win_height - float_height) / 2)
  local col = math.floor((win_width - float_width) / 2)

  local buf = nil

  if vim.api.nvim_buf_is_valid(opts.floating.buf) then
    buf = opts.floating.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  -- Define the configuration for the floating window
  local win_config = {
    relative = "editor",
    width = float_width,
    height = float_height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  }

  local enter = true

  if opts.enter ~= nil then
    enter = opts.enter
  end

  local win = vim.api.nvim_open_win(buf, enter, opts.opts or win_config)

  return { buf = buf, win = win }
end

--- @class state.Floating
--- @field floating floating.Opts

--- @class text.Window.Opts
--- @field state state.Floating
--- @field text string

--- Takes text as argument to create a floating window
--- @param opts text.Window.Opts
--- @deprecated -- Use create_floating_window and set buffer text directly
M.create_floating_text_window = function(opts)
  local floating

  floating = M.create_floating_window({ floating = opts.state.floating })

  local lines = vim.split(opts.text, "\n")

  -- Clear the buffer first
  vim.api.nvim_buf_set_lines(floating.buf, 0, -1, false, {})

  vim.api.nvim_buf_set_lines(floating.buf, 0, #lines, false, lines)

  vim.api.nvim_buf_set_keymap(
    opts.state.floating.buf,
    "n",
    "<ESC><ESC>",
    "<Cmd>q<CR>",
    { noremap = true, silent = true }
  )

  return { buf = floating.buf, win = floating.win }
end

return M

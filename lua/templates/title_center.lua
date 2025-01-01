local floatwindow = require("floatwindow")

local M = {}

M.state = {
  window_style = {},
  restore = {},
  title = "TITLE",
  width = 20,
  height = 10,
}

local foreach_float = function(callback)
  for name, float in pairs(M.state.window_style) do
    callback(name, float)
  end
end

local set_content = function()
  local padding = string.rep(" ", (M.state.window_style.header.opts.width - #M.state.title) / 2)
  local title = padding .. M.state.title

  vim.api.nvim_buf_set_lines(M.state.window_style.header.floating.buf, 0, -1, false, { title })
end

local create_window_config = function()
  local width = vim.o.columns
  local height = vim.o.lines

  M.state.width = M.state.width == 0 and vim.o.columns or M.state.width
  M.state.height = M.state.height == 0 and vim.o.lines or M.state.height

  return {
    header = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        width = string.len(M.state.title),
        height = 1,
        col = math.floor((width * 0.5) / 2) + math.floor(width * 0.2),
        row = math.floor((height * 0.5)) - 0,
        style = "minimal",
        zindex = 3,
        border = "none",
      },
      enter = false,
    },
    main = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        width = math.floor(M.state.width * 0.4),
        height = 1,
        col = math.floor((width * 0.5) / 2) + 1,
        row = math.floor((height * 0.5)) + 1,
        style = "minimal",
        border = { " ", " ", " ", " ", " ", " ", " ", " " },
        zindex = 2,
      },
    },
    background = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        width = math.floor(M.state.width * 0.5),
        height = 3,
        col = math.floor((width * 0.5) / 2),
        row = math.floor((height * 0.5)),
        style = "minimal",
        border = "rounded",
        zindex = 1,
      },
      enter = false,
    },
  }
end

local exit_window = function(restore)
  for option, config in pairs(restore) do
    vim.opt[option] = config.original
  end

  foreach_float(function(_, float)
    pcall(vim.api.nvim_win_close, float.floating.win, true)
  end)
end

local create_remap = function()
  vim.keymap.set("n", "<Esc><Esc>", function()
    vim.api.nvim_win_close(M.state.window_style.main.floating.win, true)
  end, {
    buffer = M.state.window_style.main.floating.buf,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = M.state.window_style.main.floating.buf,
    callback = function()
      exit_window(M.state.restore)
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if
        not vim.api.nvim_win_is_valid(M.state.window_style.main.floating.win)
        or M.state.window_style.main.floating.win == nil
      then
        return
      end

      local updated = create_window_config()

      foreach_float(function(name, float)
        float.opts = updated[name].opts
        vim.api.nvim_win_set_config(float.floating.win, updated[name].opts)
      end)

      set_content()
    end,
  })
end

M.window_setup = function()
  M.state.restore = {
    cmdheight = {
      original = vim.o.cmdheight,
      current = 0,
    },
  }

  for option, config in pairs(M.state.restore) do
    vim.opt[option] = config.training
  end

  M.state.window_style = create_window_config()

  foreach_float(function(_, float)
    float.floating = floatwindow.create_floating_window(float)
  end)

  set_content()

  create_remap()
end

local toggle_title_center = function()
  M.window_setup()
end

vim.api.nvim_create_user_command("Centertest", toggle_title_center, {})

return M

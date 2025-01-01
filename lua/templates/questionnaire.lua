local floatwindow = require("floatwindow")

local M = {}

M.state = {
  window_style = {},
  title = "TITLE",
  footer = "FOOTER",
  restore = {
    cmdheight = {},
  },
  question = "TEMPLATE QUESTION",
  question_height = 15,
  answear = {
    "A) TEMPLATE ANSWEAR 1",
    "B) TEMPLATE ANSWEAR 2",
    "C) TEMPLATE ANSWEAR 3",
    "D) TEMPLATE ANSWEAR 4",
  },
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

  vim.api.nvim_buf_set_lines(M.state.window_style.question.floating.buf, 0, -1, false, { M.state.question })
  vim.api.nvim_buf_set_lines(M.state.window_style.answear.floating.buf, 0, -1, false, M.state.answear)

  vim.api.nvim_buf_set_lines(M.state.window_style.footer.floating.buf, 0, -1, false, { M.footer })
end

local create_window_config = function()
  local width = vim.o.columns
  local height = vim.o.lines

  local header_height = 1
  local footer_height = 1
  local question_height = math.floor((height - header_height - footer_height + M.state.question_height) / 2)
  local answear_height = question_height - 5 - 1 - M.state.question_height

  return {
    background = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 1,
        width = width,
        height = height,
        col = 0,
        row = 0,
        border = "none",
      },
      enter = false,
    },
    header = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 4,
        width = width,
        height = header_height,
        col = 0,
        row = 0,
        border = { " ", " ", " ", " ", " ", " ", " ", " " },
      },
      enter = false,
    },
    question_background = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 2,
        width = width - 18,
        height = question_height,
        col = 6,
        row = 3,
        border = "rounded",
        title = " Question ",
      },
      enter = false,
    },
    question = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 3,
        width = width - 24,
        height = question_height - 2,
        col = 9,
        row = 4,
        border = { " ", " ", " ", " ", " ", " ", " ", " " },
      },
      enter = false,
    },
    answear_background = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 2,
        width = width - 18,
        height = answear_height,
        col = 6,
        row = question_height + 5,
        border = "rounded",
        title = " Answear ",
      },
      enter = false,
    },
    answear = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 3,
        width = width - 24,
        height = answear_height - 2,
        col = 9,
        row = question_height + 6,
        border = { " ", " ", " ", " ", " ", " ", " ", " " },
      },
    },
    footer = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 4,
        width = width,
        height = footer_height,
        col = 0,
        row = height - footer_height,
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

---Takes the buffer and the text that you want to show
---@param buf integer
---@param lines string[]
M.set_text = function(buf, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

local create_remaps = function()
  vim.keymap.set("n", "<ESC><ESC>", function()
    vim.api.nvim_win_close(M.state.window_style.answear.floating.win, true)
  end, {
    buffer = M.state.window_style.answear.floating.buf,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = M.state.window_style.answear.floating.buf,
    callback = function()
      exit_window(M.state.restore)
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if
        not vim.api.nvim_win_is_valid(M.state.window_style.answear.floating.win)
        or M.state.window_style.answear.floating.win == nil
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
      training = 0,
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

  create_remaps()
end

M.toggle_training = function()
  M.window_setup()
end

return M

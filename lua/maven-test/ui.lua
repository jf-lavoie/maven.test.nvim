local M = {}

local config = require("maven-test").config

M.width = math.floor(vim.o.columns * config.floating_window.width)
M.height = math.floor(vim.o.lines * config.floating_window.height)
M.row = math.floor((vim.o.lines - M.height) / 2)
M.col = math.floor((vim.o.columns - M.width) / 2)

M.FloatingWindow = {}
M.FloatingWindow.__index = M.FloatingWindow

function M.FloatingWindow.new(wHeight, wWidth, wRow, wCol, enter, filetype)
	local self = setmetatable({}, M.FloatingWindow)

	local buffer = vim.api.nvim_create_buf(false, true)
	local window = vim.api.nvim_open_win(buffer, enter, {
		relative = "editor",
		width = wWidth,
		height = wHeight,
		row = wRow,
		col = wCol,
		style = "minimal",
		border = config.floating_window.border,
	})

	vim.api.nvim_buf_set_option(buffer, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buffer, "filetype", filetype)

	self.buf = buffer
	self.win = window
	self.height = wHeight
	self.width = wWidth
	return self
end

function M.FloatingWindow:close()
	if vim.api.nvim_win_is_valid(self.win) then
		vim.api.nvim_win_close(self.win, true)
	end
	if vim.api.nvim_buf_is_valid(self.buf) then
		vim.api.nvim_buf_delete(self.buf, { force = true })
	end
end

function M.FloatingWindow:is_active()
	local win_id = vim.api.nvim_get_current_win()

	return win_id == self.win
end

return M

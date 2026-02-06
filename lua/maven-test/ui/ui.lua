local M = {}

local config = require("maven-test").config
local store_arg = require("maven-test.store.arguments")

local CustomArgument = require("maven-test.store.custom_argument")

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
	if vim.api.nvim_buf_is_valid(self.buf) then
		pcall(vim.api.nvim_buf_delete, self.bur, { force = true })
	end
	if vim.api.nvim_win_is_valid(self.win) then
		pcall(vim.api.nvim_win_close, self.win, true)
	end
end

function M.FloatingWindow:is_active()
	local win_id = vim.api.nvim_get_current_win()

	return win_id == self.win
end

function M.show_command_editor(cmd, fctAddToStore, onComplete)
	local bufWin = M.FloatingWindow.new(
		10,
		160,
		math.floor((vim.o.lines - 10) / 2),
		math.floor((vim.o.columns - 160) / 2),
		true,
		"sh"
	)

	local buf = bufWin.buf

	vim.api.nvim_win_set_option(bufWin.win, "winbar", "%#StatusLine#<CR> normal mode: save command | <esc>, <q> Quit")

	vim.keymap.set("n", "<Esc>", function()
		bufWin:close()
		onComplete()
	end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "q", function()
		bufWin:close()
		onComplete()
	end, { buffer = buf, nowait = true })

	vim.keymap.set("n", "<CR>", function()
		local text = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
		bufWin:close()

		local joined_text = table.concat(text, "\n"):match("^%s*(.-)%s*$")
		fctAddToStore(joined_text)

		onComplete()
	end, { buffer = buf, nowait = true })

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		callback = function()
			bufWin:close()
		end,
	})

	local splittedLines = {}
	for line in cmd:gmatch("[^\n]+") do
		table.insert(splittedLines, line)
	end

	vim.api.nvim_buf_set_lines(buf, 0, 1, true, splittedLines)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
end

function M.default_arguments_editor(getArgs, onAddArg, onUpdateArg, onDeleteArg, onComplete)
	local bufWin = M.FloatingWindow.new(
		10,
		160,
		math.floor((vim.o.lines - 10) / 2),
		math.floor((vim.o.columns - 160) / 2),
		true,
		"sh"
	)

	local function update_view()
		vim.api.nvim_buf_set_option(bufWin.buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(bufWin.buf, 0, 1, true, {})

		local splittedLines = {}
		local args = getArgs()
		for _, arg in ipairs(args) do
			local line = "🔴 "
			if arg.active then
				line = "🟢 "
			end
			table.insert(splittedLines, line .. arg.text)
		end

		vim.api.nvim_buf_set_lines(bufWin.buf, 0, 1, true, splittedLines)
		vim.api.nvim_buf_set_option(bufWin.buf, "modifiable", false)
	end

	local function getSelectedArg()
		local index = vim.api.nvim_win_get_cursor(bufWin.win)[1]

		local arg = getArgs()[index]

		return arg
	end

	vim.api.nvim_win_set_option(
		bufWin.win,
		"winbar",
		"%#StatusLine# <space> toggle activation | <a> add | <u> update | <d> delete | <esc>, <q> Quit"
	)

	vim.keymap.set("n", "<Esc>", function()
		bufWin:close()
		onComplete()
	end, { buffer = bufWin.buf, nowait = true })
	vim.keymap.set("n", "q", function()
		bufWin:close()
		onComplete()
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "a", function()
		bufWin:close()
		M.show_command_editor("", function(arg)
			onAddArg(CustomArgument.new(arg, false))
		end, function()
			M.default_arguments_editor(getArgs, onAddArg, onUpdateArg, onDeleteArg, onComplete)
		end)
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "u", function()
		local arg = getSelectedArg()

		bufWin:close()

		M.show_command_editor(arg.text, function(updated)
			if arg.text ~= updated then
				onDeleteArg(arg)
				onAddArg(CustomArgument.new(updated, arg.active))
			end
		end, function()
			M.default_arguments_editor(getArgs, onAddArg, onUpdateArg, onDeleteArg, onComplete)
		end)
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "d", function()
		local arg = getSelectedArg()
		onDeleteArg(arg)
		update_view()
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "<space>", function()
		local arg = getSelectedArg()
		arg:toggle_active()
		onUpdateArg(arg)
		update_view()
	end, { buffer = bufWin.buf, nowait = true })

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = bufWin.buf,
		callback = function()
			bufWin:close()
		end,
	})
	update_view()
end

return M

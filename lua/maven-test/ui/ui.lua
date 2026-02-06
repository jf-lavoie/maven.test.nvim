--- Core UI components for floating windows and editors
--- Provides reusable FloatingWindow class and command editor functions
--- @module 'maven-test.ui.ui'

local M = {}

local config = require("maven-test").config

local CustomArgument = require("maven-test.store.custom_argument").CustomArgument

--- Default window dimensions based on configuration
M.width = math.floor(vim.o.columns * config.floating_window.width)
M.height = math.floor(vim.o.lines * config.floating_window.height)
M.row = math.floor((vim.o.lines - M.height) / 2)
M.col = math.floor((vim.o.columns - M.width) / 2)

--- FloatingWindow class for creating centered floating windows
--- @class FloatingWindow
--- @field buf number Buffer number for the floating window
--- @field win number Window ID for the floating window
--- @field height number Window height in lines
--- @field width number Window width in columns
M.FloatingWindow = {}
M.FloatingWindow.__index = M.FloatingWindow

--- Create a new FloatingWindow instance
--- Creates a scratch buffer and opens it in a floating window
--- @param wHeight number Window height in lines
--- @param wWidth number Window width in columns
--- @param wRow number Row position (distance from top of editor)
--- @param wCol number Column position (distance from left of editor)
--- @param enter boolean Whether to enter the window after creation
--- @param filetype string Filetype to set for the buffer (for syntax highlighting)
--- @return FloatingWindow New FloatingWindow instance
--- @usage
---   local win = FloatingWindow.new(20, 80, 10, 20, true, "sh")
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

--- Close the floating window and delete its buffer
--- Uses pcall to safely handle already-closed windows/buffers
--- @usage
---   win:close()
function M.FloatingWindow:close()
	if vim.api.nvim_buf_is_valid(self.buf) then
		pcall(vim.api.nvim_buf_delete, self.buf, { force = true })
	end
	if vim.api.nvim_win_is_valid(self.win) then
		pcall(vim.api.nvim_win_close, self.win, true)
	end
end

--- Check if this floating window is the currently active window
--- @return boolean True if this window is active, false otherwise
--- @usage
---   if win:is_active() then
---     print("Window is active")
---   end
function M.FloatingWindow:is_active()
	local win_id = vim.api.nvim_get_current_win()

	return win_id == self.win
end

--- Show command editor for editing Maven commands
--- Opens a floating window with the command text that can be edited
--- Starts in insert mode for immediate editing
--- @param cmd string The command text to edit
--- @param fctAddToStore function Callback function to save the edited command
--- @param onComplete function Callback function called when editor is closed
--- @usage
---   show_command_editor("mvn test", function(edited_cmd)
---     store.add("run_all", edited_cmd)
---   end, function()
---     print("Editor closed")
---   end)
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

--- Show custom arguments editor UI
--- Opens a floating window to manage custom Maven arguments
--- Displays arguments with activation status (🟢 active, 🔴 inactive)
--- Supports adding, editing, deleting, and toggling arguments
--- @param getArgs function Function that returns array of CustomArgument objects
--- @param onAddArg function Callback function(arg) to add a new argument
--- @param onUpdateArg function Callback function(arg) to update an argument
--- @param onDeleteArg function Callback function(arg) to delete an argument
--- @param onComplete function Callback function called when editor is closed
--- @usage
---   default_arguments_editor(
---     store_arg.list,
---     store_arg.add,
---     store_arg.update,
---     store_arg.remove,
---     function() print("Closed") end
---   )
function M.default_arguments_editor(getArgs, onAddArg, onUpdateArg, onDeleteArg, onComplete)
	local bufWin = M.FloatingWindow.new(
		10,
		160,
		math.floor((vim.o.lines - 10) / 2),
		math.floor((vim.o.columns - 160) / 2),
		true,
		"sh"
	)

	--- Update the view with current arguments list
	--- Displays arguments with colored status indicators
	--- @private
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

	--- Get the argument at the current cursor position
	--- @return CustomArgument The selected argument
	--- @private
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

	-- Close window keymaps
	vim.keymap.set("n", "<Esc>", function()
		bufWin:close()
		onComplete()
	end, { buffer = bufWin.buf, nowait = true })
	vim.keymap.set("n", "q", function()
		bufWin:close()
		onComplete()
	end, { buffer = bufWin.buf, nowait = true })

	-- Add new argument
	vim.keymap.set("n", "a", function()
		bufWin:close()
		M.show_command_editor("", function(arg)
			onAddArg(CustomArgument.new(arg, false))
		end, function()
			M.default_arguments_editor(getArgs, onAddArg, onUpdateArg, onDeleteArg, onComplete)
		end)
	end, { buffer = bufWin.buf, nowait = true })

	-- Update selected argument
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

	-- Delete selected argument
	vim.keymap.set("n", "d", function()
		local arg = getSelectedArg()
		onDeleteArg(arg)
		update_view()
	end, { buffer = bufWin.buf, nowait = true })

	-- Toggle argument activation
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

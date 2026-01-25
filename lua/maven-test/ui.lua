local M = {}

local config = require("maven-test").config
local width = math.floor(vim.o.columns * config.floating_window.width)
local total_height = math.floor(vim.o.lines * config.floating_window.height)
local height1 = math.floor(total_height / 2)
local height2 = total_height - height1 - 2
local row1 = math.floor((vim.o.lines - total_height) / 2)
local row2 = row1 + height1 + 2
local col = math.floor((vim.o.columns - width) / 2)

local show_command_editor, _show_test_selector

local FullyQualifiedName = {}
FullyQualifiedName.__index = FullyQualifiedName

function FullyQualifiedName.new(text, line)
	local self = setmetatable({}, FullyQualifiedName)
	self.text = text
	self.line = line
	return self
end

local CommandInfo = {}
CommandInfo.__index = CommandInfo

function CommandInfo.new(fullyQualifiedName, commandDetails)
	local self = setmetatable({}, FullyQualifiedName)
	self.fqn = fullyQualifiedName
	self.commands = commandDetails
	return self
end

local CommandDetail = {}
CommandDetail.__index = CommandDetail

function CommandDetail.new(cmd, format)
	local self = setmetatable({}, CommandDetail)
	self.cmd = cmd
	self.format = format
	return self
end

function CommandDetail:toPreviewString()
	-- return self.cmd
	-- return self.cmd:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t"):gsub("\\", "\\\\")
	return self.cmd:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
end

local function create_floating_window(wHeight, wWidth, wRow, wCol, enter)
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, enter, {
		relative = "editor",
		width = wWidth,
		height = wHeight,
		row = wRow,
		col = wCol,
		style = "minimal",
		border = config.floating_window.border,
	})

	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "filetype", "maven-test")

	return buf, win
end

local function get_command(fqnCommands, actionsWin, commandsWin)
	local line = vim.api.nvim_win_get_cursor(actionsWin.win)[1]
	local fqn = fqnCommands[line]

	local commands = fqn.commands

	local commandIndex = vim.api.nvim_win_get_cursor(commandsWin.win)[1]

	local cmd = commands[commandIndex]

	return cmd
end

local function delete_command_from_store(fqnCommands, actionsWin, commandsWin, fctDeleteFromStore)
	local line = vim.api.nvim_win_get_cursor(actionsWin.win)[1]
	local fqn = fqnCommands[line]

	local commands = fqn.commands

	if #commands == 1 then
		vim.notify("Only 1 command left. Will not delete.", vim.log.levels.WARN)
		return
	end

	local commandIndex = vim.api.nvim_win_get_cursor(commandsWin.win)[1]

	local cmd = commands[commandIndex]

	if not cmd then
		vim.notify("No command selected to delete", vim.log.levels.ERROR)
		return
	end

	fctDeleteFromStore(cmd.format)
end

local function create_action_window(enter)
	local buf, win = create_floating_window(height1, width, row1, col, enter)
	local actionWin = {
		buf = buf,
		win = win,
		height = height1,
		width = width,
	}
	return actionWin
end
local function create_commands_window(enter)
	local buf, win = create_floating_window(height2, width, row2, col, enter)
	local commandsWin = {
		buf = buf,
		win = win,
		height = height2,
		width = width,
	}
	return commandsWin
end

local function close_popup(theWin)
	if theWin and theWin.win and vim.api.nvim_win_is_valid(theWin.win) then
		vim.api.nvim_win_close(theWin.win, true)
		-- vim.api.nvim_buf_delete(theWin.buf, { force = true })
	end
end

local function onBufLeave(actionsWin, commandsWin)
	return function()
		local win_id = vim.api.nvim_get_current_win()
		if win_id == actionsWin.win or win_id == commandsWin.win then
			return false
		end

		close_popup(actionsWin)
		close_popup(commandsWin)
		return true
	end
end

local function get_package_name()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)

	for _, line in ipairs(lines) do
		local package = line:match("^package%s+([%w%.]+)")
		if package then
			return package
		end
	end

	return nil
end

local function get_maven_command(command, test)
	return string.format(command, test)
end

local function update_preview(actionsWin, commandsWin, fqnCommands)
	local line = vim.api.nvim_win_get_cursor(actionsWin.win)[1]

	local cmds = {}

	if line <= #fqnCommands then
		local fqn = fqnCommands[line]

		for index, value in ipairs(fqn.commands) do
			local t = value:toPreviewString()
			table.insert(cmds, index, t)
		end
	end

	local content_lines = #cmds
	local available_height = commandsWin.height - 1 -- -1 for footer
	for _ = content_lines + 1, available_height do
		table.insert(cmds, "")
	end

	table.insert(cmds, "<CR>, <space> Run command | <m> modify command | <d> delete command | q: Quit")

	local preview_lines = cmds
	vim.api.nvim_buf_set_option(commandsWin.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(commandsWin.buf, 0, -1, false, preview_lines)
	vim.api.nvim_buf_set_option(commandsWin.buf, "modifiable", false)
end

local function show_fully_qualified_names(theWin, fqnCommandsInfo)
	local lines = {}

	for _, fqn in ipairs(fqnCommandsInfo) do
		table.insert(lines, fqn.fqn.text .. " (line " .. fqn.fqn.line .. ")")
	end

	local content_lines = #lines
	local available_height = theWin.height - 1 -- -1 for footer
	for _ = content_lines + 1, available_height do
		table.insert(lines, "")
	end

	table.insert(lines, "<CR> Run test | <space> Select command | q: Quit")

	vim.api.nvim_buf_set_lines(theWin.buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(theWin.buf, "modifiable", false)
end

--- Creates a list of test actions from package, class, and test methods
--- @param package_name string The Java package name
--- @param class table Table with 'name' and 'line' fields for the test class
--- @param testMethods table[] Array of tables, each with 'name' and 'line' fields for test methods
--- @return table[] Array of Action objects containing fully qualified test identifiers
local function create_fully_qualified_names(package_name, class, testMethods)
	local names = {}

	table.insert(names, FullyQualifiedName.new(package_name .. "." .. class.name, class.line))

	for _, test in ipairs(testMethods) do
		table.insert(names, FullyQualifiedName.new(package_name .. "." .. class.name .. "#" .. test.name, test.line))
	end
	return names
end

local function create_fully_qualidfied_commands(fullyQualifiedNames, commands)
	local fqnCommands = {}
	for _, fqn in ipairs(fullyQualifiedNames) do
		local cmds = {}
		for _, cmdFormat in ipairs(commands) do
			table.insert(cmds, CommandDetail.new(get_maven_command(cmdFormat, fqn.text), cmdFormat))
		end

		table.insert(fqnCommands, CommandInfo.new(fqn, cmds))
	end
	return fqnCommands
end

show_command_editor = function(cmd, getCommands, fctDeleteFromStore, fctAddToStore)
	local buf, win =
		create_floating_window(10, 160, math.floor((vim.o.lines - 10) / 2), math.floor((vim.o.columns - 160) / 2), true)

	local bufWin = {
		buf = buf,
		win = win,
	}

	vim.keymap.set("n", "<Esc>", function()
		close_popup(bufWin)
	end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "q", function()
		close_popup(bufWin)
	end, { buffer = buf, nowait = true })

	vim.keymap.set("n", "<CR>", function()
		local text = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
		close_popup(bufWin)

		local joined_text = table.concat(text, "\n"):match("^%s*(.-)%s*$")
		fctAddToStore(joined_text)

		_show_test_selector(getCommands, fctDeleteFromStore, fctAddToStore)
	end, { buffer = buf, nowait = true })

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		callback = function()
			close_popup(bufWin)
		end,
	})

	local splittedLines = {}
	for line in cmd.format:gmatch("[^\n]+") do
		table.insert(splittedLines, line)
	end

	vim.api.nvim_buf_set_lines(buf, 0, 1, true, splittedLines)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
end

_show_test_selector = function(getCommands, fctDeleteFromStore, fctAddToStore)
	local parser = require("maven-test.parser")
	local runner = require("maven-test.runner")

	local testMethods = parser.get_test_methods()
	local class = parser.get_test_class()
	local package_name = get_package_name()

	if #testMethods == 0 then
		vim.notify("No test methods found in current file", vim.log.levels.WARN)
		return
	end

	if not class or not package_name then
		vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
		return
	end

	local fullyQualifiedNames = create_fully_qualified_names(package_name, class, testMethods)

	local commands = getCommands()

	local fqnCommands = create_fully_qualidfied_commands(fullyQualifiedNames, commands)

	local actionsWin = create_action_window(true)
	local commandsWin = create_commands_window(false)

	show_fully_qualified_names(actionsWin, fqnCommands)

	local function on_cursor_move()
		update_preview(actionsWin, commandsWin, fqnCommands)
	end

	local function on_select()
		local cmd = get_command(fqnCommands, actionsWin, commandsWin)
		if not cmd then
			vim.notify("No command selected to run", vim.log.levels.ERROR)
			return
		end

		close_popup(actionsWin)
		close_popup(commandsWin)
		runner.run_maven_test(cmd.cmd)
	end

	vim.keymap.set("n", "<CR>", on_select, { buffer = actionsWin.buf, nowait = true })
	vim.keymap.set("n", "<space>", function()
		vim.api.nvim_set_current_win(commandsWin.win)
		vim.api.nvim_win_set_cursor(commandsWin.win, { 1, 0 })
	end, { buffer = actionsWin.buf, nowait = true })

	vim.keymap.set("n", "q", function()
		close_popup(actionsWin)
		close_popup(commandsWin)
	end, { buffer = actionsWin.buf, nowait = true })

	vim.keymap.set("n", "<Esc>", function()
		close_popup(actionsWin)
		close_popup(commandsWin)
	end, { buffer = actionsWin.buf, nowait = true })

	vim.keymap.set("n", "q", function()
		close_popup(actionsWin)
		close_popup(commandsWin)
	end, { buffer = commandsWin.buf, nowait = true })

	vim.keymap.set("n", "<Esc>", function()
		close_popup(actionsWin)
		close_popup(commandsWin)
	end, { buffer = commandsWin.buf, nowait = true })

	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = actionsWin.buf,
		callback = on_cursor_move,
	})

	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = actionsWin.buf,
		callback = on_cursor_move,
	})

	vim.api.nvim_create_autocmd("WinEnter", {
		-- buffer = actionsWin.buf,
		group = vim.api.nvim_create_augroup("MavenTestUIWinEnter", { clear = true }),
		callback = function()
			if onBufLeave(actionsWin, commandsWin)() then
				vim.api.nvim_del_augroup_by_name("MavenTestUIWinEnter")
			end
		end,
	})

	vim.keymap.set("n", "<CR>", on_select, { buffer = commandsWin.buf, nowait = true })

	vim.keymap.set("n", "<space>", on_select, { buffer = commandsWin.buf, nowait = true })

	vim.api.nvim_win_set_cursor(actionsWin.win, { 1, 0 })
	update_preview(actionsWin, commandsWin, fqnCommands)

	vim.keymap.set("n", "m", function()
		local cmd = get_command(fqnCommands, actionsWin, commandsWin)

		if not cmd then
			vim.notify("No command selected to modify", vim.log.levels.ERROR)
			return
		end

		close_popup(actionsWin)
		close_popup(commandsWin)

		show_command_editor(cmd, getCommands, fctDeleteFromStore, fctAddToStore)
	end, { buffer = commandsWin.buf, nowait = true })

	vim.keymap.set("n", "d", function()
		delete_command_from_store(fqnCommands, actionsWin, commandsWin, fctDeleteFromStore)
		fqnCommands = create_fully_qualidfied_commands(fullyQualifiedNames, commands)
		update_preview(actionsWin, commandsWin, fqnCommands)
	end, { buffer = commandsWin.buf, nowait = true })
end

function M.show_test_selector(getCommands, fctDeleteFromStore, fctAddToStore)
	_show_test_selector(getCommands, fctDeleteFromStore, fctAddToStore)
end

return M

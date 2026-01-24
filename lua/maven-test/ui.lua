local M = {}

local config = require("maven-test").config
local width = math.floor(vim.o.columns * config.floating_window.width)
local total_height = math.floor(vim.o.lines * config.floating_window.height)
local height1 = math.floor(total_height / 2)
local height2 = total_height - height1 - 2
local row1 = math.floor((vim.o.lines - total_height) / 2)
local row2 = row1 + height1 + 2
local col = math.floor((vim.o.columns - width) / 2)

local function create_floating_window(wHeight, wWidth, wRow, wCol, enter)
	-- Top window (test selector)
	local buf1 = vim.api.nvim_create_buf(false, true)
	local win1 = vim.api.nvim_open_win(buf1, enter, {
		relative = "editor",
		width = wWidth,
		height = wHeight,
		row = wRow,
		col = wCol,
		style = "minimal",
		border = config.floating_window.border,
	})

	vim.api.nvim_buf_set_option(buf1, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf1, "filetype", "maven-test")

	return buf1, win1
end

local function create_action_window(enter)
	local buf, win = create_floating_window(height1, width, row1, col, enter)
	local actionWin = {
		buf = buf,
		win = win,
	}
	return actionWin
end
local function create_commands_window(enter)
	local buf, win = create_floating_window(height2, width, row2, col, enter)
	local commandsWin = {
		buf = buf,
		win = win,
	}
	return commandsWin
end

local function close_popup(theWin)
	if theWin and theWin.win and vim.api.nvim_win_is_valid(theWin.win) then
		vim.api.nvim_win_close(theWin.win, true)
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

local function update_preview(actionsWin, commandsWin, actions, commands)
	local line = vim.api.nvim_win_get_cursor(actionsWin.win)[1]
	local action = actions[line]

	local cmds = {}
	for index, value in ipairs(commands) do
		table.insert(cmds, index, get_maven_command(value, action.text))
	end

	local preview_lines = cmds
	vim.api.nvim_buf_set_option(commandsWin.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(commandsWin.buf, 0, -1, false, preview_lines)
	vim.api.nvim_buf_set_option(commandsWin.buf, "modifiable", false)
end

local function show_actions(theWin, actions)
	local lines = {}

	for _, action in ipairs(actions) do
		table.insert(lines, action.text .. " (line " .. action.line .. ")")
	end

	vim.api.nvim_buf_set_lines(theWin.buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(theWin.buf, "modifiable", false)
end

local Actions = {}
Actions.__index = Actions

function Actions.new(text, line)
	local self = setmetatable({}, Actions)
	self.text = text
	self.line = line
	return self
end

--- Creates a list of test actions from package, class, and test methods
--- @param package_name string The Java package name
--- @param class table Table with 'name' and 'line' fields for the test class
--- @param tests table[] Array of tables, each with 'name' and 'line' fields for test methods
--- @return table[] Array of Action objects containing fully qualified test identifiers
local function create_actions(package_name, class, tests)
	local actions = {}

	table.insert(actions, Actions.new(package_name .. "." .. class.name, class.line))

	for _, test in ipairs(tests) do
		table.insert(actions, Actions.new(package_name .. "." .. class.name .. "#" .. test.name, test.line))
	end
	return actions
end

function M.show_test_selector(commands)
	local parser = require("maven-test.parser")
	local runner = require("maven-test.runner")

	local tests = parser.get_test_methods()
	local class = parser.get_test_class()
	local package_name = get_package_name()

	if #tests == 0 then
		vim.notify("No test methods found in current file", vim.log.levels.WARN)
		return
	end

	if not class or not package_name then
		vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
		return
	end

	local possibleActions = create_actions(package_name, class, tests)

	local actionsWin = create_action_window(true)
	local commandsWin = create_commands_window(false)

	show_actions(actionsWin, possibleActions)

	local function on_cursor_move()
		update_preview(actionsWin, commandsWin, possibleActions, commands)
	end

	local function on_select()
		local line = vim.api.nvim_win_get_cursor(actionsWin.win)[1]
		local action = possibleActions[line]

		local commandLine = vim.api.nvim_win_get_cursor(commandsWin.win)[1]
		if not action then
			vim.notify("No action selected", vim.log.levels.ERROR)
			return
		end

		close_popup(actionsWin)
		close_popup(commandsWin)
		runner.run_maven_test(get_maven_command(commands[commandLine], action.text))
	end

	vim.keymap.set("n", "<CR>", on_select, { buffer = actionsWin.buf, nowait = true })

	vim.keymap.set("n", "q", function()
		close_popup(actionsWin)
		close_popup(commandsWin)
	end, { buffer = actionsWin.buf, nowait = true })

	vim.keymap.set("n", "<Esc>", function()
		close_popup(actionsWin)
		close_popup(commandsWin)
	end, { buffer = actionsWin.buf, nowait = true })

	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = actionsWin.buf,
		callback = on_cursor_move,
	})

	vim.api.nvim_win_set_cursor(actionsWin.win, { class and 3 or 3, 0 })
	update_preview(actionsWin, commandsWin, possibleActions, commands)
end

return M

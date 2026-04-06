--- Test selector UI with two-pane layout
--- Top pane displays test actions (class and methods)
--- Bottom pane shows command preview with active arguments
--- @module 'maven-test.tests.ui'

local M = {}

local ui = require("maven-test.ui.ui")

--- Window dimensions for two-pane layout
local width = ui.width
local total_height = ui.height
local height1 = math.floor(total_height / 2)
local height2 = total_height - height1 - 2
local row1 = ui.row
local row2 = row1 + height1 + 2
local col = ui.col

--- Forward declarations for circular dependencies
local show_command_editor, _show_test_selector

--- Fully qualified name class
--- Represents a test identifier with its line number
--- @class FullyQualifiedName
--- @field package_name string The Java package name
--- @field class string The class name
--- @field test_name string? The test method or field name (nil for class-level tests)
--- @field line number The line number where the test is defined
--- @field is_current boolean Whether this test is the current one under the cursor
local FullyQualifiedName = {}
FullyQualifiedName.__index = FullyQualifiedName

--- Creates a new FullyQualifiedName instance
--- @param package_name string The Java package name (e.g., "com.example")
--- @param class string The class name
--- @param test_name string? The test method or field name (nil for class-level tests)
--- @param line number The line number where the test is defined
--- @param is_current boolean Whether this test is at the current cursor position
--- @return FullyQualifiedName
function FullyQualifiedName.new(package_name, class, test_name, line, is_current)
	local self = setmetatable({}, FullyQualifiedName)
	self.package_name = package_name
	self.class = class
	self.test_name = test_name
	self.line = line
	self.is_current = is_current
	return self
end

--- Generates the fully qualified name text for the test
--- Returns either "package.Class#method" for test methods or "package.Class" for class-level tests
--- @return string The fully qualified test name in Maven format
function FullyQualifiedName:text()
	if self.test_name then
		return self.package_name .. "." .. self.class .. "#" .. self.test_name
	else
		return self.package_name .. "." .. self.class
	end
end

--- Checks if this represents a class-level test
--- Returns true if test_name is nil (indicating a class-level test action)
--- @return boolean True if this is a class-level test, false if it's a method-level test
function FullyQualifiedName:isClass()
	return self.test_name == nil
end

--- Converts the test identifier to a human-readable string
--- Combines the fully qualified name with its line number
--- @return string The test identifier in format "package.Class#method (line N)"
function FullyQualifiedName:toString()
	return self:text() .. " (line " .. self.line .. ")"
end

--- Fully qualified command class
--- Links a test identifier (FullyQualifiedName) with its associated formatted Maven commands
--- @class FullyQualifiedCommand
--- @field fqn FullyQualifiedName The test identifier
--- @field formattedCommands FormattedCommand[] Array of formatted Maven commands for this test
local FullyQualifiedCommand = {}
FullyQualifiedCommand.__index = FullyQualifiedCommand

--- Creates a new FullyQualifiedCommand
--- @param fullyQualifiedName FullyQualifiedName The test identifier
--- @param formattedCommands FormattedCommand[] Array of formatted commands
--- @return FullyQualifiedCommand
function FullyQualifiedCommand.new(fullyQualifiedName, formattedCommands)
	local self = setmetatable({}, FullyQualifiedCommand)
	self.fqn = fullyQualifiedName
	self.formattedCommands = formattedCommands
	return self
end

--- Checks if this command is for a class-level test
--- Delegates to the underlying FullyQualifiedName's isClass method
--- @return boolean True if this is a class-level test, false if it's a method-level test
function FullyQualifiedCommand:isClass()
	return self.fqn:isClass()
end

--- Formatted command class
--- Represents a Maven command that has been formatted with test-specific values
--- @class FormattedCommand
--- @field cmd string The fully formatted Maven command ready to execute
--- @field format string The original command template before substitution
--- @field fctAddToStore function Callback function(cmd) to add this command to the store when modified
--- @field fctDeleteFromStore function Callback function(cmd) to add this command to the store when modified
local FormattedCommand = {}
FormattedCommand.__index = FormattedCommand

--- Creates a new FormattedCommand
--- @param cmd string The formatted Maven command
--- @param format string The command template
--- @param fctAddToStore function Callback function(cmd) to add this command to the store when modified
--- @param fctDeleteFromStore function Callback function(cmd) to delete this command from the store when modified
--- @return FormattedCommand
function FormattedCommand.new(cmd, format, fctAddToStore, fctDeleteFromStore)
	local self = setmetatable({}, FormattedCommand)
	self.cmd = cmd
	self.format = format
	self.fctAddToStore = fctAddToStore
	self.fctDeleteFromStore = fctDeleteFromStore
	return self
end

--- Converts command to preview string with escaped special characters
--- Escapes newlines, carriage returns, and tabs for display in UI
--- @return string The sanitized command for display
function FormattedCommand:toPreviewString()
	local str, _ = self.cmd:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
	return str
end

--- Gets the selected command from the UI based on cursor position
--- Returns both the FullyQualifiedCommand and the specific FormattedCommand selected
--- @param fqnCommands FullyQualifiedCommand[] Array of fully qualified commands
--- @param actionsWin FloatingWindow The actions window
--- @param commandsWin FloatingWindow The commands window
--- @return FullyQualifiedCommand|nil, FormattedCommand|nil The selected commands or nil
--- @private
local function get_command(fqnCommands, actionsWin, commandsWin)
	local line = vim.api.nvim_win_get_cursor(actionsWin.win)[1]
	local fullyQualifiedCommand = fqnCommands[line]

	local formattedCommands = fullyQualifiedCommand.formattedCommands

	local commandIndex = vim.api.nvim_win_get_cursor(commandsWin.win)[1]

	local formattedCommand = formattedCommands[commandIndex]

	return fullyQualifiedCommand, formattedCommand
end

--- Deletes a command from the store
--- Prevents deletion if only one command remains
--- @param fqnCommands FullyQualifiedCommand[] Array of fully qualified commands
--- @param actionsWin FloatingWindow The actions window
--- @param commandsWin FloatingWindow The commands window
--- @param fctDeleteFromStore function Callback to delete from store
--- @private
local function delete_command_from_store(fqnCommands, actionsWin, commandsWin)
	local fullyQualifiedCommand, formattedCommand = get_command(fqnCommands, actionsWin, commandsWin)

	if fullyQualifiedCommand == nil then
		vim.notify("No command selected to delete", vim.log.levels.ERROR)
		return
	end

	local commands = fullyQualifiedCommand.formattedCommands

	if #commands == 1 then
		vim.notify("Only 1 command left. Will not delete.", vim.log.levels.WARN)
		return
	end

	if not formattedCommand then
		vim.notify("No command selected to delete", vim.log.levels.ERROR)
		return
	end

	formattedCommand.fctDeleteFromStore(formattedCommand.format)
end

--- Create the top floating window for test actions
--- @param enter boolean Whether to enter the window
--- @return FloatingWindow
--- @private
local function create_action_window(enter)
	local actionWin = ui.FloatingWindow.new(height1, width, row1, col, enter, "java")
	return actionWin
end

--- Create the bottom floating window for command preview
--- @param enter boolean Whether to enter the window
--- @return FloatingWindow
--- @private
local function create_commands_window(enter)
	local commandsWin = ui.FloatingWindow.new(height2, width, row2, col, enter, "sh")
	return commandsWin
end

--- Handle buffer leave event to close both windows
--- @param actionsWin FloatingWindow The actions window
--- @param commandsWin FloatingWindow The commands window
--- @return boolean True if windows were closed, false otherwise
--- @private
local function onBufLeave(actionsWin, commandsWin)
	if actionsWin:is_active() or commandsWin:is_active() then
		return false
	end

	actionsWin:close()
	commandsWin:close()

	return true
end

--- Formats a Maven command with template values
--- @param command string The command template with placeholders
--- @param templateValues table The values to substitute into the template (package, class, method)
--- @return string The formatted Maven command
--- @private
local function get_maven_command(command, templateValues)
	return require("maven-test.template").template(command, templateValues)
end

--- Updates the command preview pane based on cursor position
--- Shows commands for the currently selected action with active custom arguments appended
--- Retrieves commands for the selected line and renders them with active arguments
--- @param actionsWin FloatingWindow The actions window (top pane)
--- @param commandsWin FloatingWindow The commands preview window (bottom pane)
--- @param fqnCommands FullyQualifiedCommand[] Array of fully qualified commands linking tests to commands
--- @param argumentsStore KeyValueStore The store containing custom Maven arguments
--- @private
local function update_preview(actionsWin, commandsWin, fqnCommands, argumentsStore)
	local line = vim.api.nvim_win_get_cursor(actionsWin.win)[1]

	local cmds = {}

	if line <= #fqnCommands then
		local fqn = fqnCommands[line]

		for index, value in ipairs(fqn.formattedCommands) do
			local t = value:toPreviewString()

			-- Append active custom arguments to preview
			for _, arg in ipairs(argumentsStore:list()) do
				if arg.active then
					t = arg:append_to_command(t)
				end
			end

			table.insert(cmds, index, t)
		end
	end

	local preview_lines = cmds
	vim.api.nvim_buf_set_option(commandsWin.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(commandsWin.buf, 0, -1, false, preview_lines)
	vim.api.nvim_buf_set_option(commandsWin.buf, "modifiable", false)

	vim.api.nvim_win_set_option(
		commandsWin.win,
		"winbar",
		"%#StatusLine#<CR>, <space> Run command | <m> modify command | <d> delete command | <q> Quit"
	)
end

--- Displays fully qualified names in the actions window
--- @param theWin FloatingWindow The window to update
--- @param fqnCommandsInfo FullyQualifiedCommand[] Array of fully qualified commands
--- @private
local function show_fully_qualified_names(theWin, fqnCommandsInfo)
	local lines = {}

	for _, fqn in ipairs(fqnCommandsInfo) do
		table.insert(lines, fqn.fqn:text() .. " // line " .. fqn.fqn.line)
	end

	vim.api.nvim_buf_set_option(theWin.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(theWin.buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(theWin.buf, "modifiable", false)

	vim.api.nvim_win_set_option(
		theWin.win,
		"winbar",
		"%#StatusLine#<CR> Run command | <space> Select command | <esc>, <q> Quit"
	)
end

--- Create fully qualified test names from package, class, and methods
--- First entry is the test class, followed by individual test methods
--- @param package_name string The Java package name
--- @param class table Table with 'name', 'is_current' and 'line' fields for the test class
--- @param testMethods table[] Array of tables, each with 'name' and 'line' fields
--- @return FullyQualifiedName[] Array of fully qualified name objects
--- @private
local function create_fully_qualified_names(package_name, class, testMethods)
	local names = {}

	table.insert(names, FullyQualifiedName.new(package_name, class.name, nil, class.line, false))

	for _, test in ipairs(testMethods) do
		table.insert(names, FullyQualifiedName.new(package_name, class.name, test.name, test.line, test.is_current))
	end
	return names
end

--- Creates command info objects by combining FQNs with command templates
--- Moves the current test (under cursor) to the top of the list
--- Expands command templates with test-specific values (package, class, method)
--- @param fullyQualifiedNames FullyQualifiedName[] Array of test identifiers
--- @param testMethodCommands string[] Array of command templates for test methods
--- @param testClassCommands string[] Array of command templates for test classes
--- @param fctAddToMethodStore function Callback to add method commands to store
--- @param fctAddToClassStore function Callback to add class commands to store
--- @param fctDeleteFromMethodStore function Callback to delete method commands from store
--- @param fctDeleteFromClassStore function Callback to delete class commands from store
--- @return FullyQualifiedCommand[] Array of fully qualified commands linking each test to its commands
--- @private
local function create_fully_qualidfied_commands(
	fullyQualifiedNames,
	testMethodCommands,
	testClassCommands,
	fctAddToMethodStore,
	fctAddToClassStore,
	fctDeleteFromMethodStore,
	fctDeleteFromClassStore
)
	local fqnCommands = {}

	local localFullyQualifiedNames = fullyQualifiedNames

	for i, fqn in ipairs(localFullyQualifiedNames) do
		if fqn.is_current then
			-- Move current test to the top of the list
			table.remove(localFullyQualifiedNames, i)
			table.insert(localFullyQualifiedNames, 1, fqn)
			break
		end
	end

	for _, fqn in ipairs(localFullyQualifiedNames) do
		local formattedCmds = {}

		if fqn:isClass() then
			for _, cmdFormat in ipairs(testClassCommands) do
				local templateValues = {
					package = fqn.package_name,
					class = fqn.class,
					method = fqn.test_name,
				}

				local mavenCommand = get_maven_command(cmdFormat, templateValues)

				table.insert(
					formattedCmds,
					FormattedCommand.new(mavenCommand, cmdFormat, fctAddToClassStore, fctDeleteFromClassStore)
				)
			end
		else
			for _, cmdFormat in ipairs(testMethodCommands) do
				local templateValues = {
					package = fqn.package_name,
					class = fqn.class,
					method = fqn.test_name,
				}

				local mavenCommand = get_maven_command(cmdFormat, templateValues)

				table.insert(
					formattedCmds,
					FormattedCommand.new(mavenCommand, cmdFormat, fctAddToMethodStore, fctDeleteFromMethodStore)
				)
			end
		end

		table.insert(fqnCommands, FullyQualifiedCommand.new(fqn, formattedCmds))
	end
	return fqnCommands
end

--- Shows command editor and returns to test selector on completion
--- Opens a floating window to edit the command text, then reopens the test selector
--- @param formattedCommand FormattedCommand The command to edit
--- @param getTestMethodCommands function Function that returns command templates for test methods
--- @param getTestClassCommands function Function that returns command templates for test classes
--- @param fctDeleteFromMethodStore function Callback to delete method commands from store
--- @param fctAddToMethodStore function Callback to add method commands to store
--- @param fctDeleteFromClassStore function Callback to delete class commands from store
--- @param fctAddToClassStore function Callback to add class commands to store
--- @param argumentsStore KeyValueStore Store of custom Maven arguments
--- @private
show_command_editor = function(
	formattedCommand,
	getTestMethodCommands,
	getTestClassCommands,
	fctDeleteFromMethodStore,
	fctAddToMethodStore,
	fctDeleteFromClassStore,
	fctAddToClassStore,
	argumentsStore
)
	vim.print("jf-debug-> 'formattedCommand': " .. vim.inspect(formattedCommand))
	ui.show_command_editor(formattedCommand.format, formattedCommand.fctAddToStore, function()
		_show_test_selector(
			getTestMethodCommands,
			getTestClassCommands,
			fctDeleteFromMethodStore,
			fctAddToMethodStore,
			fctDeleteFromClassStore,
			fctAddToClassStore,
			argumentsStore
		)
	end)
end

--- Internal implementation of test selector UI
--- Parses the current Java file for tests and creates a two-pane layout
--- Top pane shows test methods and class-level actions
--- Bottom pane shows preview of Maven commands with custom arguments
--- @param getTestMethodCommands function Function that returns command templates for test methods
--- @param getTestClassCommands function Function that returns command templates for test classes
--- @param fctDeleteFromMethodStore function Callback to delete method commands from the store
--- @param fctAddToMethodStore function Callback to add method commands to the store
--- @param fctDeleteFromClassStore function Callback to delete class commands from the store
--- @param fctAddToClassStore function Callback to add class commands to the store
--- @param argumentsStore KeyValueStore The store containing custom Maven arguments
--- @private
_show_test_selector = function(
	getTestMethodCommands,
	getTestClassCommands,
	fctDeleteFromMethodStore,
	fctAddToMethodStore,
	fctDeleteFromClassStore,
	fctAddToClassStore,
	argumentsStore
)
	local parser = require("maven-test.tests.parsers.java")
	local runner = require("maven-test.runner.runner")

	local testMethods = parser.get_test_methods()
	local class = parser.get_test_class()
	local package_name = parser.get_package_name()

	if #testMethods == 0 then
		vim.notify("No test methods found in current file", vim.log.levels.WARN)
		return
	end

	if not class or not package_name then
		vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
		return
	end

	local fullyQualifiedNames = create_fully_qualified_names(package_name, class, testMethods)

	local testMethodCommands = getTestMethodCommands()
	local testClassCommands = getTestClassCommands()

	local fqnCommands = create_fully_qualidfied_commands(
		fullyQualifiedNames,
		testMethodCommands,
		testClassCommands,
		fctAddToMethodStore,
		fctAddToClassStore,
		fctDeleteFromMethodStore,
		fctDeleteFromClassStore
	)

	local actionsWin = create_action_window(true)
	local commandsWin = create_commands_window(false)

	--- Update preview when cursor moves in actions window
	--- @private
	local function on_cursor_move()
		update_preview(actionsWin, commandsWin, fqnCommands, argumentsStore)
	end

	--- Execute the selected command
	--- @private
	local function on_select()
		local _, formattedCommand = get_command(fqnCommands, actionsWin, commandsWin)
		if not formattedCommand then
			vim.notify("No command selected to run", vim.log.levels.ERROR)
			return
		end

		actionsWin:close()
		commandsWin:close()

		runner.run_command(formattedCommand.cmd, argumentsStore)
	end

	-- Actions window keymaps
	vim.keymap.set("n", "<CR>", on_select, { buffer = actionsWin.buf, nowait = true })
	vim.keymap.set("n", "<space>", function()
		vim.api.nvim_set_current_win(commandsWin.win)
		vim.api.nvim_win_set_cursor(commandsWin.win, { 1, 0 })
	end, { buffer = actionsWin.buf, nowait = true })

	vim.keymap.set("n", "q", function()
		actionsWin:close()
		commandsWin:close()
	end, { buffer = actionsWin.buf, nowait = true })

	vim.keymap.set("n", "<Esc>", function()
		actionsWin:close()
		commandsWin:close()
	end, { buffer = actionsWin.buf, nowait = true })

	-- Commands window keymaps
	vim.keymap.set("n", "q", function()
		actionsWin:close()
		commandsWin:close()
	end, { buffer = commandsWin.buf, nowait = true })

	vim.keymap.set("n", "<Esc>", function()
		actionsWin:close()
		commandsWin:close()
	end, { buffer = commandsWin.buf, nowait = true })

	-- Auto-update preview on cursor movement
	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = actionsWin.buf,
		callback = on_cursor_move,
	})

	-- Auto-close when switching to other windows
	vim.api.nvim_create_autocmd("WinEnter", {
		group = vim.api.nvim_create_augroup("MavenTestUIWinEnter", { clear = true }),
		callback = function()
			if onBufLeave(actionsWin, commandsWin) then
				vim.api.nvim_del_augroup_by_name("MavenTestUIWinEnter")
			end
		end,
	})

	-- Commands window specific keymaps
	vim.keymap.set("n", "<CR>", on_select, { buffer = commandsWin.buf, nowait = true })

	vim.keymap.set("n", "<space>", on_select, { buffer = commandsWin.buf, nowait = true })

	show_fully_qualified_names(actionsWin, fqnCommands)
	vim.api.nvim_win_set_cursor(actionsWin.win, { 1, 0 })
	update_preview(actionsWin, commandsWin, fqnCommands, argumentsStore)

	-- Edit command keymap
	vim.keymap.set("n", "m", function()
		local _, formattedCommand = get_command(fqnCommands, actionsWin, commandsWin)

		if not formattedCommand then
			vim.notify("No command selected to modify", vim.log.levels.ERROR)
			return
		end

		actionsWin:close()
		commandsWin:close()

		show_command_editor(
			formattedCommand,
			getTestMethodCommands,
			getTestClassCommands,
			fctDeleteFromMethodStore,
			fctAddToMethodStore,
			fctDeleteFromClassStore,
			fctAddToClassStore,
			argumentsStore
		)
	end, { buffer = commandsWin.buf, nowait = true })

	-- Delete command keymap
	vim.keymap.set("n", "d", function()
		delete_command_from_store(fqnCommands, actionsWin, commandsWin)
		fqnCommands = create_fully_qualidfied_commands(
			fullyQualifiedNames,
			testMethodCommands,
			testClassCommands,
			fctAddToMethodStore,
			fctAddToClassStore,
			fctDeleteFromMethodStore,
			fctDeleteFromClassStore
		)
		update_preview(actionsWin, commandsWin, fqnCommands, argumentsStore)
	end, { buffer = commandsWin.buf, nowait = true })
end

--- Shows the test selector UI
--- Displays a two-pane floating window for selecting and running tests
--- Top pane: List of test methods and class-level test actions
--- Bottom pane: Preview of Maven commands to be executed
--- @param getTestMethodCommands function Function that returns command templates for test methods
--- @param getTestClassCommands function Function that returns command templates for test classes
--- @param fctDeleteFromMethodStore function Callback to delete method commands from the store
--- @param fctAddToMethodStore function Callback to add method commands to the store
--- @param fctDeleteFromClassStore function Callback to delete class commands from the store
--- @param fctAddToClassStore function Callback to add class commands to the store
--- @param argumentsStore KeyValueStore The store containing custom Maven arguments
--- @usage
---   show_test_selector(
---     function() return store.get("run_method") end,
---     function() return store.get("run_class") end,
---     function(cmd) store.remove("run_method", cmd) end,
---     function(cmd) store.add("run_method", cmd) end,
---     function(cmd) store.remove("run_class", cmd) end,
---     function(cmd) store.add("run_class", cmd) end,
---     argumentsStore
---   )
function M.show_test_selector(
	getTestMethodCommands,
	getTestClassCommands,
	fctDeleteFromMethodStore,
	fctAddToMethodStore,
	fctDeleteFromClassStore,
	fctAddToClassStore,
	argumentsStore
)
	_show_test_selector(
		getTestMethodCommands,
		getTestClassCommands,
		fctDeleteFromMethodStore,
		fctAddToMethodStore,
		fctDeleteFromClassStore,
		fctAddToClassStore,
		argumentsStore
	)
end

return M

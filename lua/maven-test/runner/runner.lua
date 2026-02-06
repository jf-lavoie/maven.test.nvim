--- Maven test runner module
--- Executes Maven commands in Neovim terminal
--- Handles command construction with package/class/method names
--- @module maven-test.runner.runner

local M = {}

--- Extract the package name from the current Java file
--- Searches the first 50 lines for a package declaration
--- @return string|nil The package name (e.g., "com.example.app"), or nil if not found
--- @private
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

--- Run a Maven command in a terminal split
--- Appends active custom arguments before execution
--- Opens a new terminal split at the bottom of the editor
--- @param command string The Maven command to execute
--- @usage
---   runner.run_command("mvn test")
---   runner.run_command("mvn test -Dtest=com.example.MyTest#testMethod")
function M.run_command(command)
	local customArguments = require("maven-test.store.arguments")

	for _, arg in ipairs(customArguments.list()) do
		if arg.active then
			command = arg:append_to_command(command)
		end
	end

	vim.notify("Running: " .. command, vim.log.levels.INFO)

	-- Open a new terminal split
	vim.cmd("botright split | enew")
	local lCmd = 'echo "$ ' .. command .. '" && ' .. command
	vim.fn.jobstart(lCmd, { term = true })
	vim.cmd("startinsert")
end

--- Run a specific test method
--- Constructs fully qualified test name: package.ClassName#methodName
--- Formats the command template with the fully qualified name
--- @param method_name string The test method name (e.g., "testSomething")
--- @param command string The Maven command template with %s placeholder
--- @usage
---   runner.run_test_method("testMethod", "mvn test -Dtest=%s")
function M.run_test_method(method_name, command)
	local class_name = require("maven-test.tests.parser").get_test_class()
	local package_name = get_package_name()

	if not class_name or not package_name then
		vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
		return
	end

	local fully_qualified = package_name .. "." .. class_name .. "#" .. method_name
	local localCommand = string.format(command, fully_qualified)
	M.run_command(localCommand)
end

--- Run all tests in the current class
--- Constructs fully qualified class name: package.ClassName
--- Formats the command template with the fully qualified name
--- @param command string The Maven command template with %s placeholder
--- @usage
---   runner.run_test_class("mvn test -Dtest=%s")
function M.run_test_class(command)
	local class_name = require("maven-test.tests.parser").get_test_class()
	local package_name = get_package_name()

	if not class_name or not package_name then
		vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
		return
	end

	local fully_qualified = package_name .. "." .. class_name.name
	local localCommand = string.format(command, fully_qualified)
	M.run_command(localCommand)
end

--- Run all tests in the project
--- Executes the command as-is without modification
--- @param command string The Maven command (e.g., "mvn test")
--- @usage
---   runner.run_all_tests("mvn test")
function M.run_all_tests(command)
	M.run_command(command)
end

return M

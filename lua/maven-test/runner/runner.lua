--- Maven test runner module
--- Executes Maven commands in Neovim terminal
--- Handles command construction with package/class/method names
--- @module 'maven-test.runner.runner'

local M = {}

--- Template a string by replacing {placeholder} patterns with values
--- @param str string The template string (e.g., "mvn test -Dtest={class}#{method}")
--- @param vars table A table of placeholder values (e.g., {class="MyTest", method="testFoo"})
--- @return string The templated string with placeholders replaced
--- @private
local function template(str, vars)
	return require("maven-test.template").template(str, vars)
end

--- Run a Maven command in a terminal split
--- Appends active custom arguments before execution
--- Opens a new terminal split at the bottom of the editor
--- @param command string The Maven command to execute
--- @usage
---   runner.run_command("mvn test")
---   runner.run_command("mvn test -Dtest=com.example.MyTest#testMethod")
function M.run_command(command, argumentsStore)
	for _, arg in ipairs(argumentsStore:list()) do
		if arg.active then
			command = arg:append_to_command(command)
		end
	end

	vim.notify("Running: " .. command, vim.log.levels.INFO)

	-- Open a new terminal split
	vim.cmd("botright split | enew")
	-- TODO: fix command for all escapes (e.g., single quotes, backticks)
	local lCmd = 'echo "$ ' .. command:gsub('"', '\\"') .. '" && ' .. command:gsub('"', '\\"')
	vim.fn.jobstart(lCmd, { term = true })
	vim.cmd("startinsert")
end

--- Run a specific test method
--- Constructs fully qualified test name: package.ClassName#methodName
--- Formats the command template with placeholders: {file}, {class}, {testmethod}
--- @param command string The Maven command template with placeholders
--- @usage
---   runner.run_test_method("testMethod", "mvn test -Dtest={class}#{testmethod}")
function M.run_test_method(command, argumentsStore)
	local class_name = require("maven-test.tests.parsers").get_test_class()
	local package_name = require("maven-test.tests.parsers").get_package_name()
	local methods = require("maven-test.tests.parsers").get_test_methods()
	local current_function = nil
	for _, value in ipairs(methods) do
		if value.is_current then
			current_function = value.name
			break
		end
	end

	if not class_name or not package_name or not current_function then
		vim.notify("Could not determine test package, class or method", vim.log.levels.ERROR)
		return
	end

	local templateValues = {
		namespace = package_name,
		class = class_name,
		fully_qualified_class = package_name .. "." .. class_name,
		func = current_function,
	}

	local localCommand = template(command, templateValues)
	M.run_command(localCommand, argumentsStore)
end

--- Run all tests in the current class
--- Constructs fully qualified class name: package.ClassName
--- Formats the command template with placeholders: {file}, {class}
--- @param command string The Maven command template with placeholders
--- @usage
---   runner.run_test_class("mvn test -Dtest={class}")
function M.run_test_class(pattern, command, argumentsStore)
	local class = require("maven-test.tests.parsers").get_test_class(pattern)
	local package_name = require("maven-test.tests.parsers").get_package_name(pattern)

	if not class or not package_name then
		vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
		return
	end

	local templateValues = {
		package = package_name,
		class = class.name,
	}

	local localCommand = template(command, templateValues)
	M.run_command(localCommand, argumentsStore)
end

--- Run all tests in the project
--- Executes the command as-is without modification
--- @param command string The Maven command (e.g., "mvn test")
--- @usage
---   runner.run_all_tests("mvn test")
function M.run_all_tests(command, argumentsStore)
	M.run_command(command, argumentsStore)
end

return M

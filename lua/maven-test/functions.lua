--- High-level orchestration functions for Maven test operations
--- Coordinates between UI, store, and runner modules
--- Manages store initialization and default command setup
--- @module 'maven-test.functions'

local M = {}

local store = require("maven-test.commands.store")
local store_arg = require("maven-test.arguments.store")

--- Store keys for different command types
local RUN_ALL_KEY = "run_all"
local RUN_CLASS_KEY = "run_class"
local RUN_METHOD_KEY = "run_method"
local RUN_ALL_DEBUG_KEY = "run_all_debug"
local RUN_CLASS_DEBUG_KEY = "run_class_debug"
local RUN_METHOD_DEBUG_KEY = "run_method_debug"
local COMMANDS = "commands"

--- Initialization flag to ensure setup runs only once
local initialized = false

--- Add default Maven commands to the store
--- Only adds commands if the store key is empty
--- Includes test commands and Maven lifecycle commands
--- @private
local function _default_commands()
	local options = require("maven-test").config

	if #store.get(RUN_ALL_KEY) == 0 then
		store.add(RUN_ALL_KEY, options.maven_command .. " test")
	end
	if #store.get(RUN_CLASS_KEY) == 0 then
		store.add(RUN_CLASS_KEY, options.maven_command .. " test -Dtest=%s")
	end
	if #store.get(RUN_METHOD_KEY) == 0 then
		store.add(RUN_METHOD_KEY, options.maven_command .. " test -Dtest=%s")
	end
	if #store.get(RUN_ALL_DEBUG_KEY) == 0 then
		store.add(
			RUN_ALL_DEBUG_KEY,
			options.maven_command
				.. ' test -Dmaven.surefire.debug="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address='
				.. options.debug_port
				.. '"'
		)
	end
	if #store.get(RUN_CLASS_DEBUG_KEY) == 0 then
		store.add(
			RUN_CLASS_DEBUG_KEY,
			options.maven_command
				.. ' test -Dtest=%s -Dmaven.surefire.debug"-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address='
				.. options.debug_port
				.. '"'
		)
	end
	if #store.get(RUN_METHOD_DEBUG_KEY) == 0 then
		store.add(
			RUN_METHOD_DEBUG_KEY,
			options.maven_command
				.. ' test -Dtest=%s -Dmaven.surefire.debug"-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address='
				.. options.debug_port
				.. '"'
		)
	end

	if #store.get(COMMANDS) == 0 then
		store.add(COMMANDS, options.maven_command .. " site")
		store.add(COMMANDS, options.maven_command .. " clean")
		store.add(COMMANDS, options.maven_command .. " deploy")
		store.add(COMMANDS, options.maven_command .. " install")
		store.add(COMMANDS, options.maven_command .. " verify")
		store.add(COMMANDS, options.maven_command .. " package")
		store.add(COMMANDS, options.maven_command .. " test")
		store.add(COMMANDS, options.maven_command .. " compile")
		store.add(COMMANDS, options.maven_command .. " validate")
	end
end

--- Initialize the functions module
--- Ensures default commands are added to store on first use
--- Safe to call multiple times - only initializes once
--- @private
local function _initialize()
	if initialized then
		return
	end

	initialized = true

	_default_commands()
end

--- Show Maven commands UI
--- Displays all stored Maven lifecycle commands in a floating window
--- User can execute, edit, or delete commands
function M.commands()
	_initialize()

	require("maven-test.commands.ui").show_commands(function()
		return store.get(COMMANDS)
	end, function(value)
		store.remove(COMMANDS, value)
	end, function(value)
		store.add(COMMANDS, value)
	end)
end

--- Show custom arguments editor UI
--- Allows user to add, toggle, edit, and delete custom Maven arguments
function M.show_custom_arguments()
	_initialize()

	require("maven-test.arguments.ui").default_arguments_editor(
		store_arg.list,
		store_arg.add,
		store_arg.update,
		store_arg.remove,
		function() end
	)
end

--- Show test selector UI for running a specific test method
--- Opens two-pane floating window with test list and command preview
function M.run_test()
	_initialize()
	require("maven-test.tests.ui").show_test_selector(function()
		return store.get(RUN_METHOD_KEY)
	end, function(value)
		store.remove(RUN_METHOD_KEY, value)
	end, function(value)
		store.add(RUN_METHOD_KEY, value)
	end)
end

--- Run all tests in the current test class
--- Uses the first stored command template for running test classes
function M.run_test_class()
	_initialize()
	local cmd = store.first(RUN_CLASS_KEY)
	require("maven-test.runner.runner").run_test_class(cmd)
end

--- Run all tests in the project
--- Uses the first stored command for running all tests
function M.run_all_tests()
	_initialize()
	local cmd = store.first(RUN_ALL_KEY)
	require("maven-test.runner.runner").run_all_tests(cmd)
end

--- Show test selector UI for debugging a specific test method
--- Opens two-pane floating window with test list and debug command preview
function M.run_test_debug()
	_initialize()
	require("maven-test.tests.ui").show_test_selector(function()
		return store.get(RUN_METHOD_DEBUG_KEY)
	end, function(value)
		store.remove(RUN_METHOD_DEBUG_KEY, value)
	end, function(value)
		store.add(RUN_METHOD_DEBUG_KEY, value)
	end)
end

--- Debug all tests in the current test class
--- Uses the first stored debug command template for test classes
function M.run_test_class_debug()
	_initialize()
	local cmd = store.first(RUN_CLASS_DEBUG_KEY)
	require("maven-test.runner.runner").run_test_class(cmd)
end

--- Debug all tests in the project
--- Uses the first stored debug command for all tests
function M.run_all_tests_debug()
	_initialize()
	local cmd = store.first(RUN_ALL_DEBUG_KEY)
	require("maven-test.runner.runner").run_all_tests(cmd)
end

--- Restore command store to default state
--- Clears all stored commands and re-adds default commands
--- Useful for resetting to a known good state
function M.restore_store()
	_initialize()
	store.empty_store()
	_default_commands()
end

return M

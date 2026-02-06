local M = {}

local store = require("maven-test.store")
local store_arg = require("maven-test.store_arguments")

local RUN_ALL_KEY = "run_all"
local RUN_CLASS_KEY = "run_class"
local RUN_METHOD_KEY = "run_method"
local RUN_ALL_DEBUG_KEY = "run_all_debug"
local RUN_CLASS_DEBUG_KEY = "run_class_debug"
local RUN_METHOD_DEBUG_KEY = "run_method_debug"
local COMMANDS = "commands"

local initialized = false

local function _default_commands()
	local options = require("maven-test").config

	if #store.get(RUN_ALL_KEY) == 0 then
		store.add_to_store(RUN_ALL_KEY, options.maven_command .. " test")
	end
	if #store.get(RUN_CLASS_KEY) == 0 then
		store.add_to_store(RUN_CLASS_KEY, options.maven_command .. " test -Dtest=%s")
	end
	if #store.get(RUN_METHOD_KEY) == 0 then
		store.add_to_store(RUN_METHOD_KEY, options.maven_command .. " test -Dtest=%s")
	end
	if #store.get(RUN_ALL_DEBUG_KEY) == 0 then
		store.add_to_store(
			RUN_ALL_DEBUG_KEY,
			options.maven_command
				.. ' test -Dmaven.surefire.debug="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address='
				.. options.debug_port
				.. '"'
		)
	end
	if #store.get(RUN_CLASS_DEBUG_KEY) == 0 then
		store.add_to_store(
			RUN_CLASS_DEBUG_KEY,
			options.maven_command
				.. ' test -Dtest=%s -Dmaven.surefire.debug"-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address='
				.. options.debug_port
				.. '"'
		)
	end
	if #store.get(RUN_METHOD_DEBUG_KEY) == 0 then
		store.add_to_store(
			RUN_METHOD_DEBUG_KEY,
			options.maven_command
				.. ' test -Dtest=%s -Dmaven.surefire.debug"-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address='
				.. options.debug_port
				.. '"'
		)
	end

	if #store.get(COMMANDS) == 0 then
		store.add_to_store(COMMANDS, options.maven_command .. " site")
		store.add_to_store(COMMANDS, options.maven_command .. " clean")
		store.add_to_store(COMMANDS, options.maven_command .. " deploy")
		store.add_to_store(COMMANDS, options.maven_command .. " install")
		store.add_to_store(COMMANDS, options.maven_command .. " verify")
		store.add_to_store(COMMANDS, options.maven_command .. " package")
		store.add_to_store(COMMANDS, options.maven_command .. " test")
		store.add_to_store(COMMANDS, options.maven_command .. " compile")
		store.add_to_store(COMMANDS, options.maven_command .. " validate")
	end
end
local function _initialize()
	if initialized then
		return
	end

	initialized = true

	_default_commands()
end

function M.commands()
	_initialize()

	require("maven-test.ui-commands").show_commands(function()
		return store.get(COMMANDS)
	end, function(value)
		store.remove_from_store(COMMANDS, value)
	end, function(value)
		store.add_to_store(COMMANDS, value)
	end)
end

function M.show_custom_arguments()
	_initialize()

	require("maven-test.ui").default_arguments_editor(
		store_arg.list,
		store_arg.add_to_store,
		store_arg.update,
		store_arg.remove_from_store,
		function() end
	)
end

function M.run_test()
	_initialize()
	require("maven-test.ui-tests").show_test_selector(function()
		return store.get(RUN_METHOD_KEY)
	end, function(value)
		store.remove_from_store(RUN_METHOD_KEY, value)
	end, function(value)
		store.add_to_store(RUN_METHOD_KEY, value)
	end)
end

function M.run_test_class()
	_initialize()
	local cmds = store.first(RUN_CLASS_KEY)
	require("maven-test.runner").run_test_class(cmds)
end

function M.run_all_tests()
	_initialize()
	local cmds = store.first(RUN_ALL_KEY)
	require("maven-test.runner").run_all_tests(cmds)
end

function M.run_test_debug()
	_initialize()
	local cmds = store.get(RUN_METHOD_DEBUG_KEY)
	require("maven-test.ui-tests").show_test_selector(cmds)
end

function M.run_test_class_debug()
	_initialize()
	local cmds = store.first(RUN_CLASS_DEBUG_KEY)
	require("maven-test.runner").run_test_class(cmds)
end

function M.run_all_tests_debug()
	_initialize()
	local cmds = store.first(RUN_ALL_DEBUG_KEY)
	require("maven-test.runner").run_all_tests(cmds)
end

function M.restore_store()
	_initialize()
	store.empty_store()
	_default_commands()
end

return M

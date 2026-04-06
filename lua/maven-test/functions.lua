--- High-level orchestration functions for Maven test operations
--- Coordinates between UI, store, and runner modules
--- Manages store initialization and default command setup
--- @module 'maven-test.functions'

local RUN_ALL_KEY = "run_all"
local RUN_CLASS_KEY = "run_class"
local RUN_METHOD_KEY = "run_method"
local COMMANDS = "commands"

local M = {}

ProjectFunctions = {}
ProjectFunctions.__index = ProjectFunctions

function ProjectFunctions.new(projectConfig)
	local self = setmetatable({}, ProjectFunctions)
	self.projectConfig = projectConfig
	self.initialized = false
	self.store_cmds = require("maven-test.commands.store").new(projectConfig.type)
	self.store_arguments = require("maven-test.arguments.store").new(projectConfig.type)
	return self
end

--- Initialize the functions module
--- Ensures default commands are added to store on first use
--- Safe to call multiple times - only initializes once
--- @private
function ProjectFunctions:_initialize()
	if self.initialized then
		return
	end

	self.initialized = true
	self:_default_commands()
end

function ProjectFunctions:_default_commands()
	if #self.store_cmds:get(RUN_ALL_KEY) == 0 then
		for _, cmd in ipairs(self.projectConfig.test_commands) do
			self.store_cmds:add(RUN_ALL_KEY, cmd)
		end
	end
	if #self.store_cmds:get(RUN_CLASS_KEY) == 0 then
		for _, cmd in ipairs(self.projectConfig.test_file_commands) do
			self.store_cmds:add(RUN_CLASS_KEY, cmd)
		end
	end
	if #self.store_cmds:get(RUN_METHOD_KEY) == 0 then
		for _, cmd in ipairs(self.projectConfig.test_method_commands) do
			self.store_cmds:add(RUN_METHOD_KEY, cmd)
		end
	end
	if #self.store_cmds:get(COMMANDS) == 0 then
		for _, cmd in ipairs(self.projectConfig.commands) do
			self.store_cmds:add(COMMANDS, cmd)
		end
	end
end

--- Show Maven commands UI
--- Displays all stored Maven lifecycle commands in a floating window
--- User can execute, edit, or delete commands
function ProjectFunctions:commands()
	self:_initialize()

	require("maven-test.commands.ui").show_commands(function()
		return self.store_cmds:get(COMMANDS)
	end, function(value)
		self.store_cmds:remove(COMMANDS, value)
	end, function(value)
		self.store_cmds:add(COMMANDS, value)
	end, function(cmd)
		self.store_cmds:move_first(COMMANDS, cmd)

		local runner = require("maven-test.runner.runner")

		runner.run_command(cmd, self.store_arguments)
	end, self.store_arguments)
end

--- Show custom arguments editor UI
--- Allows user to add, toggle, edit, and delete custom Maven arguments
function ProjectFunctions:show_custom_arguments()
	self:_initialize()

	require("maven-test.arguments.ui").external_default_arguments_editor(self.store_arguments, function() end)
end

--- Show test selector UI for running a specific test method
--- Opens two-pane floating window with test list and command preview
function ProjectFunctions:run_test()
	self:_initialize()
	require("maven-test.tests.ui").show_test_selector(function()
		return self.store_cmds:get(RUN_METHOD_KEY)
	end, function()
		return self.store_cmds:get(RUN_CLASS_KEY)
	end, function(value)
		self.store_cmds:remove(RUN_METHOD_KEY, value)
	end, function(value)
		self.store_cmds:add(RUN_METHOD_KEY, value)
	end, function(value)
		self.store_cmds:remove(RUN_CLASS_KEY, value)
	end, function(value)
		self.store_cmds:add(RUN_CLASS_KEY, value)
	end, self.store_arguments)
end

--- Run all tests in the current test class
--- Uses the first stored command template for running test classes
function ProjectFunctions:run_test_class()
	self:_initialize()
	local cmd = self.store_cmds:first(RUN_CLASS_KEY)

	require("maven-test.runner.runner").run_test_class(self.projectConfig.type, cmd, self.store_arguments)
end

--- Run all tests in the project
--- Uses the first stored command for running all tests
function ProjectFunctions:run_all_tests()
	self:_initialize()
	local cmd = self.store_cmds:first(RUN_ALL_KEY)
	require("maven-test.runner.runner").run_all_tests(cmd, self.store_arguments)
end

--- Restore command store to default state
--- Clears all stored commands and re-adds default commands
--- Useful for resetting to a known good state
function ProjectFunctions:restore_commands_store()
	self:_initialize()
	self.store_cmds:empty_store()
	self:_default_commands()
end

--- Restore arguments store to default state
--- Clears all stored arguments and re-adds default arguments
--- Useful for resetting to a known good state
function ProjectFunctions:restore_arguments_store()
	self:_initialize()
	self.store_arg.empty_store()
end

local cache = {}
local function _getCacheValue(projectConfig)
	if not cache[projectConfig.type] then
		cache[projectConfig.type] = ProjectFunctions.new(projectConfig)
	end
	return cache[projectConfig.type]
end

--- Show Maven commands UI
--- Displays all stored Maven lifecycle commands in a floating window
--- User can execute, edit, or delete commands
function M.commands(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)

	projectFunctions:commands()
end

--- Show custom arguments editor UI
--- Allows user to add, toggle, edit, and delete custom Maven arguments
function M.show_custom_arguments(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)

	projectFunctions:show_custom_arguments()
end

--- Show test selector UI for running a specific test method
--- Opens two-pane floating window with test list and command preview
function M.run_test(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)
	projectFunctions:run_test()
end

--- Run all tests in the current test class
--- Uses the first stored command template for running test classes
function M.run_test_class(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)
	projectFunctions:run_test_class()
end

--- Run all tests in the project
--- Uses the first stored command for running all tests
function M.run_all_tests(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)
	projectFunctions:run_all_tests()
end

--- Restore command store to default state
--- Clears all stored commands and re-adds default commands
--- Useful for resetting to a known good state
function M.restore_commands_store(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)
	projectFunctions:restore_commands_store()
end

--- Restore arguments store to default state
--- Clears all stored arguments and re-adds default arguments
--- Useful for resetting to a known good state
function M.restore_arguments_store(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)
	projectFunctions:restore_arguments_store()
end

return M

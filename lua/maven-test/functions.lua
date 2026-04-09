--- High-level orchestration functions for test operations
--- Coordinates between UI, store, and runner modules
--- Manages per-project store initialization, caching, and default command setup
--- Supports multiple project types (Maven, Gradle, Go, Lua)
--- @module 'maven-test.functions'

--- Key constants for command store categories
--- @private
local RUN_ALL_KEY = "run_all" -- Commands for running all tests in project
local RUN_CLASS_KEY = "run_class" -- Commands for running test class/file
local RUN_METHOD_KEY = "run_method" -- Commands for running test method/function
local COMMANDS = "commands" -- Common project commands (Maven lifecycle, etc.)

local M = {}

--- ProjectFunctions class for managing project-specific test operations
--- Each project type gets its own instance with dedicated stores
--- @class ProjectFunctions
--- @field projectConfig ProjectConfig The project configuration
--- @field initialized boolean Whether the instance has been initialized
--- @field store_cmds table Command store for this project type
--- @field store_arguments table Argument store for this project type
ProjectFunctions = {}
ProjectFunctions.__index = ProjectFunctions

--- Create a new ProjectFunctions instance for a project type
--- @param projectConfig ProjectConfig The project configuration
--- @return ProjectFunctions A new ProjectFunctions instance
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

--- Populate store with default commands from project configuration
--- Only adds commands if the store category is empty
--- @private
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
	if
		self.projectConfig.commands ~= nil
		and #self.projectConfig.commands > 0
		and #self.store_cmds:get(COMMANDS) == 0
	then
		for _, cmd in ipairs(self.projectConfig.commands) do
			self.store_cmds:add(COMMANDS, cmd)
		end
	end
end

--- Show project commands UI
--- Displays all stored project commands (Maven lifecycle, Gradle tasks, etc.) in a floating window
--- User can execute, edit, delete commands, and manage command order
--- Commands are stored per project type
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
--- Allows user to add, toggle (active/inactive), edit, and delete custom build tool arguments
--- Arguments are applied to all commands before execution
function ProjectFunctions:show_custom_arguments()
	self:_initialize()

	require("maven-test.arguments.ui").external_default_arguments_editor(self.store_arguments, function() end)
end

--- Show test selector UI for running a specific test method
--- Opens two-pane floating window with test list (top) and command preview (bottom)
--- Detects test methods/functions in current file using treesitter
--- User can select method, edit/delete commands, and execute tests
function ProjectFunctions:run_test()
	self:_initialize()
	require("maven-test.tests.ui").show_test_selector(self.projectConfig.pattern, function()
		return self.store_cmds:get(RUN_METHOD_KEY)
	end, function(value)
		self.store_cmds:remove(RUN_METHOD_KEY, value)
	end, function(value)
		self.store_cmds:add(RUN_METHOD_KEY, value)
	end, self.store_arguments)
end

--- Run all tests in the current test class/file
--- Uses the first stored command template for running test classes
--- Automatically detects class name and package using treesitter
function ProjectFunctions:run_test_class()
	self:_initialize()
	local cmd = self.store_cmds:first(RUN_CLASS_KEY)

	require("maven-test.runner.runner").run_test_class(self.projectConfig.pattern, cmd, self.store_arguments)
end

--- Run all tests in the project
--- Uses the first stored command for running all tests
function ProjectFunctions:run_all_tests()
	self:_initialize()
	local cmd = self.store_cmds:first(RUN_ALL_KEY)
	require("maven-test.runner.runner").run_all_tests(cmd, self.store_arguments)
end

--- Restore command store to default state
--- Clears all stored commands and re-adds defaults from project configuration
--- Useful for resetting after experimenting with custom commands
function ProjectFunctions:restore_commands_store()
	self:_initialize()
	self.store_cmds:empty_store()
	self:_default_commands()
end

--- Restore arguments store to default state
--- Clears all custom arguments
--- Useful for resetting after experimenting with custom arguments
function ProjectFunctions:restore_arguments_store()
	self:_initialize()
	self.store_arg.empty_store()
end

--- Cache for ProjectFunctions instances per project type
--- Ensures singleton behavior per project type
--- @type table<string, ProjectFunctions>
local cache = {}

--- Get or create a cached ProjectFunctions instance for the project type
--- @param projectConfig ProjectConfig The project configuration
--- @return ProjectFunctions The cached or newly created instance
--- @private
local function _getCacheValue(projectConfig)
	if not cache[projectConfig.type] then
		cache[projectConfig.type] = ProjectFunctions.new(projectConfig)
	end
	return cache[projectConfig.type]
end

--- Show project commands UI
--- Displays all stored project commands in a floating window
--- User can execute, edit, delete commands, and manage command order
--- @param projectConfig ProjectConfig The project configuration
function M.commands(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)

	projectFunctions:commands()
end

--- Show custom arguments editor UI
--- Allows user to add, toggle (active/inactive), edit, and delete custom build tool arguments
--- @param projectConfig ProjectConfig The project configuration
function M.show_custom_arguments(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)

	projectFunctions:show_custom_arguments()
end

--- Show test selector UI for running a specific test method
--- Opens two-pane floating window with test list (top) and command preview (bottom)
--- @param projectConfig ProjectConfig The project configuration
function M.run_test(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)
	projectFunctions:run_test()
end

--- Run all tests in the current test class/file
--- Uses the first stored command template for running test classes
--- @param projectConfig ProjectConfig The project configuration
function M.run_test_class(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)
	projectFunctions:run_test_class()
end

--- Run all tests in the project
--- Uses the first stored command for running all tests
--- @param projectConfig ProjectConfig The project configuration
function M.run_all_tests(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)
	projectFunctions:run_all_tests()
end

--- Restore command store to default state
--- Clears all stored commands and re-adds defaults from project configuration
--- @param projectConfig ProjectConfig The project configuration
function M.restore_commands_store(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)
	projectFunctions:restore_commands_store()
end

--- Restore arguments store to default state
--- Clears all custom arguments
--- @param projectConfig ProjectConfig The project configuration
function M.restore_arguments_store(projectConfig)
	local projectFunctions = _getCacheValue(projectConfig)
	projectFunctions:restore_arguments_store()
end

return M

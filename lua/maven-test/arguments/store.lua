--- Maven custom arguments store module
--- Provides a singleton key-value store for managing custom Maven arguments
--- Each argument is stored with its text as the key and an Argument object as the value
--- Persists to arguments.json in the project data directory
---
--- The store manages Maven arguments that can be:
--- - Added with active/inactive state
--- - Toggled on/off
--- - Retrieved for appending to Maven commands
--- - Persisted across Neovim sessions
---
--- @module 'maven-test.arguments.store'
--- @see maven-test.arguments.argument For Argument class definition
--- @see maven-test.store.key_value_store For underlying storage implementation
---
--- @usage
---   local arguments_store = require("maven-test.arguments.store")
---   local Argument = require("maven-test.arguments.argument").Argument
---
---   -- Add a new argument
---   arguments_store:add("-X", Argument.new("-X", true))
---
---   -- Get an argument
---   local arg = arguments_store:get("-X")
---
---   -- List all arguments
---   local all_args = arguments_store:list()

local Argument = require("maven-test.arguments.argument").Argument
local KeyValueStore = require("maven-test.store.key_value_store").KeyValueStore

local M = {}

function M.new(project_type)
	local store = KeyValueStore.new(string.format("%s_arguments.json", project_type), function(data)
		return Argument.new(data.text, data.active)
	end)
	return store
end

return M

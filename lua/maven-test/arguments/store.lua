--- Maven custom arguments store module
--- Factory for creating project-specific argument stores
--- Each store manages custom Maven arguments with active/inactive state
--- Persists to {project_type}_arguments.json in the project data directory
---
--- @module 'maven-test.arguments.store'
--- @see maven-test.arguments.argument For Argument class definition
--- @see maven-test.store.key_value_store For underlying storage implementation

local Argument = require("maven-test.arguments.argument").Argument
local KeyValueStore = require("maven-test.store.key_value_store").KeyValueStore

local M = {}

--- Creates a new custom arguments store for the specified project type
--- @param project_type string The project type identifier (e.g., "maven", "gradle")
--- @return KeyValueStore The arguments store instance with Argument deserialization
function M.new(project_type)
	local store = KeyValueStore.new(string.format("%s_arguments.json", project_type), function(data)
		return Argument.new(data.text, data.active)
	end)
	return store
end

return M

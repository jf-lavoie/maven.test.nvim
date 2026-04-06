--- Maven command store module
--- Factory for creating project-specific Maven command stores
--- Each store manages command templates with most recently used ordering
--- Persists to {project_type}_commands.json in the project data directory
---
--- @module 'maven-test.commands.store'
--- @see maven-test.store.key_values_store For underlying storage implementation

local KeyValuesStore = require("maven-test.store.key_values_store").KeyValuesStore

local M = {}

--- Creates a new Maven command store for the specified project type
--- @param project_type string The project type identifier (e.g., "maven", "gradle")
--- @return KeyValuesStore The command store instance
function M.new(project_type)
	local store = KeyValuesStore.new(string.format("%s_commands.json", project_type))
	return store
end

return M

--- In-memory key-value store where values are arrays of strings
-- local store = KeyValuesStore.new("store.json")
--
-- return store

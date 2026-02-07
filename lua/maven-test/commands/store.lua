--- Maven command store module
--- Manages storage and retrieval of Maven command templates
--- Store structure: { [key: string]: string[] }
--- Commands are stored as arrays, with most recently used first
--- @module 'maven-test.store.store'

local M = {}

local persistence = require("maven-test.store.persistence").Persistence.new("store.json")

--- In-memory key-value store where values are arrays of strings
local store = {}

--- Initialize the store by loading from disk
--- Uses lazy initialization pattern - runs only once per session
--- Subsequent calls are no-ops (function replaces itself)
--- @private
local function _initialize_store()
	store = persistence:load()
	_initialize_store = function() end
end

--- Save current store state to disk
--- @private
local function save()
	_initialize_store()
	persistence:save(store)
end

--- Reload store from disk, discarding in-memory changes
--- Useful for synchronizing with external modifications
function M.load()
	_initialize_store()
	store = persistence:load()
end

--- Add a command to the store
--- If the key doesn't exist, creates a new array with the value
--- If the value already exists for this key, does nothing (idempotent)
--- New values are inserted at the front (most recently used first)
--- Automatically persists to disk after addition
--- @param key string The store key (e.g., "run_method", "run_class")
--- @param value string The Maven command template to store
--- @usage
---   store.add("run_method", "mvn test -Dtest=%s")
---   store.add("run_all", "mvn test")
function M.add(key, value)
	_initialize_store()
	if not store[key] then
		store[key] = { value }
		save()
		return
	end

	for _, v in ipairs(store[key]) do
		if v == value then
			return
		end
	end

	table.insert(store[key], 1, value)
	save()
end

--- Remove a specific command from the store
--- Finds and removes the first occurrence of the value for the given key
--- If the key becomes empty after removal, the key is deleted
--- Automatically persists to disk after removal
--- @param key string The store key
--- @param value string The command to remove
--- @usage
---   store.remove("run_method", "mvn test -Dtest=%s")
function M.remove(key, value)
	_initialize_store()
	if not store[key] then
		return
	end

	for i, v in ipairs(store[key]) do
		if v == value then
			table.remove(store[key], i)
			break
		end
	end

	if #store[key] == 0 then
		store[key] = nil
	end

	save()
end

--- Get the first (most recently used) command for a key
--- @param key string The store key
--- @return string|nil The first command, or nil if key doesn't exist or is empty
--- @usage
---   local cmd = store.first("run_method")
---   if cmd then
---     runner.run_command(cmd)
---   end
function M.first(key)
	_initialize_store()
	if not store[key] or #store[key] == 0 then
		return nil
	end
	return store[key][1]
end

--- Get all commands for a key
--- Returns an empty table if the key doesn't exist (non-nil guarantee)
--- @param key string The store key
--- @return string[] Array of commands, or empty table if key doesn't exist
--- @usage
---   local commands = store.get("run_method")
---   for _, cmd in ipairs(commands) do
---     print(cmd)
---   end
function M.get(key)
	_initialize_store()
	return store[key] or {}
end

--- Clear all data from the store
--- Removes all keys and values, then persists the empty state to disk
--- Useful for resetting to a clean state
--- @usage
---   store.empty_store()  -- Remove all stored commands
function M.empty_store()
	_initialize_store()
	store = {}
	save()
end

return M

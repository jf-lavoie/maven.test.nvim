--- Maven command store module
--- Manages storage and retrieval of Maven command templates
--- Store structure: { [key: string]: string[] }
--- Commands are stored as arrays, with most recently used first
--- @module 'maven-test.store.key_values_store'

local M = {}

local Persistence = require("maven-test.store.persistence").Persistence

--- In-memory key-value store where values are arrays of strings
M.KeyValueStore = {}
M.KeyValueStore.__index = M.KeyValueStore

function M.KeyValueStore.new(fileName)
	local self = setmetatable({}, M.KeyValueStore)

	self.persistence = Persistence.new(fileName)
	self.store = {}

	return self
end

--- Initialize the store by loading from disk
--- Uses lazy initialization pattern - runs only once per session
--- Subsequent calls are no-ops (function replaces itself)
--- @private
function M.KeyValueStore:_initialize_store()
	self.store = self.persistence:load()
	self._initialize_store = function(self) end
end

--- Save current store state to disk
--- @private
function M.KeyValueStore:save()
	self:_initialize_store()
	self.persistence:save(self.store)
end

--- Reload store from disk, discarding in-memory changes
--- Useful for synchronizing with external modifications
function M.KeyValueStore:load()
	self:_initialize_store()
	self.store = self.persistence:load()
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
function M.KeyValueStore:add(key, value)
	self:_initialize_store()
	if not self.store[key] then
		self.store[key] = { value }
		self:save()
		return
	end

	for _, v in ipairs(self.store[key]) do
		if v == value then
			return
		end
	end

	table.insert(self.store[key], 1, value)
	self:save()
end

--- Remove a specific command from the store
--- Finds and removes the first occurrence of the value for the given key
--- If the key becomes empty after removal, the key is deleted
--- Automatically persists to disk after removal
--- @param key string The store key
--- @param value string The command to remove
--- @usage
---   store.remove("run_method", "mvn test -Dtest=%s")
function M.KeyValueStore:remove(key, value)
	self:_initialize_store()
	if not self.store[key] then
		return
	end

	for i, v in ipairs(self.store[key]) do
		if v == value then
			table.remove(self.store[key], i)
			break
		end
	end

	if #self.store[key] == 0 then
		self.store[key] = nil
	end

	self:save()
end

--- Get the first (most recently used) command for a key
--- @param key string The store key
--- @return string|nil The first command, or nil if key doesn't exist or is empty
--- @usage
---   local cmd = store.first("run_method")
---   if cmd then
---     runner.run_command(cmd)
---   end
function M.KeyValueStore:first(key)
	self:_initialize_store()
	if not self.store[key] or #self.store[key] == 0 then
		return nil
	end
	return self.store[key][1]
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
function M.KeyValueStore:get(key)
	self:_initialize_store()
	return self.store[key] or {}
end

--- Clear all data from the store
--- Removes all keys and values, then persists the empty state to disk
--- Useful for resetting to a clean state
--- @usage
---   store.empty_store()  -- Remove all stored commands
function M.KeyValueStore:empty_store()
	self:_initialize_store()
	self.store = {}
	self:save()
end

return M

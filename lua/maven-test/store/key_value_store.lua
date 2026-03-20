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

--- Create a new KeyValueStore instance
--- Initializes an empty in-memory store with file persistence
--- @param fileName string Name of the JSON file for persistence (e.g., "store.json")
--- @param onDataLoaded function|nil Optional callback to transform data when loading from disk
--- @return KeyValueStore New KeyValueStore instance
--- @usage
---   local store = KeyValueStore.new("arguments.json", function(data) return Argument.from_json(data) end)
function M.KeyValueStore.new(fileName, onDataLoaded)
	local self = setmetatable({}, M.KeyValueStore)

	self.persistence = Persistence.new(fileName)
	self.store = {}
	self.onDataLoaded = onDataLoaded

	return self
end

--- Initialize the store by loading from disk
--- Uses lazy initialization pattern - runs only once per session
--- Subsequent calls are no-ops (function replaces itself)
--- @private
function M.KeyValueStore:_initialize_store()
	local data = self.persistence:load()

	for key, value in pairs(data) do
		if self.onDataLoaded then
			local item = self.onDataLoaded(value)
			self.store[key] = item
		end
	end
	self._initialize_store = function() end
end

--- Save current store state to disk
--- @private
function M.KeyValueStore:save()
	self:_initialize_store()
	self.persistence:save(self.store)
end

--- Reload store from disk, discarding in-memory changes
--- Useful for synchronizing with external modifications
--- @usage
---   store:load()  -- Reload from disk
function M.KeyValueStore:load()
	self:_initialize_store()
	self.store = self.persistence:load()
end

--- Set or overwrite a key-value pair in the store
--- If the key exists, its value is completely replaced
--- If the key doesn't exist, it is created with the given value
--- Automatically persists to disk after the operation
--- @param key string The store key
--- @param value any The data to set (string, number, table, or object)
--- @usage
---   store:add("key1", "value")
---   store:add("key2", 1)
---   store:add("key3", {"a table"})
---   store:add("-X", Argument.new("-X", true))
function M.KeyValueStore:add(key, value)
	self:_initialize_store()
	self.store[key] = value

	self:save()
end

--- Update an existing argument's properties (typically the active state)
--- Finds the argument by text and updates its active flag
--- Automatically persists to disk after update
--- @param key string The store key
--- @param value Argument The argument object with updated properties
--- @usage
---   local arg = Argument.new("-X", false)  -- Deactivate the -X flag
---   arguments.update(arg.text, arg)
function M.KeyValueStore:update(key, value)
	self:_initialize_store()

	if self.store[key] then
		self.store[key] = value
	end
	self:save()
end

--- Remove a specific key and all its values from the store
--- Deletes the entire key entry from the store, removing all associated values
--- If the key doesn't exist, the operation is a no-op (no error)
--- Automatically persists to disk after removal
--- @param key string The store key to remove
--- @usage
---   store:remove("key1")  -- Removes the entire key and all its values
function M.KeyValueStore:remove(key)
	self:_initialize_store()
	if not self.store[key] then
		return
	end

	self.store[key] = nil

	self:save()
end

--- Get a shallow copy of the store as a list of values
--- Returns a copy of all values in the store to prevent external modifications
--- If the store is not initialized or empty, returns an empty array
--- @return table An array containing all values from the store
--- @usage
---   local items = store:list()
---   for _, item in ipairs(items) do
---     print(vim.inspect(item))
---   end
function M.KeyValueStore:list()
	self:_initialize_store()
	local original = self.store or {}
	local copy = {}
	for _, v in pairs(original) do
		table.insert(copy, v)
	end
	return copy
end

--- Get all commands for a key
--- Returns nil if the key doesn't exist
--- @param key string The store key
--- @return any the value associated to the key
--- @usage
---   local value = store.get("key1")
---   print(value)
function M.KeyValueStore:get(key)
	self:_initialize_store()
	return self.store[key] or nil
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

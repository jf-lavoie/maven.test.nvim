--- Key-Value store module
--- Manages storage and retrieval of key-value pairs where values can be any type
--- Store structure: { [key: string]: any }
--- Supports custom deserialization via onDataLoaded callback
--- Automatically persists to disk on modifications
--- @module 'maven-test.store.key_value_store'

local M = {}

local Persistence = require("maven-test.store.persistence").Persistence

--- In-memory key-value store with disk persistence
--- @class KeyValueStore
--- @field persistence Persistence The persistence layer for disk storage
--- @field store table<string, any> The in-memory store mapping keys to values
--- @field onDataLoaded function? Optional callback to transform data when loading from disk
M.KeyValueStore = {}
M.KeyValueStore.__index = M.KeyValueStore

--- Creates a new KeyValueStore instance
--- Initializes an empty in-memory store with file persistence
--- @param fileName string Name of the JSON file for persistence (e.g., "arguments.json")
--- @param onDataLoaded function? Optional callback to deserialize/transform data when loading from disk
--- @return KeyValueStore New KeyValueStore instance
--- @usage
---   local store = KeyValueStore.new("arguments.json", function(data) return Argument.new(data.text, data.active) end)
function M.KeyValueStore.new(fileName, onDataLoaded)
	local self = setmetatable({}, M.KeyValueStore)

	self.persistence = Persistence.new(fileName)
	self.store = {}
	self.onDataLoaded = onDataLoaded

	return self
end

--- Initializes the store by loading from disk
--- Uses lazy initialization pattern - runs only once per session
--- Subsequent calls are no-ops (function replaces itself with empty function)
--- Applies onDataLoaded callback to each value if provided
--- @private
function M.KeyValueStore:_initialize_store()
	local data = self.persistence:load()

	for key, value in pairs(data) do
		if self.onDataLoaded then
			local item = self.onDataLoaded(value)
			self.store[key] = item
		else
			self.store[key] = value
		end
	end
	self._initialize_store = function() end
end

--- Saves current store state to disk
--- Persists all key-value pairs to the JSON file
--- @private
function M.KeyValueStore:save()
	self:_initialize_store()
	self.persistence:save(self.store)
end

--- Reloads store from disk, discarding in-memory changes
--- Useful for synchronizing with external modifications
--- Does not apply onDataLoaded callback during reload
--- @usage
---   store:load()  -- Reload from disk
function M.KeyValueStore:load()
	self:_initialize_store()
	self.store = self.persistence:load()
end

--- Sets or overwrites a key-value pair in the store
--- If the key exists, its value is completely replaced
--- If the key doesn't exist, it is created with the given value
--- Automatically persists to disk after the operation
--- @param key string The store key
--- @param value any The value to store (can be any type: string, number, table, object)
--- @usage
---   store:add("key1", "value")
---   store:add("key2", 42)
---   store:add("key3", {enabled = true})
---   store:add("-X", Argument.new("-X", true))
function M.KeyValueStore:add(key, value)
	self:_initialize_store()
	self.store[key] = value

	self:save()
end

--- Updates an existing value in the store
--- Only updates if the key already exists (no-op if key doesn't exist)
--- Automatically persists to disk after update
--- @param key string The store key to update
--- @param value any The new value to store
--- @usage
---   local arg = Argument.new("-X", false)
---   store:update(arg.text, arg)
function M.KeyValueStore:update(key, value)
	self:_initialize_store()

	if self.store[key] then
		self.store[key] = value
	end
	self:save()
end

--- Removes a key-value pair from the store
--- Deletes the entire key entry from the store
--- If the key doesn't exist, the operation is a no-op (no error)
--- Automatically persists to disk after removal
--- @param key string The store key to remove
--- @usage
---   store:remove("key1")  -- Removes the key and its value
function M.KeyValueStore:remove(key)
	self:_initialize_store()
	if not self.store[key] then
		return
	end

	self.store[key] = nil

	self:save()
end

--- Gets all values from the store as a list
--- Returns a shallow copy of all values to prevent external modifications
--- If the store is not initialized or empty, returns an empty array
--- @return any[] An array containing all values from the store
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

--- Gets the value associated with a key
--- Returns nil if the key doesn't exist
--- @param key string The store key to retrieve
--- @return any? The value associated with the key, or nil if not found
--- @usage
---   local value = store:get("key1")
---   if value then
---     print(vim.inspect(value))
---   end
function M.KeyValueStore:get(key)
	self:_initialize_store()
	return self.store[key] or nil
end

--- Clears all data from the store
--- Removes all keys and values, then persists the empty state to disk
--- Useful for resetting to a clean state
--- @usage
---   store:empty_store()  -- Remove all stored data
function M.KeyValueStore:empty_store()
	self:_initialize_store()
	self.store = {}
	self:save()
end

return M

--- Custom Maven arguments store module
--- Manages storage and retrieval of custom Maven arguments that apply to all commands
--- @module 'maven-test.store.arguments'

local M = {}

--- In-memory store for CustomArgument objects
local store = {}

local persistence = require("maven-test.store.persistence").Persistence.new("arguments.json")
local CustomArgument = require("maven-test.arguments.argument").CustomArgument

--- @class CustomArgument
--- @field text string The Maven argument text
--- @field active boolean Whether this argument is currently active
--- @field toggle_active fun(self: CustomArgument): CustomArgument
--- @field append_to_command fun(self: CustomArgument, command: string): string

--- Initialize the store by loading from disk
--- Uses lazy initialization pattern - runs only once per session
--- Subsequent calls are no-ops (function replaces itself)
--- @private
local function _initialize_store()
	local data = persistence:load()

	for i, v in ipairs(data) do
		table.insert(store, i, CustomArgument.new(v.text, v.active))
	end

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

--- Add a custom argument to the store
--- Arguments are inserted at the front of the list (most recently added first)
--- Duplicate arguments (same text) are not added (idempotent operation)
--- Automatically persists to disk after addition
--- @param arg CustomArgument The argument object to add
--- @usage
---   local arg = CustomArgument.new("-X", true)
---   arguments.add(arg)
function M.add(arg)
	_initialize_store()

	for _, v in ipairs(store) do
		if v.text == arg.text then
			return
		end
	end

	table.insert(store, 1, arg)
	save()
end

--- Update an existing argument's properties (typically the active state)
--- Finds the argument by text and updates its active flag
--- Automatically persists to disk after update
--- @param arg CustomArgument The argument object with updated properties
--- @usage
---   local arg = CustomArgument.new("-X", false)  -- Deactivate the -X flag
---   arguments.update(arg)
function M.update(arg)
	_initialize_store()

	for _, v in ipairs(store) do
		if v.text == arg.text then
			v.active = arg.active
		end
	end

	save()
end

--- Remove an argument from the store
--- Finds and removes the first argument matching the given text
--- Automatically persists to disk after removal
--- @param arg CustomArgument The argument object to remove (matched by text field)
--- @usage
---   local arg = CustomArgument.new("-X", true)
---   arguments.remove(arg)
function M.remove(arg)
	_initialize_store()

	for i, v in ipairs(store) do
		if v.text == arg.text then
			table.remove(store, i)
			break
		end
	end

	save()
end

--- Get a specific argument by index
--- @param index number The 1-based index of the argument
--- @return CustomArgument|table The argument at the given index, or empty table if not found
--- @usage
---   local first_arg = arguments.get(1)
function M.get(index)
	_initialize_store()
	return store[index] or {}
end

--- Get a shallow copy of all arguments in the store
--- Returns a copy to prevent external modification of the internal store
--- @return CustomArgument[] Array of all CustomArgument objects
--- @usage
---   local all_args = arguments.list()
---   for _, arg in ipairs(all_args) do
---     print(arg.text, arg.active)
---   end
function M.list()
	_initialize_store()
	local original = store or {}
	local copy = {}
	for i, v in ipairs(original) do
		copy[i] = v
	end
	return copy
end

--- Clear all arguments from the store
--- Removes all stored arguments and persists the empty state to disk
--- Useful for resetting to a clean state
--- @usage
---   arguments.empty_store()  -- Remove all custom arguments
function M.empty_store()
	_initialize_store()
	store = {}
	save()
end

return M

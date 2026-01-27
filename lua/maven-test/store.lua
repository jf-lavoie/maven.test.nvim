local M = {}

local persistence = require("maven-test.store_persistence")
local store = {}
-- local store_loaded = false

local function _initialize_store()
	-- if store_loaded then
	-- 	return
	-- end

	-- store_loaded = true
	store = persistence.load()
	_initialize_store = function() end
end

local function save_store()
	_initialize_store()
	persistence.save(store)
end

function M.load()
	_initialize_store()
	store = persistence.load()
end

function M.add_to_store(key, value)
	_initialize_store()
	if not store[key] then
		store[key] = { value }
		save_store()
		return
	end

	for _, v in ipairs(store[key]) do
		if v == value then
			return
		end
	end

	table.insert(store[key], 1, value)
	save_store()
end

function M.remove_from_store(key, value)
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

	save_store()
end

function M.first(key)
	_initialize_store()
	if not store[key] or #store[key] == 0 then
		return nil
	end
	return store[key][1]
end

function M.get(key)
	_initialize_store()
	return store[key] or {}
end

function M.empty_store()
	_initialize_store()
	store = {}
	save_store()
end

return M

local M = {}

local persistence = require("maven-test.store.persistence").Persistence.new("store.json")
local store = {}

local function _initialize_store()
	store = persistence:load()
	_initialize_store = function() end
end

local function save()
	_initialize_store()
	persistence:save(store)
end

function M.load()
	_initialize_store()
	store = persistence:load()
end

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
	save()
end

return M

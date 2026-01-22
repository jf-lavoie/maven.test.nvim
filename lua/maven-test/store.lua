local M = {}

local persistence = require("maven-test.store_persistence")
local store = {}

local function save_store()
	persistence.save(store)
end

function M.load()
	store = persistence.load()
end

function M.add_to_store(key, value)
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
	if not store[key] or #store[key] == 0 then
		return nil
	end
	return store[key][1]
end

function M.get(key)
	return store[key] or {}
end

return M

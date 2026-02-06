local M

M = {}

local store = {}

local persistence = require("maven-test.store.persistence").Persistence.new("arguments.json")
local CustomArgument = require("maven-test.store.custom_argument").CustomArgument

local function _initialize_store()
	local data = persistence:load()

	for i, v in ipairs(data) do
		table.insert(store, i, CustomArgument.new(v.text, v.active))
	end

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

function M.update(arg)
	_initialize_store()

	for _, v in ipairs(store) do
		if v.text == arg.text then
			v.active = arg.active
		end
	end

	save()
end

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

function M.get(index)
	_initialize_store()
	return store[index] or {}
end

function M.list()
	_initialize_store()
	local original = store or {}
	local copy = {}
	for i, v in ipairs(original) do
		copy[i] = v
	end
	return copy
end

function M.empty_store()
	_initialize_store()
	store = {}
	save()
end

return M

local M

M = {}

M.Persistence = {}
M.Persistence.__index = M.Persistence

function M.Persistence.new(fileName)
	local self = setmetatable({}, M.Persistence)
	self.dataDir = require("maven-test").config.data_dir
	self.filePath = self.dataDir .. "/" .. fileName
	self.initialized = false
	return self
end

function M.Persistence:_initialize()
	if self.initialized then
		return
	end
	self.initialized = true

	vim.fn.mkdir(self.datadir, "p")
end

function M.Persistence:save(store_data)
	self:_initialize()

	local file = self.filePath
	local json = vim.fn.json_encode(store_data)

	local f = io.open(file, "w")
	if f then
		f:write(json)
		f:close()
		return true
	end
	return false
end

function M.Persistence:load()
	self:_initialize()

	local file = self.filePath

	if vim.fn.filereadable(file) == 0 then
		return {}
	end

	local f = io.open(file, "r")
	if not f then
		return {}
	end

	local content = f:read("*all")
	f:close()

	if content == "" then
		return {}
	end

	local ok, data = pcall(vim.fn.json_decode, content)
	if ok then
		return data
	end

	return {}
end

local persistence = M.Persistence.new("arguments.json")
local store = {}

M.CustomArgument = {}
M.CustomArgument.__index = M.CustomArgument

function M.CustomArgument.new(text, active)
	local self = setmetatable({}, M.CustomArgument)

	self.text = text

	self.active = active

	return self
end

function M.CustomArgument:toggle_active()
	self.active = not self.active

	return self
end

local function _initialize_store()
	local data = persistence:load()

	for i, v in ipairs(data) do
		table.insert(store, i, M.CustomArgument.new(v.text, v.active))
	end

	_initialize_store = function() end
end

local function save_store()
	_initialize_store()
	persistence:save(store)
end

function M.load()
	_initialize_store()
	store = persistence:load()
end

function M.add_to_store(arg)
	_initialize_store()

	for _, v in ipairs(store) do
		if v.text == arg.text then
			return
		end
	end

	table.insert(store, 1, arg)
	save_store()
end

function M.update(arg)
	_initialize_store()

	for _, v in ipairs(store) do
		if v.text == arg.text then
			v.active = arg.active
		end
	end

	save_store()
end

function M.remove_from_store(arg)
	_initialize_store()

	for i, v in ipairs(store) do
		if v.text == arg.text then
			table.remove(store, i)
			break
		end
	end

	save_store()
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
	save_store()
end

return M

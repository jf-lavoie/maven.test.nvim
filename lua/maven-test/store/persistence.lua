local M = {}

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

return M

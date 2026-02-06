--- Persistence layer for store data
--- Handles JSON serialization and file I/O for store data
--- Creates data directory if it doesn't exist
--- @module 'maven-test.store.persistence'

local M = {}

--- Persistence class for managing file-based storage
--- @class Persistence
--- @field dataDir string The directory where store files are saved
--- @field filePath string Full path to the store file
--- @field initialized boolean Whether the data directory has been created
M.Persistence = {}
M.Persistence.__index = M.Persistence

--- Create a new Persistence instance
--- @param fileName string Name of the file to store data in (e.g., "store.json", "arguments.json")
--- @return Persistence New persistence instance
--- @usage
---   local persistence = Persistence.new("store.json")
function M.Persistence.new(fileName)
	local self = setmetatable({}, M.Persistence)
	self.dataDir = require("maven-test").config.data_dir
	self.filePath = self.dataDir .. "/" .. fileName
	self.initialized = false
	return self
end

--- Initialize the persistence layer
--- Creates the data directory if it doesn't exist
--- Uses lazy initialization - only runs once per instance
--- @private
function M.Persistence:_initialize()
	if self.initialized then
		return
	end
	self.initialized = true

	vim.fn.mkdir(self.dataDir, "p")
end

--- Save data to the store file
--- Serializes data to JSON and writes to disk
--- Creates the data directory if it doesn't exist
--- @param store_data table The data to serialize and save
--- @return boolean True if save succeeded, false otherwise
--- @usage
---   local success = persistence:save({ key = { "value1", "value2" } })
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

--- Load data from the store file
--- Reads and deserializes JSON from disk
--- Returns empty table on any error (file not found, invalid JSON, etc.)
--- @return table The deserialized data, or empty table if file doesn't exist or is invalid
--- @usage
---   local data = persistence:load()
---   if data.key then
---     print("Found key:", vim.inspect(data.key))
---   end
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

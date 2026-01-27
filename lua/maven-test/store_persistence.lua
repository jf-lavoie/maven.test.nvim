local M = {}

M.data_dir = nil

local initialized = false

local function get_store_file()
	return M.data_dir .. "/store.json"
end

local function _initialize()
	if initialized then
		return
	end
	initialized = true

	vim.fn.mkdir(M.data_dir, "p")
end

function M.setup(data_dir)
	M.data_dir = data_dir
end

function M.save(store_data)
	_initialize()

	local file = get_store_file()
	local json = vim.fn.json_encode(store_data)

	local f = io.open(file, "w")
	if f then
		f:write(json)
		f:close()
		return true
	end
	return false
end

function M.load()
	_initialize()

	local file = get_store_file()

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

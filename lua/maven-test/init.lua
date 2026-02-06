if vim.g.loaded_maven_test then
	return
end

local M = {}

local function get_project_name()
	local cwd = vim.fn.getcwd()
	return vim.fn.fnamemodify(cwd, ":t")
end

local function get_store_dir()
	local project_name = get_project_name()
	local data_dir = vim.fn.stdpath("data")
	return data_dir .. "/maven.nvim.test/" .. project_name
end

M.config = {
	maven_command = "mvn",
	floating_window = {
		width = 0.8,
		height = 0.6,
		border = "rounded",
	},
	debug_port = 5005,
	data_dir = get_store_dir(),
}

function M.setup(opts)
	if vim.g.loaded_maven_test == 1 then
		return
	end

	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	require("maven-test.store.persistence").setup(M.config.data_dir)
	require("maven-test.commands")

	vim.g.loaded_maven_test = 1
end

return M

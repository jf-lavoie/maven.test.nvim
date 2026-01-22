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
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	require("maven-test.store_persistence").initialize(M.config.data_dir)
	require("maven-test.store").load()

	require("maven-test.commands").register()
	require("maven-test.functions").register(M.config)
end

return M

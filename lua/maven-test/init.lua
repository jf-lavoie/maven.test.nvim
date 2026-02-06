--- Maven test plugin initialization module
--- Handles plugin setup, configuration, and guard against multiple loads
--- @module 'maven-test'

if vim.g.loaded_maven_test then
	return
end

local M = {}

--- Get the current project name from the working directory
--- @return string The project name (last component of cwd path)
--- @private
local function get_project_name()
	local cwd = vim.fn.getcwd()
	return vim.fn.fnamemodify(cwd, ":t")
end

--- Get the store directory path for the current project
--- @return string Full path to the store directory
--- @private
local function get_store_dir()
	local project_name = get_project_name()
	local data_dir = vim.fn.stdpath("data")
	return data_dir .. "/maven.nvim.test/" .. project_name
end

--- Default configuration
--- @class MavenTestConfig
--- @field maven_command string The Maven command to use (default: "mvn")
--- @field floating_window table Floating window configuration
--- @field floating_window.width number Window width as fraction of editor width (default: 0.8)
--- @field floating_window.height number Window height as fraction of editor height (default: 0.6)
--- @field floating_window.border string Border style (default: "rounded")
--- @field debug_port number Port for Maven Surefire debug mode (default: 5005)
--- @field data_dir string Directory for storing command data (auto-generated per project)
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

--- Setup the maven-test plugin
--- Merges user configuration with defaults and registers commands
--- Safe to call multiple times - will only initialize once
--- @param opts? MavenTestConfig User configuration to override defaults
--- @usage
---   require('maven-test').setup({
---     maven_command = "mvn",
---     debug_port = 5005,
---     floating_window = { width = 0.8, height = 0.6, border = "rounded" }
---   })
function M.setup(opts)
	if vim.g.loaded_maven_test == 1 then
		return
	end

	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	require("maven-test.user_commands")

	vim.g.loaded_maven_test = 1
end

return M

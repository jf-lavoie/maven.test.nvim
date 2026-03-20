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
--- @field projects table Project detection configuration for different build systems
--- @field projects.maven table Maven project configuration
--- @field projects.maven.root_markers string[] Files indicating a Maven project root (default: {"pom.xml"})
--- @field projects.maven.type string Project language type (default: "java")
--- @field projects.gradle table Gradle project configuration
--- @field projects.gradle.root_markers string[] Files indicating a Gradle project root
--- @field projects.gradle.type string Project language type (default: "java")
--- @field projects.go table Go project configuration
--- @field projects.go.root_markers string[] Files indicating a Go project root (default: {"go.mod"})
--- @field projects.go.type string Project language type (default: "go")
M.config = {
	maven_command = "mvn",
	floating_window = {
		width = 0.8,
		height = 0.6,
		border = "rounded",
	},
	debug_port = 5005,
	data_dir = get_store_dir(),
	projects = {
		maven = {
			root_markers = { "pom.xml" },
			pattern = "java",
			test_commands = { "mvn test" },
			test_file_commands = { "mvn test -Dtest=%s" },
			test_method_commands = { "mvn test -Dtest=%s#%s" },
			commands = {
				"mvn site",
				"mvn clean",
				"mvn deploy",
				"mvn install",
				"mvn verify",
				"mvn package",
				"mvn test",
				"mvn compile",
				"mvn validate",
			},
		},

		gradle = {
			root_markers = { "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" },
			pattern = "java",
			test_commands = { "gradle test" },
			test_file_commands = { "gradle test --tests %s" },
			test_method_commands = { "gradle test --tests %s.%s" },
		},

		go = {
			root_markers = { "go.mod" },
			pattern = "go",
			test_commands = { "go test ./..." },
			test_file_commands = { "go test %s" },
			test_method_commands = { "go test -run ^%s$ %s" },
		},

		lua = {
			root_markers = { "plugin/init.lua", "init.lua", "main.lua" },
			pattern = "lua",
			test_commands = { "lua test" },
			test_file_commands = { "lua test %s" },
			test_method_commands = { "lua test %s -m %s" },
		},
	},
}

M.ProjectConfig = {}
M.ProjectConfig.__index = M.ProjectConfig

function M.ProjectConfig:new(project_type, configuration)
	local project = setmetatable(vim.tbl_extend("force", { type = project_type }, configuration), self)

	return project
end

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

	local detector = require("maven-test.project.detector")
	local detected_projects = detector.detect_project_type(M.config.projects)

	local projectConfigs = {}

	if #detected_projects > 0 then
		for _, root in ipairs(detected_projects) do
			local project_type = root[1]
			local path = root[2]
			vim.notify("maven-test: " .. project_type .. " at " .. path, vim.log.levels.INFO)

			table.insert(projectConfigs, M.ProjectConfig:new(project_type, M.config.projects[project_type]))
		end
	else
		vim.notify("maven-test: No projects detected", vim.log.levels.INFO)
	end

	require("maven-test.user_commands").register_commands(projectConfigs)

	vim.g.loaded_maven_test = 1
end

return M

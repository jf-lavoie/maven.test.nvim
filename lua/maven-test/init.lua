--- Maven test plugin initialization module
--- Handles plugin setup, configuration, project detection, and load guards
--- Supports Maven, Gradle, Go, and Lua project types
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
--- @field floating_window table Floating window configuration for UI elements
--- @field floating_window.width number Window width as fraction of editor width (default: 0.8)
--- @field floating_window.height number Window height as fraction of editor height (default: 0.6)
--- @field floating_window.border string Border style: "rounded", "single", "double", "solid", "none" (default: "rounded")
--- @field debug_port number Port for remote debugging (Maven Surefire, etc.) (default: 5005)
--- @field data_dir string Directory for storing command data (auto-generated per project in stdpath("data"))
--- @field projects table Project detection and configuration for different build systems
--- @field projects.maven table Maven project configuration
--- @field projects.maven.root_markers string[] Files indicating a Maven project root (default: {"pom.xml"})
--- @field projects.maven.pattern string File pattern for project type detection (default: "java")
--- @field projects.maven.test_commands string[] Default commands for running all tests
--- @field projects.maven.test_file_commands string[] Command templates for running test class (placeholders: {package}, {class})
--- @field projects.maven.test_method_commands string[] Command templates for running test method (placeholders: {package}, {class}, {method})
--- @field projects.maven.commands string[] Maven lifecycle commands for command UI
--- @field projects.gradle table Gradle project configuration
--- @field projects.gradle.root_markers string[] Files indicating a Gradle project root
--- @field projects.gradle.pattern string File pattern for project type detection (default: "java")
--- @field projects.gradle.test_commands string[] Default commands for running all tests
--- @field projects.gradle.test_file_commands string[] Command templates for running test class
--- @field projects.gradle.test_method_commands string[] Command templates for running test method
--- @field projects.go table Go project configuration
--- @field projects.go.root_markers string[] Files indicating a Go project root (default: {"go.mod"})
--- @field projects.go.pattern string File pattern for project type detection (default: "go")
--- @field projects.go.test_commands string[] Default commands for running all tests
--- @field projects.go.test_file_commands string[] Command templates for running test file
--- @field projects.go.test_method_commands string[] Command templates for running test function
--- @field projects.lua table Lua project configuration
--- @field projects.lua.root_markers string[] Files indicating a Lua project root
--- @field projects.lua.pattern string File pattern for project type detection (default: "lua")
--- @field projects.lua.test_commands string[] Default commands for running all tests
--- @field projects.lua.test_file_commands string[] Command templates for running test file
--- @field projects.lua.test_method_commands string[] Command templates for running test case
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
			test_file_commands = { "mvn test -Dtest={package}.{class}" },
			test_method_commands = { "mvn test -Dtest={package}.{class}#{method}" },
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
			test_file_commands = { "gradle test --tests {package}.{class}" },
			test_method_commands = { "gradle test --tests {package}.{class}#{method}" },
		},

		go = {
			root_markers = { "go.mod" },
			pattern = "go",
			test_commands = { "go test ./..." },
			test_file_commands = { "go test -run . {dirname}" },
			test_method_commands = { "go test ./... -run ^{method}$" },
			commands = {
				"go build ./...",
			},
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

--- ProjectConfig class for managing detected project configurations
--- @class ProjectConfig
--- @field type string The project type (e.g., "maven", "gradle", "go", "lua")
--- @field root_markers string[] Files that indicate project root
--- @field pattern string File pattern for project detection
--- @field test_commands string[] Commands for running all tests
--- @field test_file_commands string[] Command templates for running test file/class
--- @field test_method_commands string[] Command templates for running test method/function
--- @field commands string[]? Optional list of common project commands (e.g., Maven lifecycle)
M.ProjectConfig = {}
M.ProjectConfig.__index = M.ProjectConfig

--- Create a new ProjectConfig instance
--- @param project_type string The type of project (e.g., "maven", "gradle")
--- @param configuration table Configuration for this project type from M.config.projects
--- @return ProjectConfig A new ProjectConfig instance
function M.ProjectConfig:new(project_type, configuration)
	local project = setmetatable(vim.tbl_extend("force", { type = project_type }, configuration), self)

	return project
end

--- Setup the maven-test plugin
--- Detects project type(s), merges user configuration with defaults, and registers user commands
--- Safe to call multiple times - will only initialize once (checks vim.g.loaded_maven_test)
--- Supports multiple project types in the same workspace
--- @param opts? MavenTestConfig User configuration to override defaults
--- @usage
---   require('maven-test').setup({
---     maven_command = "mvn",
---     debug_port = 5005,
---     floating_window = { width = 0.8, height = 0.6, border = "rounded" },
---     projects = {
---       maven = { root_markers = { "pom.xml" } }
---     }
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

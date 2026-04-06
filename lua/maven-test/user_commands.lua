--- User command registration module
--- Registers buffer-local commands via FileType autocmd for detected project types
--- Commands are only available in relevant file buffers (e.g., Java, Go, Lua) for better performance
--- Supports multiple project types through dynamic pattern matching
--- @module 'maven-test.user_commands'

--- Ensure the plugin is loaded before executing commands
--- Calls setup() if the plugin hasn't been initialized yet
--- @private
local function ensure_loaded()
	if vim.g.loaded_maven_test ~= 1 then
		require("maven-test").setup()
	end
end

local M = {}

--- Register user commands for all detected project configurations
--- Creates FileType autocmds for each project type and registers buffer-local commands
--- Commands registered:
---   - MavenTest: Opens UI to select and run a test method
---   - MavenTestClass: Runs all tests in the current class/file
---   - MavenTestAll: Runs all tests in the project
---   - MavenTestCommands: Opens UI to view, edit, and run stored Maven commands
---   - MavenTestCustomArguments: Opens UI to manage custom Maven arguments
---   - MavenTestRestoreCommandsStore: Restores command store to default state
---   - MavenTestRestoreArgumentStore: Restores argument store to default state
--- @param projectConfigs ProjectConfig[] List of detected project configurations
--- @usage
---   local configs = { ProjectConfig:new("maven", {...}), ProjectConfig:new("gradle", {...}) }
---   register_commands(configs)
M.register_commands = function(projectConfigs)
	for _, projectConfig in ipairs(projectConfigs) do
		local pattern = projectConfig.pattern
		-- Register FileType autocmd to create buffer-local commands for project-specific files
		-- Pattern is determined by project type (e.g., "java" for Maven/Gradle, "go" for Go projects)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = pattern,
			group = vim.api.nvim_create_augroup("MavenTest" .. pattern, { clear = true }),
			callback = function(args)
				-- Test execution commands
				vim.api.nvim_buf_create_user_command(args.buf, "MavenTest", function()
					ensure_loaded()
					require("maven-test.functions").run_test(projectConfig)
				end, { desc = "Open test method picker and run selected test" })

				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestClass", function()
					ensure_loaded()
					require("maven-test.functions").run_test_class(projectConfig)
				end, { desc = "Run all tests in the current class/file" })

				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestAll", function()
					ensure_loaded()
					require("maven-test.functions").run_all_tests(projectConfig)
				end, { desc = "Run all tests in the project" })

				-- Management commands
				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestRestoreCommandsStore", function()
					ensure_loaded()
					require("maven-test.functions").restore_commands_store(projectConfig)
				end, { desc = "Restore command store to default configuration" })

				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestCommands", function()
					ensure_loaded()
					require("maven-test.functions").commands(projectConfig)
				end, { desc = "Show stored Maven commands UI (view, edit, delete, run)" })

				-- Argument management commands
				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestCustomArguments", function()
					ensure_loaded()
					require("maven-test.functions").show_custom_arguments(projectConfig)
				end, { desc = "Manage custom Maven arguments (add, edit, toggle, delete)" })

				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestRestoreArgumentStore", function()
					ensure_loaded()
					require("maven-test.functions").restore_arguments_store(projectConfig)
				end, { desc = "Restore argument store to default configuration" })
			end,
		})
	end
end

return M

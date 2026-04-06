--- User command registration module
--- Registers buffer-local commands for Java files via FileType autocmd
--- Commands are only available in Java buffers for better performance
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

M.register_commands = function(projectConfigs)
	for _, projectConfig in ipairs(projectConfigs) do
		local pattern = projectConfig.pattern
		-- Register FileType autocmd to create buffer-local commands for Java files
		vim.api.nvim_create_autocmd("FileType", {
			pattern = pattern,
			group = vim.api.nvim_create_augroup("MavenTest" .. pattern, { clear = true }),
			callback = function(args)
				-- Test execution commands
				vim.api.nvim_buf_create_user_command(args.buf, "MavenTest", function()
					ensure_loaded()
					require("maven-test.functions").run_test(projectConfig)
				end, { desc = "Test method picker" })

				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestClass", function()
					ensure_loaded()
					require("maven-test.functions").run_test_class(projectConfig)
				end, { desc = "Run all tests in the current Java class" })

				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestAll", function()
					ensure_loaded()
					require("maven-test.functions").run_all_tests(projectConfig)
				end, { desc = "Run all tests in the current Java class" })

				-- Management commands
				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestRestoreCommandsStore", function()
					ensure_loaded()
					require("maven-test.functions").restore_commands_store(projectConfig)
				end, { desc = "Restore stored commands" })

				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestCommands", function()
					ensure_loaded()
					require("maven-test.functions").commands(projectConfig)
				end, { desc = "Show commands" })

				-- Management arguments
				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestCustomArguments", function()
					ensure_loaded()
					require("maven-test.functions").show_custom_arguments(projectConfig)
				end, { desc = "Show custom arguments" })

				vim.api.nvim_buf_create_user_command(args.buf, "MavenTestRestoreArgumentStore", function()
					ensure_loaded()
					require("maven-test.functions").restore_arguments_store(projectConfig)
				end, { desc = "Restore stored commands" })
			end,
		})
	end
end

return M

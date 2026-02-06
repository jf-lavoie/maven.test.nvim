local function ensure_loaded()
	if vim.g.loaded_maven_test ~= 1 then
		require("maven-test").setup()
	end
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "java",
	group = vim.api.nvim_create_augroup("MavenTestJava", { clear = true }),
	callback = function(args)
		-- Buffer-local commands
		vim.api.nvim_buf_create_user_command(args.buf, "MavenTest", function()
			ensure_loaded()
			require("maven-test.functions").run_test()
		end, { desc = "Test method picker" })
		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestClass", function()
			ensure_loaded()
			require("maven-test.functions").run_test_class()
		end, { desc = "Run all tests in the current Java class" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestAll", function()
			ensure_loaded()
			require("maven-test.functions").run_all_tests()
		end, { desc = "Run all tests in the current Java class" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestDebug", function()
			ensure_loaded()
			require("maven-test.functions").run_test_debug()
		end, { desc = "Test method picker (debug mode)" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestClassDebug", function()
			ensure_loaded()
			require("maven-test.functions").run_test_class_debug()
		end, { desc = "Run all tests in the current Java class (debug mode)" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestAllDebug", function()
			ensure_loaded()
			require("maven-test.functions").run_all_tests_debug()
		end, { desc = "Run all tests (debug mode)" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestRestoreCommandsStore", function()
			ensure_loaded()
			require("maven-test.functions").restore_store()
		end, { desc = "Restore stored commands" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestCommands", function()
			ensure_loaded()
			require("maven-test.functions").commands()
		end, { desc = "Show commands" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestCustomArguments", function()
			ensure_loaded()
			require("maven-test.functions").show_custom_arguments()
		end, { desc = "Show custom arguments" })

		-- ... other commands
	end,
})

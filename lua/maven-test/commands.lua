vim.api.nvim_create_autocmd("FileType", {
	pattern = "java",
	group = vim.api.nvim_create_augroup("MavenTestJava", { clear = true }),
	callback = function(args)
		local functions = require("maven-test.functions")
		-- Buffer-local commands
		vim.api.nvim_buf_create_user_command(args.buf, "MavenTest", function()
			functions.run_test()
		end, { desc = "Test method picker" })
		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestClass", function()
			functions.run_test_class()
		end, { desc = "Run all tests in the current Java class" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestAll", function()
			functions.run_all_tests()
		end, { desc = "Run all tests in the current Java class" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestDebug", function()
			functions.run_test_debug()
		end, { desc = "Test method picker (debug mode)" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestClassDebug", function()
			functions.run_test_class_debug()
		end, { desc = "Run all tests in the current Java class (debug mode)" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestAllDebug", function()
			functions.run_all_tests_debug()
		end, { desc = "Run all tests (debug mode)" })

		vim.api.nvim_buf_create_user_command(args.buf, "MavenTestRestoreCommandsStore", function()
			functions.restore_store()
		end, { desc = "Restore stored commands" })

		-- ... other commands
	end,
})

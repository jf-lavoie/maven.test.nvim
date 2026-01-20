local functions = require("maven-test.functions")

local M = {}

function M.register()
	vim.api.nvim_create_user_command("MavenTest", function()
		functions.run_test()
	end, { desc = "Test method picker" })

	vim.api.nvim_create_user_command("MavenTestClass", function()
		functions.run_test_class()
	end, { desc = "Run all tests in the current Java class" })

	vim.api.nvim_create_user_command("MavenTestAll", function()
		functions.run_all_tests()
	end, { desc = "Run all tests in the current Java class" })

	vim.api.nvim_create_user_command("MavenTestDebug", function()
		functions.run_test_debug()
	end, { desc = "Test method picker (debug mode)" })

	vim.api.nvim_create_user_command("MavenTestClassDebug", function()
		functions.run_test_class_debug()
	end, { desc = "Run all tests in the current Java class (debug mode)" })

	vim.api.nvim_create_user_command("MavenTestAllDebug", function()
		functions.run_all_tests_debug()
	end, { desc = "Run all tests (debug mode)" })
end

return M

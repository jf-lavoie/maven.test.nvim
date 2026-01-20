local M = {}
function M.run_test()
	require("maven-test.ui").show_test_selector(false)
end

function M.run_test_class()
	require("maven-test.runner").run_test_class(false)
end

function M.run_all_tests()
	require("maven-test.runner").run_all_tests(false)
end

function M.run_test_debug()
	require("maven-test.ui").show_test_selector(true)
end

function M.run_test_class_debug()
	require("maven-test.runner").run_test_class(true)
end

function M.run_all_tests_debug()
	require("maven-test.runner").run_all_tests(true)
end

return M

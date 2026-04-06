local M = {}

M.get_package_name = function(pattern)
	return require("maven-test.tests.parsers." .. pattern).get_package_name()
end

M.get_test_class = function(pattern)
	return require("maven-test.tests.parsers." .. pattern).get_test_class()
end

M.get_test_methods = function(pattern)
	return require("maven-test.tests.parsers." .. pattern).get_test_methods()
end

return M

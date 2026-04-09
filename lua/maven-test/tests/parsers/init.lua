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

M.get_fully_qualified_test_method_names = function(pattern)
	return require("maven-test.tests.parsers." .. pattern).get_fully_qualified_test_method_names()
end

M.get_test_file_name = function(pattern)
	return require("maven-test.tests.parsers." .. pattern).get_test_file_name()
end

return M

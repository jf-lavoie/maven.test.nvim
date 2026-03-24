local M = {}

M.get_package_name = function(type)
	return require("maven-test.tests.parsers." .. type).get_package_name()
end

M.get_test_class = function(type)
	return require("maven-test.tests.parsers." .. type).get_test_class()
end

M.get_test_methods = function(type)
	return require("maven-test.tests.parsers." .. type).get_test_methods()
end

return M

--- Parser dispatcher module for language-specific test detection
--- Routes parser calls to the appropriate language implementation (Java or Go)
--- based on the provided pattern parameter
--- @module 'maven-test.tests.parsers'
local M = {}

--- Get the package name from the current buffer
--- Delegates to language-specific parser (java or go)
--- @param pattern string Language identifier ("java" or "go")
--- @return string The package name (e.g., "com.example.myapp" for Java, "github.com/user/pkg" for Go)
M.get_package_name = function(pattern)
	return require("maven-test.tests.parsers." .. pattern).get_package_name()
end

--- Get the test class information from the current buffer
--- Delegates to language-specific parser (java or go)
--- @param pattern string Language identifier ("java" or "go")
--- @return table Class object with { name: string, line: number }
M.get_test_class = function(pattern)
	return require("maven-test.tests.parsers." .. pattern).get_test_class()
end

--- Get all test methods/functions in the current buffer
--- Delegates to language-specific parser (java or go)
--- @param pattern string Language identifier ("java" or "go")
--- @return table[] Array of test objects, each with { name: string, line: number, type: string, is_current: boolean }
M.get_test_methods = function(pattern)
	return require("maven-test.tests.parsers." .. pattern).get_test_methods()
end

--- Get fully qualified test method names for all tests in the current buffer
--- Delegates to language-specific parser (java or go)
--- @param pattern string Language identifier ("java" or "go")
--- @return JavaFullyQualifiedMethodName[]|GoFullyQualifiedMethodName[]|nil Array of fully qualified method name objects, or nil if package/class not found
M.get_fully_qualified_test_method_names = function(pattern)
	return require("maven-test.tests.parsers." .. pattern).get_fully_qualified_test_method_names()
end

--- Get the test file name from the current buffer
--- Delegates to language-specific parser (java or go)
--- @param pattern string Language identifier ("java" or "go")
--- @return JavaFullyQualifiedClassName|GoFullyQualifiedFileName|nil The fully qualified file/class name object, or nil if package/class not found
M.get_test_file_name = function(pattern)
	return require("maven-test.tests.parsers." .. pattern).get_test_file_name()
end

return M

--- Parser dispatcher module for language-specific test detection
--- Routes parser calls to the appropriate language implementation (Java or Go)
--- based on the provided filetype parameter
--- @module 'maven-test.tests.parsers'
local M = {}

--- Get the package name from the current buffer
--- Delegates to language-specific parser (java or go)
--- @param filetype string Language identifier ("java" or "go")
--- @return string|nil The package name (e.g., "com.example.myapp" for Java, "mypackage" for Go), or nil if not found
function M.get_package_name(filetype)
	return require("maven-test.tests.parsers." .. filetype).get_package_name()
end

--- Get the test class information from the current buffer
--- Delegates to language-specific parser (java or go)
--- Note: For Go, returns empty placeholder { name = "", line = -1 }
--- @param filetype string Language identifier ("java" or "go")
--- @return table Class object with fields: name (string), line (number)
function M.get_test_class(filetype)
	return require("maven-test.tests.parsers." .. filetype).get_test_class()
end

--- Get all test methods/functions in the current buffer
--- Delegates to language-specific parser (java or go)
--- @param filetype string Language identifier ("java" or "go")
--- @return table[] Array of test objects, each with fields: name (string), line (number), is_current (boolean)
function M.get_test_methods(filetype)
	return require("maven-test.tests.parsers." .. filetype).get_test_methods()
end

--- Get fully qualified test method names for all tests in the current buffer
--- Delegates to language-specific parser (java or go)
--- Reorders results to place the test under cursor at the top of the list
--- @param filetype string Language identifier ("java" or "go")
--- @return JavaFullyQualifiedMethodName[]|GoFullyQualifiedMethodName[]|nil Array of fully qualified method name objects with current test first, or nil if package/class not found
function M.get_fully_qualified_test_method_names(filetype)
	local fqnmn = require("maven-test.tests.parsers." .. filetype).get_fully_qualified_test_method_names()

	for i, met in ipairs(fqnmn) do
		if met.method.is_current then
			-- Move current test to the top of the list
			table.remove(fqnmn, i)
			table.insert(fqnmn, 1, met)
			break
		end
	end

	return fqnmn
end

--- Get the test file name from the current buffer
--- Delegates to language-specific parser (java or go)
--- @param filetype string Language identifier ("java" or "go")
--- @return JavaFullyQualifiedClassName[]|GoFullyQualifiedFileName[]|nil Array containing fully qualified file/class name object, or nil if package/class not found
function M.get_test_file_name(filetype)
	return require("maven-test.tests.parsers." .. filetype).get_test_file_name()
end

--- Get the project-level fully qualified name
--- Returns a ProjectFullyQualifiedName for project-wide commands
--- @return ProjectFullyQualifiedName[] Array containing a single project fully qualified name object
function M.get_project_fully_qualified_name()
	return { require("maven-test.tests.parsers.FullyQualifiedNames").ProjectFullyQualifiedName.new() }
end

return M

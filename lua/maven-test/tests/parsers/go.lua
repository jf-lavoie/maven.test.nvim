--- Go test parser using Treesitter
--- Detects test functions in Go files using treesitter queries
--- Supports standard Go testing functions (Test*, Benchmark*, Example*, Fuzz*)
--- @module 'maven-test.tests.parsers.go'

local M = {}

--- Get the "test class" for Go files
--- Go doesn't have classes, so this returns an empty placeholder object
--- This provides interface compatibility with Java parser for the test runner
--- @return table A class object with: { name: string (empty), line: number (-1) }
--- @usage
---   local class = parser.get_test_class()
---   -- Returns { name = "", line = -1 } for Go files
function M.get_test_class()
	return {
		name = "",
		line = -1,
	}
end

--- Get all test functions in the current buffer
--- Searches for functions with names starting with Test, Benchmark, Example, or Fuzz
--- @return table[] Array of test objects, each with: { name: string, line: number, type: "function", is_current: boolean }
--- @usage
---   local tests = parser.get_test_methods()
---   for _, test in ipairs(tests) do
---     print(test.name .. " at line " .. test.line .. (test.is_current and " (current)" or ""))
---   end
function M.get_test_methods()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	local parser = vim.treesitter.get_parser(bufnr, "go")
	if not parser then
		return {}
	end

	local tree = parser:parse()[1]
	local root = tree:root()
	local tests = {}

	-- Query for test functions (Test*, Benchmark*, Example*, Fuzz*)
	local query = vim.treesitter.query.parse(
		"go",
		[[
    (function_declaration
      name: (identifier) @func.name
      (#match? @func.name "^(Test|Benchmark|Example|Fuzz)")) @func
  ]]
	)

	local seen_functions = {}
	for id, node in query:iter_captures(root, bufnr, 0, -1) do
		local name = query.captures[id]
		if name == "func.name" then
			local func_name = vim.treesitter.get_node_text(node, bufnr)
			if func_name and not seen_functions[func_name] then
				seen_functions[func_name] = true
				-- Get the parent function_declaration node to determine cursor position
				local parent = node:parent()
				local func_start_row, _, func_end_row, _ = parent:range()
				local is_current = cursor_line >= (func_start_row + 1) and cursor_line <= (func_end_row + 1)
				table.insert(tests, {
					name = func_name,
					line = func_start_row + 1,
					-- type = "function",
					is_current = is_current,
				})
			end
		end
	end

	return tests
end

--- Get the package name from the current Go file
--- Uses treesitter to find the package declaration
--- @return string|nil The package name (e.g., "main", "mypackage"), or nil if not found
--- @usage
---   local pkg = parser.get_package_name()
---   if pkg then
---     print("Package: " .. pkg)
---   end
function M.get_package_name()
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr, "go")
	if not parser then
		return nil
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	-- Query for package declaration
	local query = vim.treesitter.query.parse(
		"go",
		[[
    (package_clause
      (package_identifier) @package.name)
  ]]
	)

	for id, node in query:iter_captures(root, bufnr, 0, -1) do
		local name = query.captures[id]
		if name == "package.name" then
			return vim.treesitter.get_node_text(node, bufnr)
		end
	end

	return nil
end

--- --- Get the file name without extension
--- --- This is used as a substitute for "class" in Go since Go doesn't have classes
--- --- @return string|nil The file name without extension, or nil if not available
--- --- @usage
--- ---   local file = parser.get_file_name()
--- function M.get_file_name()
--- 	return vim.fn.expand("%:t:r")
--- end

--- Get fully qualified test method names for all test functions in the current buffer
--- Creates GoFullyQualifiedMethodName objects containing package, file path, and method info
--- @return GoFullyQualifiedMethodName[]? Array of fully qualified method name objects, or nil if package not found
--- @usage
---   local fqn_list = parser.get_fully_qualified_test_method_names()
---   if fqn_list then
---     for _, fqn in ipairs(fqn_list) do
---       print(fqn:fullyQualifiedMethodName())
---     end
---   end
function M.get_fully_qualified_test_method_names()
	local FullyQualifiedName = require("maven-test.tests.parsers.FullyQualifiedNames")
	local GoFullyQualifiedMethodName = FullyQualifiedName.GoFullyQualifiedMethodName
	local fqn_list = {}

	local package_name = M.get_package_name()
	if not package_name then
		return nil
	end

	local package_ = FullyQualifiedName.Package.new(package_name)

	local methods = M.get_test_methods()

	for _, method in ipairs(methods) do
		table.insert(
			fqn_list,
			GoFullyQualifiedMethodName.new(
				package_,
				vim.api.nvim_buf_get_name(0),
				FullyQualifiedName.Method.new(method.name, method.line, method.is_current)
			)
		)
	end

	return fqn_list
end

--- Get the fully qualified file name for the current Go test file
--- Creates a GoFullyQualifiedFileName object containing package and file path
--- @return GoFullyQualifiedFileName? The fully qualified file name object, or nil if package not found
--- @usage
---   local fqn_file = parser.get_test_file_name()
---   if fqn_file then
---     print("Package file: " .. fqn_file:fullyQualifiedFileName())
---   end
M.get_test_file_name = function()
	local FullyQualifiedName = require("maven-test.tests.parsers.FullyQualifiedNames")
	local GoFullyQualifiedFileName = FullyQualifiedName.GoFullyQualifiedFileName

	local package_name = M.get_package_name()
	if not package_name then
		return nil
	end
	local package_ = FullyQualifiedName.Package.new(package_name)

	return GoFullyQualifiedFileName.new(package_, vim.api.nvim_buf_get_name(0))
end

return M

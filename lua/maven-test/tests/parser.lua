--- Java test parser using Treesitter
--- Detects test methods and classes in Java files using treesitter queries
--- Supports @Test and @ArchTest annotations
--- @module maven-test.tests.parser

local M = {}

--- Get all test methods in the current buffer
--- Searches for methods annotated with @Test or @ArchTest
--- Also finds @ArchTest annotated fields (ArchUnit test rules)
--- @return table[] Array of test objects, each with: { name: string, line: number, type: "method" }
--- @usage
---   local tests = parser.get_test_methods()
---   for _, test in ipairs(tests) do
---     print(test.name .. " at line " .. test.line)
---   end
function M.get_test_methods()
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr, "java")
	if not parser then
		return {}
	end

	local tree = parser:parse()[1]
	local root = tree:root()
	local tests = {}

	-- Query for @Test annotation on methods
	local query = vim.treesitter.query.parse(
		"java",
		[[
    (method_declaration
      (modifiers
        (marker_annotation
          name: (identifier) @annotation (#eq? @annotation "Test")))
      name: (identifier) @method.name) @method
  ]]
	)

	for id, node in query:iter_captures(root, bufnr, 0, -1) do
		local name = query.captures[id]
		if name == "method.name" then
			local method_name = vim.treesitter.get_node_text(node, bufnr)
			local start_row, _, _, _ = node:range()
			table.insert(tests, {
				name = method_name,
				line = start_row + 1,
				type = "method",
			})
		end
	end

	-- Query for @ArchTest annotation on methods
	local query_archtest = vim.treesitter.query.parse(
		"java",
		[[
    (method_declaration
      (modifiers
        (marker_annotation
          name: (identifier) @annotation (#eq? @annotation "ArchTest")))
      name: (identifier) @method.name) @method
  ]]
	)

	for id, node in query_archtest:iter_captures(root, bufnr, 0, -1) do
		local name = query_archtest.captures[id]
		if name == "method.name" then
			local method_name = vim.treesitter.get_node_text(node, bufnr)
			local start_row, _, _, _ = node:range()
			table.insert(tests, {
				name = method_name,
				line = start_row + 1,
				type = "method",
			})
		end
	end

	-- Query for @ArchTest annotation on field declarations
	local query_archtest_field = vim.treesitter.query.parse(
		"java",
		[[
    (field_declaration
      (modifiers
        (marker_annotation
          name: (identifier) @annotation (#eq? @annotation "ArchTest")))
      declarator: (variable_declarator
        name: (identifier) @field.name)) @field
  ]]
	)

	for id, node in query_archtest_field:iter_captures(root, bufnr, 0, -1) do
		local name = query_archtest_field.captures[id]
		if name == "field.name" then
			local field_name = vim.treesitter.get_node_text(node, bufnr)
			local start_row, _, _, _ = node:range()
			table.insert(tests, {
				name = field_name,
				line = start_row + 1,
				type = "method", -- Note: fields are also marked as "method" for consistency
			})
		end
	end

	return tests
end

--- Get the test class name from the current buffer
--- Extracts the first class declaration found in the file
--- @return table|nil Class object with: { name: string, line: number, type: "class" }, or nil if not found
--- @usage
---   local class = parser.get_test_class()
---   if class then
---     print("Class: " .. class.name)
---   end
function M.get_test_class()
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr, "java")
	if not parser then
		return nil
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"java",
		[[
    (class_declaration
      name: (identifier) @class.name)
  ]]
	)

	for id, node in query:iter_captures(root, bufnr, 0, -1) do
		local name = query.captures[id]
		if name == "class.name" then
			local class_name = vim.treesitter.get_node_text(node, bufnr)
			local start_row, _, _, _ = node:range()
			return {
				name = class_name,
				line = start_row + 1,
				type = "class",
			}
		end
	end

	return nil
end

return M

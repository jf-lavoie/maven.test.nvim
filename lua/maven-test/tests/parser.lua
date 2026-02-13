--- Java test parser using Treesitter
--- Detects test methods and classes in Java files using treesitter queries
--- Supports @Test and @ArchTest annotations
--- @module 'maven-test.tests.parser'

local M = {}

--- Get all test methods in the current buffer
--- Searches for methods annotated with @Test or @ArchTest
--- Also finds @ArchTest annotated fields (ArchUnit test rules)
--- @return table[] Array of test objects, each with: { name: string, line: number, type: "method", is_current: boolean }
--- @usage
---   local tests = parser.get_test_methods()
---   for _, test in ipairs(tests) do
---     print(test.name .. " at line " .. test.line .. (test.is_current and " (current)" or ""))
---   end
function M.get_test_methods()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
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

	local seen_methods = {}
	for id, node in query:iter_captures(root, bufnr, 0, -1) do
		local name = query.captures[id]
		if name == "method" then
			-- Get the method name from the node
			local method_name = nil
			for child in node:iter_children() do
				if child:type() == "identifier" then
					method_name = vim.treesitter.get_node_text(child, bufnr)
					break
				end
			end

			if method_name and not seen_methods[method_name] then
				seen_methods[method_name] = true
				local method_start_row, _, method_end_row, _ = node:range()
				local is_current = cursor_line >= (method_start_row + 1) and cursor_line <= (method_end_row + 1)
				table.insert(tests, {
					name = method_name,
					line = method_start_row + 1,
					type = "method",
					is_current = is_current,
				})
			end
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

	local seen_archtest_methods = {}
	for id, node in query_archtest:iter_captures(root, bufnr, 0, -1) do
		local name = query_archtest.captures[id]
		if name == "method" then
			-- Get the method name from the node
			local method_name = nil
			for child in node:iter_children() do
				if child:type() == "identifier" then
					method_name = vim.treesitter.get_node_text(child, bufnr)
					break
				end
			end

			if method_name and not seen_archtest_methods[method_name] then
				seen_archtest_methods[method_name] = true
				local method_start_row, _, method_end_row, _ = node:range()
				local is_current = cursor_line >= (method_start_row + 1) and cursor_line <= (method_end_row + 1)
				table.insert(tests, {
					name = method_name,
					line = method_start_row + 1,
					type = "method",
					is_current = is_current,
				})
			end
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

	local seen_archtest_fields = {}
	for id, node in query_archtest_field:iter_captures(root, bufnr, 0, -1) do
		local name = query_archtest_field.captures[id]
		if name == "field" then
			-- Get the field name from the variable_declarator
			local field_name = nil
			for child in node:iter_children() do
				if child:type() == "variable_declarator" then
					for subchild in child:iter_children() do
						if subchild:type() == "identifier" then
							field_name = vim.treesitter.get_node_text(subchild, bufnr)
							break
						end
					end
					break
				end
			end

			if field_name and not seen_archtest_fields[field_name] then
				seen_archtest_fields[field_name] = true
				local field_start_row, _, field_end_row, _ = node:range()
				local is_current = cursor_line >= (field_start_row + 1) and cursor_line <= (field_end_row + 1)
				table.insert(tests, {
					name = field_name,
					line = field_start_row + 1,
					type = "method", -- Note: fields are also marked as "method" for consistency
					is_current = is_current,
				})
			end
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

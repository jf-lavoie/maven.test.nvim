local M = {}

function M.get_test_methods()
	local bufnr = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(bufnr, "java")
	if not parser then
		return {}
	end

	local tree = parser:parse()[1]
	local root = tree:root()
	local tests = {}

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
				type = "method",
			})
		end
	end

	return tests
end

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

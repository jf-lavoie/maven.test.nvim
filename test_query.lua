-- Quick test to understand treesitter query behavior
local query_str = [[
(method_declaration
  (modifiers
    (marker_annotation
      name: (identifier) @annotation (#eq? @annotation "Test")))
  name: (identifier) @method.name) @method
]]

print("Query captures:")
local query = vim.treesitter.query.parse("java", query_str)
for i, capture in ipairs(query.captures) do
  print(i .. ": " .. capture)
end

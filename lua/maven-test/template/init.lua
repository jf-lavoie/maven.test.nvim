local M = {}
--- Template a string by replacing {placeholder} patterns with values
--- @param str string The template string (e.g., "mvn test -Dtest={class}#{method}")
--- @param vars table A table of placeholder values (e.g., {class="MyTest", method="testFoo"})
--- @return string The templated string with placeholders replaced
--- @private
function M.template(str, vars)
	return (str:gsub("{([^}]+)}", vars))
end

return M

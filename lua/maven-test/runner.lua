local M = {}

local function get_package_name()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)

	for _, line in ipairs(lines) do
		local package = line:match("^package%s+([%w%.]+)")
		if package then
			return package
		end
	end

	return nil
end

local function run_maven_test(test_spec, debug)
	local config = require("maven-test").config
	local cmd = config.maven_command .. " test " .. test_spec

	if debug then
		cmd = cmd .. " -Dmaven.surefire.debug"
		vim.notify("Running in DEBUG mode (port " .. config.debug_port .. "): " .. cmd, vim.log.levels.INFO)
	else
		vim.notify("Running: " .. cmd, vim.log.levels.INFO)
	end

	-- Open a new terminal split
	vim.cmd("botright split | enew")
	vim.fn.jobstart(cmd, { term = true })
	vim.cmd("startinsert")
end

function M.run_test_method(method_name, debug)
	local class_name = require("maven-test.parser").get_test_class()
	local package_name = get_package_name()

	if not class_name or not package_name then
		vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
		return
	end

	local fully_qualified = package_name .. "." .. class_name .. "#" .. method_name
	run_maven_test("-Dtest=" .. fully_qualified, debug)
end

function M.run_test_class(debug)
	local class_name = require("maven-test.parser").get_test_class()
	local package_name = get_package_name()

	if not class_name or not package_name then
		vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
		return
	end

	local fully_qualified = package_name .. "." .. class_name
	run_maven_test("-Dtest=" .. fully_qualified, debug)
end

function M.run_all_tests(debug)
	run_maven_test("", debug)
end

return M

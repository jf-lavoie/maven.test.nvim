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

local function run_maven_test(command)
	-- local config = require("maven-test").config
	-- local cmd = config.maven_command .. " test " .. test_spec
	--
	-- if debug then
	-- 	cmd = cmd .. " -Dmaven.surefire.debug"
	-- 	vim.notify("Running in DEBUG mode (port " .. config.debug_port .. "): " .. cmd, vim.log.levels.INFO)
	-- else
	vim.notify("Running: " .. command, vim.log.levels.INFO)
	-- end

	-- Open a new terminal split
	vim.cmd("botright split | enew")
	local lCmd = 'echo "$ ' .. command .. '" && ' .. command
	vim.fn.jobstart(lCmd, { term = true })
	vim.cmd("startinsert")
end

function M.run_test_method(method_name, command)
	local class_name = require("maven-test.parser").get_test_class()
	local package_name = get_package_name()

	if not class_name or not package_name then
		vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
		return
	end

	local fully_qualified = package_name .. "." .. class_name .. "#" .. method_name
	local localCommand = string.format(command, fully_qualified)
	run_maven_test(localCommand)
end

function M.run_test_class(command)
	local class_name = require("maven-test.parser").get_test_class()
	local package_name = get_package_name()

	if not class_name or not package_name then
		vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
		return
	end

	local fully_qualified = package_name .. "." .. class_name
	local localCommand = string.format(command, fully_qualified)
	run_maven_test(localCommand)
end

function M.run_all_tests(command)
	run_maven_test(command)
end

return M

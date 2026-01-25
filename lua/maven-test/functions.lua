local M = {}

local store = require("maven-test.store")

local RUN_ALL_KEY = "run_all"
local RUN_CLASS_KEY = "run_class"
local RUN_METHOD_KEY = "run_method"
local RUN_ALL_DEBUG_KEY = "run_all_debug"
local RUN_CLASS_DEBUG_KEY = "run_class_debug"
local RUN_METHOD_DEBUG_KEY = "run_method_debug"

function M.register(options)
	store.add_to_store(RUN_ALL_KEY, options.maven_command .. " test")
	store.add_to_store(RUN_CLASS_KEY, options.maven_command .. " test -Dtest=%s")
	store.add_to_store(RUN_METHOD_KEY, options.maven_command .. " test -Dtest=%s")
	store.add_to_store(RUN_ALL_DEBUG_KEY, options.maven_command .. " test -Dmaven.surefire.debug")
	store.add_to_store(RUN_CLASS_DEBUG_KEY, options.maven_command .. " test -Dtest=%s -Dmaven.surefire.debug")
	store.add_to_store(RUN_METHOD_DEBUG_KEY, options.maven_command .. " test -Dtest=%s -Dmaven.surefire.debug")
end

function M.run_test()
	require("maven-test.ui").show_test_selector(function()
		return store.get(RUN_METHOD_KEY)
	end, function(value)
		store.remove_from_store(RUN_METHOD_KEY, value)
	end, function(value)
		store.add_to_store(RUN_METHOD_KEY, value)
	end)
end

function M.run_test_class()
	local cmds = store.first(RUN_CLASS_KEY)
	require("maven-test.runner").run_test_class(cmds)
end

function M.run_all_tests()
	local cmds = store.first(RUN_ALL_KEY)
	require("maven-test.runner").run_all_tests(cmds)
end

function M.run_test_debug()
	local cmds = store.get(RUN_METHOD_DEBUG_KEY)
	require("maven-test.ui").show_test_selector(cmds)
end

function M.run_test_class_debug()
	local cmds = store.first(RUN_CLASS_DEBUG_KEY)
	require("maven-test.runner").run_test_class(cmds)
end

function M.run_all_tests_debug()
	local cmds = store.first(RUN_ALL_DEBUG_KEY)
	require("maven-test.runner").run_all_tests(cmds)
end

function M.restore_store()
	store.empty_store()
	M.register(require("maven-test").config)
end

return M

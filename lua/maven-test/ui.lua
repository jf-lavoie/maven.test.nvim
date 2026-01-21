local M = {}

local popup_bufnr = nil
local popup_winid = nil
local preview_bufnr = nil
local preview_winid = nil

local function create_floating_window()
	local config = require("maven-test").config
	local width = math.floor(vim.o.columns * config.floating_window.width)
	local total_height = math.floor(vim.o.lines * config.floating_window.height)
	local height1 = math.floor(total_height * 2 / 3)
	local height2 = total_height - height1 - 2
	local row = math.floor((vim.o.lines - total_height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Top window (test selector)
	local buf1 = vim.api.nvim_create_buf(false, true)
	local win1 = vim.api.nvim_open_win(buf1, true, {
		relative = "editor",
		width = width,
		height = height1,
		row = row,
		col = col,
		style = "minimal",
		border = config.floating_window.border,
	})

	vim.api.nvim_buf_set_option(buf1, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf1, "filetype", "maven-test")

	-- Bottom window (command preview)
	local buf2 = vim.api.nvim_create_buf(false, true)
	local win2 = vim.api.nvim_open_win(buf2, false, {
		relative = "editor",
		width = width,
		height = height2,
		row = row + height1 + 2,
		col = col,
		style = "minimal",
		border = config.floating_window.border,
	})

	vim.api.nvim_buf_set_option(buf2, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf2, "filetype", "maven-test")

	vim.api.nvim_win_set_option(win2, "wrap", true)
	vim.api.nvim_win_set_option(win2, "linebreak", true)

	return buf1, win1, buf2, win2
end

local function close_popup()
	if popup_winid and vim.api.nvim_win_is_valid(popup_winid) then
		vim.api.nvim_win_close(popup_winid, true)
	end
	if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
		vim.api.nvim_win_close(preview_winid, true)
	end
	popup_bufnr = nil
	popup_winid = nil
	preview_bufnr = nil
	preview_winid = nil
end

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

local function get_maven_command(class_name, package_name, method_name, debug)
	local config = require("maven-test").config
	local cmd = config.maven_command .. " test "

	if method_name then
		cmd = cmd .. "-Dtest=" .. package_name .. "." .. class_name .. "#" .. method_name
	elseif class_name then
		cmd = cmd .. "-Dtest=" .. package_name .. "." .. class_name
	end

	if debug then
		cmd = cmd .. " -Dmaven.surefire.debug"
	end

	return cmd
end

local function update_preview(tests, class_name, package_name, debug)
	local line = vim.api.nvim_win_get_cursor(popup_winid)[1]
	local cmd = ""

	if class_name and line == 3 then
		cmd = get_maven_command(class_name, package_name, nil, debug)
	elseif line > (class_name and 4 or 2) then
		local test_idx = line - (class_name and 4 or 2)
		if tests[test_idx] then
			cmd = get_maven_command(class_name, package_name, tests[test_idx].name, debug)
		end
	end

	local preview_lines = { "$ " .. cmd }
	vim.api.nvim_buf_set_option(preview_bufnr, "modifiable", true)
	vim.api.nvim_buf_set_lines(preview_bufnr, 0, -1, false, preview_lines)
	vim.api.nvim_buf_set_option(preview_bufnr, "modifiable", false)
end

function M.show_test_selector(debug)
	local parser = require("maven-test.parser")
	local runner = require("maven-test.runner")

	local tests = parser.get_test_methods()
	local class_name = parser.get_test_class()
	local package_name = get_package_name()

	if #tests == 0 then
		vim.notify("No test methods found in current file", vim.log.levels.WARN)
		return
	end

	if not class_name or not package_name then
		vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
		return
	end

	popup_bufnr, popup_winid, preview_bufnr, preview_winid = create_floating_window()

	local lines = { "Select test to run:", "" }
	if class_name then
		table.insert(lines, "▶ Run all tests in class: " .. class_name)
		table.insert(lines, "")
	end

	for _, test in ipairs(tests) do
		table.insert(lines, "  " .. test.name .. " (line " .. test.line .. ")")
	end

	vim.api.nvim_buf_set_lines(popup_bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(popup_bufnr, "modifiable", false)

	local function on_cursor_move()
		update_preview(tests, class_name, package_name, debug)
	end

	local function on_select()
		local line = vim.api.nvim_win_get_cursor(popup_winid)[1]
		close_popup()

		if class_name and line == 3 then
			runner.run_test_class(debug)
		elseif line > (class_name and 4 or 2) then
			local test_idx = line - (class_name and 4 or 2)
			if tests[test_idx] then
				runner.run_test_method(tests[test_idx].name, debug)
			end
		end
	end

	vim.keymap.set("n", "<CR>", on_select, { buffer = popup_bufnr, nowait = true })
	vim.keymap.set("n", "q", close_popup, { buffer = popup_bufnr, nowait = true })
	vim.keymap.set("n", "<Esc>", close_popup, { buffer = popup_bufnr, nowait = true })

	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = popup_bufnr,
		callback = on_cursor_move,
	})

	vim.api.nvim_win_set_cursor(popup_winid, { class_name and 3 or 3, 0 })
	update_preview(tests, class_name, package_name, debug)
end

return M

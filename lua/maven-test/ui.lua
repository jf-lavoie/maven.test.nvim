local M = {}

local popup_bufnr = nil
local popup_winid = nil

local function create_floating_window()
	local config = require("maven-test").config
	local width = math.floor(vim.o.columns * config.floating_window.width)
	local height = math.floor(vim.o.lines * config.floating_window.height)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = config.floating_window.border,
	})

	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "filetype", "maven-test")

	return buf, win
end

local function close_popup()
	if popup_winid and vim.api.nvim_win_is_valid(popup_winid) then
		vim.api.nvim_win_close(popup_winid, true)
	end
	popup_bufnr = nil
	popup_winid = nil
end

function M.show_test_selector(debug)
	local parser = require("maven-test.parser")
	local runner = require("maven-test.runner")

	local tests = parser.get_test_methods()
	local class_name = parser.get_test_class()

	if #tests == 0 then
		vim.notify("No test methods found in current file", vim.log.levels.WARN)
		return
	end

	popup_bufnr, popup_winid = create_floating_window()

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

	local function on_select()
		local line = vim.api.nvim_win_get_cursor(popup_winid)[1]
		close_popup()

		if class_name and line == 3 then
			runner.run_test_class()
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

	vim.api.nvim_win_set_cursor(popup_winid, { class_name and 3 or 3, 0 })
end

return M

local M = {}

local ui = require("maven-test.ui")
local runner = require("maven-test.runner")

local width = ui.width
local height = ui.height
local row = ui.row
local col = ui.col

local function run_command(bufWin)
	local line = vim.api.nvim_get_current_line()
	bufWin:close()
	runner.run_command(line)
end

local function update_floating_window(bufWin, getCommands)
	local cmds = {}

	for index, value in ipairs(getCommands()) do
		local sanitize = value:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
		table.insert(cmds, index, sanitize)
	end

	local preview_lines = cmds
	vim.api.nvim_buf_set_option(bufWin.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(bufWin.buf, 0, -1, false, preview_lines)
	vim.api.nvim_buf_set_option(bufWin.buf, "modifiable", false)
end

function M.show_commands(getCommands, fctDeleteFromStore, fctAddToStore)
	local bufWin = ui.FloatingWindow.new(height, width, row, col, true, "sh")

	vim.api.nvim_create_autocmd("WinEnter", {
		group = vim.api.nvim_create_augroup("MavenTestUICommandsWinEnter", { clear = true }),
		callback = function()
			if not bufWin:is_active() then
				vim.api.nvim_del_augroup_by_name("MavenTestUICommandsWinEnter")
				bufWin:close()
			end
		end,
	})

	vim.keymap.set("n", "q", function()
		bufWin:close()
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "<Esc>", function()
		bufWin:close()
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "<Space>", function()
		run_command(bufWin)
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "<CR>", function()
		run_command(bufWin)
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "d", function()
		local line = vim.api.nvim_get_current_line()
		fctDeleteFromStore(line)

		update_floating_window(bufWin, getCommands)
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "m", function()
		local line = vim.api.nvim_get_current_line()
		bufWin:close()

		ui.show_command_editor(line, fctAddToStore, function()
			M.show_commands(getCommands, fctDeleteFromStore, fctAddToStore)
		end)
	end, { buffer = bufWin.buf, nowait = true })

	update_floating_window(bufWin, getCommands)

	vim.api.nvim_win_set_option(
		bufWin.win,
		"winbar",
		"%#StatusLine#<CR>, <space> Run command | <m> modify command | <d> delete command | <q> Quit"
	)
end

return M

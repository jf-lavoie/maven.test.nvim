local M = {}

local ui = require("maven-test.ui.ui")
local runner = require("maven-test.runner.runner")

local width = ui.width
local height = ui.height
local row = ui.row
local col = ui.col

local function run_command(bufWin, cmd)
	bufWin:close()
	runner.run_command(cmd)
end

local function update_view(bufWin, getCommands)
	local cmds = {}

	local customArguments = require("maven-test.store.arguments")

	for index, value in ipairs(getCommands()) do
		local sanitize = value:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")

		for _, arg in ipairs(customArguments.list()) do
			if arg.active then
				sanitize = arg:append_to_command(sanitize)
			end
		end

		table.insert(cmds, index, sanitize)
	end

	local preview_lines = cmds
	vim.api.nvim_buf_set_option(bufWin.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(bufWin.buf, 0, -1, false, preview_lines)
	vim.api.nvim_buf_set_option(bufWin.buf, "modifiable", false)
end

local function getSelectedCmd(bufWin, getCommands)
	local index = vim.api.nvim_win_get_cursor(bufWin.win)[1]

	local cmd = getCommands()[index]

	return cmd
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
		run_command(bufWin, getSelectedCmd(bufWin, getCommands))
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "<CR>", function()
		run_command(bufWin, getSelectedCmd(bufWin, getCommands))
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "d", function()
		local cmd = getSelectedCmd(bufWin, getCommands)
		fctDeleteFromStore(cmd)

		update_view(bufWin, getCommands)
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "m", function()
		local cmd = getSelectedCmd(bufWin, getCommands)
		bufWin:close()

		ui.show_command_editor(cmd, fctAddToStore, function()
			M.show_commands(getCommands, fctDeleteFromStore, fctAddToStore)
		end)
	end, { buffer = bufWin.buf, nowait = true })

	update_view(bufWin, getCommands)

	vim.api.nvim_win_set_option(
		bufWin.win,
		"winbar",
		"%#StatusLine#<CR>, <space> Run command | <m> modify command | <d> delete command | <q> Quit"
	)
end

return M

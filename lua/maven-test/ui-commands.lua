local M = {}

local ui = require("maven-test.ui")

local width = ui.width
local height = ui.height
local row = ui.row
local col = ui.col

function M.show_commands(getCommands, fctDeleteFromStore, fctAddToStore)
	local bufWin = ui.FloatingWindow.new(height, width, row, col, true, "sh")

	local cmds = {}

	for index, value in ipairs(getCommands()) do
		table.insert(cmds, index, value)
	end

	local preview_lines = cmds
	vim.api.nvim_buf_set_option(bufWin.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(bufWin.buf, 0, -1, false, preview_lines)
	vim.api.nvim_buf_set_option(bufWin.buf, "modifiable", false)

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

	vim.api.nvim_win_set_option(
		bufWin.win,
		"winbar",
		"%#StatusLine#<CR>, <space> Run command | <m> modify command | <d> delete command | q Quit"
	)
end

return M

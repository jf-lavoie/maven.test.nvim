--- Maven commands list UI
--- Displays stored Maven commands in a floating window
--- Allows running, editing, and deleting commands
--- @module 'maven-test.commands.ui'

local M = {}

local ui = require("maven-test.ui.ui")
local runner = require("maven-test.runner.runner")

local width = ui.width
local height = ui.height
local row = ui.row
local col = ui.col

--- Run a command and close the UI window
--- @param bufWin FloatingWindow The window to close
--- @param cmd string The Maven command to run
--- @private
local function run_command(bufWin, cmd)
	bufWin:close()
	runner.run_command(cmd)
end

--- Update the view with current commands list
--- Applies active custom arguments to each command in the preview
--- @param bufWin FloatingWindow The window to update
--- @param getCommands function Function that returns array of commands
--- @private
local function update_view(bufWin, getCommands)
	local cmds = {}

	local customArguments = require("maven-test.store.arguments")

	for index, value in ipairs(getCommands()) do
		-- Sanitize command for display (escape special characters)
		local sanitize = value:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")

		-- Append active custom arguments to preview
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

--- Get the command at the current cursor position
--- @param bufWin FloatingWindow The window containing the cursor
--- @param getCommands function Function that returns array of commands
--- @return string The selected command
--- @private
local function getSelectedCmd(bufWin, getCommands)
	local index = vim.api.nvim_win_get_cursor(bufWin.win)[1]

	local cmd = getCommands()[index]

	return cmd
end

--- Show Maven commands UI
--- Opens a floating window displaying all stored Maven commands
--- User can run, edit, or delete commands
--- @param getCommands function Function that returns array of command strings
--- @param fctDeleteFromStore function Callback function(cmd) to delete a command
--- @param fctAddToStore function Callback function(cmd) to add/update a command
--- @usage
---   show_commands(
---     function() return store.get("commands") end,
---     function(cmd) store.remove("commands", cmd) end,
---     function(cmd) store.add("commands", cmd) end
---   )
function M.show_commands(getCommands, fctDeleteFromStore, fctAddToStore)
	local bufWin = ui.FloatingWindow.new(height, width, row, col, true, "sh")

	-- Auto-close when switching windows
	vim.api.nvim_create_autocmd("WinEnter", {
		group = vim.api.nvim_create_augroup("MavenTestUICommandsWinEnter", { clear = true }),
		callback = function()
			if not bufWin:is_active() then
				vim.api.nvim_del_augroup_by_name("MavenTestUICommandsWinEnter")
				bufWin:close()
			end
		end,
	})

	-- Close window keymaps
	vim.keymap.set("n", "q", function()
		bufWin:close()
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "<Esc>", function()
		bufWin:close()
	end, { buffer = bufWin.buf, nowait = true })

	-- Run selected command
	vim.keymap.set("n", "<Space>", function()
		run_command(bufWin, getSelectedCmd(bufWin, getCommands))
	end, { buffer = bufWin.buf, nowait = true })

	vim.keymap.set("n", "<CR>", function()
		run_command(bufWin, getSelectedCmd(bufWin, getCommands))
	end, { buffer = bufWin.buf, nowait = true })

	-- Delete selected command
	vim.keymap.set("n", "d", function()
		local cmd = getSelectedCmd(bufWin, getCommands)
		fctDeleteFromStore(cmd)

		update_view(bufWin, getCommands)
	end, { buffer = bufWin.buf, nowait = true })

	-- Edit selected command
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

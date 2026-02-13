local M = {}

local Argument = require("maven-test.arguments.argument").Argument

local ui = require("maven-test.ui.ui")

--- Show custom arguments editor UI
--- Opens a floating window to manage custom Maven arguments
--- Displays arguments with activation status (🟢 active, 🔴 inactive)
--- Supports adding, editing, deleting, and toggling arguments
--- @param getArgs function Function that returns array of Argument objects
--- @param onAddArg function Callback function(arg) to add a new argument
--- @param onUpdateArg function Callback function(arg) to update an argument
--- @param onDeleteArg function Callback function(arg) to delete an argument
--- @param onComplete function Callback function called when editor is closed
--- @usage
---   default_arguments_editor(
---     store_arg.list,
---     store_arg.add,
---     store_arg.update,
---     store_arg.remove,
---     function() print("Closed") end
---   )
function M.default_arguments_editor(getArgs, onAddArg, onUpdateArg, onDeleteArg, onComplete)
	local bufWin = ui.FloatingWindow.new(
		10,
		160,
		math.floor((vim.o.lines - 10) / 2),
		math.floor((vim.o.columns - 160) / 2),
		true,
		"sh"
	)

	--- Update the view with current arguments list
	--- Displays arguments with colored status indicators
	--- @private
	local function update_view()
		local row = vim.api.nvim_win_get_cursor(bufWin.win)[1]

		vim.api.nvim_buf_set_option(bufWin.buf, "modifiable", true)

		local splittedLines = {}
		local args = getArgs()
		for _, arg in ipairs(args) do
			local line = "🔴 "
			if arg.active then
				line = "🟢 "
			end
			table.insert(splittedLines, line .. arg.text)
		end

		vim.api.nvim_buf_set_lines(bufWin.buf, 0, -1, true, splittedLines)
		vim.api.nvim_buf_set_option(bufWin.buf, "modifiable", false)

		if row > #args then
			row = #args
		end
		if row < 1 then
			row = 1
		end
		vim.api.nvim_win_set_cursor(bufWin.win, { row, 0 })
	end

	--- Get the argument at the current cursor position
	--- Retrieves the Argument object corresponding to the line where the cursor is positioned.
	--- If the cursor is beyond the arguments list, returns the last argument.
	--- @return Argument|nil The selected Argument object, or nil if no arguments exist
	--- @private
	local function getSelectedArg()
		local index = vim.api.nvim_win_get_cursor(bufWin.win)[1]

		local args = getArgs()

		if #args < 1 then
			return nil
		end

		if index > #args then
			index = #args
		end

		return args[index]
	end

	vim.api.nvim_win_set_option(
		bufWin.win,
		"winbar",
		"%#StatusLine# <space> toggle activation | <a> add | <u> update | <d> delete | <esc>, <q> Quit"
	)

	-- Close window keymaps
	vim.keymap.set("n", "<Esc>", function()
		bufWin:close()
		onComplete()
	end, { buffer = bufWin.buf, nowait = true })
	vim.keymap.set("n", "q", function()
		bufWin:close()
		onComplete()
	end, { buffer = bufWin.buf, nowait = true })

	-- Add new argument
	vim.keymap.set("n", "a", function()
		bufWin:close()
		ui.show_command_editor("", function(arg)
			onAddArg(Argument.new(arg, false))
		end, function()
			M.default_arguments_editor(getArgs, onAddArg, onUpdateArg, onDeleteArg, onComplete)
		end)
	end, { buffer = bufWin.buf, nowait = true })

	-- Update selected argument
	vim.keymap.set("n", "u", function()
		local arg = getSelectedArg()

		if not arg then
			return
		end

		bufWin:close()

		ui.show_command_editor(arg.text, function(updated)
			if arg.text ~= updated then
				onDeleteArg(arg)
				onAddArg(Argument.new(updated, arg.active))
			end
		end, function()
			M.default_arguments_editor(getArgs, onAddArg, onUpdateArg, onDeleteArg, onComplete)
		end)
	end, { buffer = bufWin.buf, nowait = true })

	-- Delete selected argument
	vim.keymap.set("n", "d", function()
		local arg = getSelectedArg()

		if not arg then
			return
		end
		onDeleteArg(arg)
		update_view()
	end, { buffer = bufWin.buf, nowait = true })

	-- Toggle argument activation
	vim.keymap.set("n", "<space>", function()
		local arg = getSelectedArg()

		if not arg then
			return
		end
		arg:toggle_active()
		onUpdateArg(arg)
		update_view()
	end, { buffer = bufWin.buf, nowait = true })

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = bufWin.buf,
		callback = function()
			bufWin:close()
		end,
	})
	update_view()
end

--- Show custom arguments editor UI
--- External callers that wants to access the module without knowing the internal structure
--- Opens a floating window to manage custom Maven arguments
--- Displays arguments with activation status (🟢 active, 🔴 inactive)
--- Supports adding, editing, deleting, and toggling arguments
--- @param onComplete function Callback function called when editor is closed
--- @usage
---   default_arguments_editor(
---     function() print("Closed") end
---   )
function M.external_default_arguments_editor(onComplete)
	local store = require("maven-test.arguments.store")

	M.default_arguments_editor(store.list, store.add, store.update, store.remove, onComplete)
end
return M

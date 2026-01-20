local M = {}

M.config = {
	maven_command = "mvn",
	floating_window = {
		width = 0.8,
		height = 0.6,
		border = "rounded",
	},
	debug_port = 5005,
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	require("maven-test.commands").register()
end

return M

if vim.g.loaded_maven_test ~= 1 then
	return
end

local opts = { buffer = true, silent = true, remap = true }

-- Default keymaps (only if not already mapped)
if vim.fn.hasmapto("<Plug>(maven-test-section)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mt",
		"<Plug>(maven-test-section)",
		vim.tbl_extend("force", opts, { desc = "Maven tests" })
	)
end

if vim.fn.hasmapto("<Plug>(maven-test)") == 0 then
	vim.keymap.set("n", "<leader>Mtt", "<Plug>(maven-test)", vim.tbl_extend("force", opts, { desc = "Maven test" }))
end
if vim.fn.hasmapto("<Plug>(maven-test-class)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mtc",
		"<Plug>(maven-test-class)",
		vim.tbl_extend("force", opts, { desc = "Run current class tests" })
	)
end
if vim.fn.hasmapto("<Plug>(maven-test-all)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mta",
		"<Plug>(maven-test-all)",
		vim.tbl_extend("force", opts, { desc = "Run all tests" })
	)
end

if vim.fn.hasmapto("<Plug>(maven-test-section-debug)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mtd",
		"<Plug>(maven-test-section)",
		vim.tbl_extend("force", opts, { desc = "Maven tests (debug mode)" })
	)
end
if vim.fn.hasmapto("<Plug>(maven-test-debug)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mtdt",
		"<Plug>(maven-test-debug)",
		vim.tbl_extend("force", opts, { desc = "Open test selector (debug mode)" })
	)
end
if vim.fn.hasmapto("<Plug>(maven-test-class-debug)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mtdc",
		"<Plug>(maven-test-class-debug)",
		vim.tbl_extend("force", opts, { desc = "Run current class tests (debug mode)" })
	)
end
if vim.fn.hasmapto("<Plug>(maven-test-all-debug)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mtda",
		"<Plug>(maven-test-all-debug)",
		vim.tbl_extend("force", opts, { desc = "Run all tests (debug mode)" })
	)
end

if vim.fn.hasmapto("<Plug>(maven-test-commands)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mx",
		"<Plug>(maven-test-commands)",
		vim.tbl_extend("force", opts, { desc = "Maven commands" })
	)
end

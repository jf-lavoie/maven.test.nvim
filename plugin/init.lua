-- maven-test.nvim - Maven test runner integration for Neovim
-- Maintainer: jflavoie
-- Version: 1.0.0
-- License: MIT (2026)

if vim.g.loaded_maven_test then
	return
end
vim.g.loaded_maven_test = 1

require("maven-test").setup()

-- Define <Plug> mappings
vim.keymap.set("n", "<Plug>(maven-test-section)", "+Maven tests", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test)", ":MavenTest<CR>", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test-class)", ":MavenTestClass<CR>", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test-all)", ":MavenTestAll<CR>", { silent = true })

vim.keymap.set("n", "<Plug>(maven-test-debug-section)", "+Maven debug tests", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test-debug)", ":MavenTestDebug<CR>", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test-class-debug)", ":MavenTestClassDebug<CR>", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test-all-debug)", ":MavenTestAllDebug<CR>", { silent = true })

-- Default keymaps (only if not already mapped)
if vim.fn.hasmapto("<Plug>(maven-test-section)") == 0 then
	vim.keymap.set("n", "<leader>Mt", "<Plug>(maven-test-section)", { remap = true, desc = "Maven tests" })
end

if vim.fn.hasmapto("<Plug>(maven-test)") == 0 then
	vim.keymap.set("n", "<leader>Mtt", "<Plug>(maven-test)", { remap = true, desc = "Maven test" })
end
if vim.fn.hasmapto("<Plug>(maven-test-class)") == 0 then
	vim.keymap.set("n", "<leader>Mtc", "<Plug>(maven-test-class)", { remap = true, desc = "Run current class tests" })
end
if vim.fn.hasmapto("<Plug>(maven-test-all)") == 0 then
	vim.keymap.set("n", "<leader>Mta", "<Plug>(maven-test-all)", { remap = true, desc = "Run all tests" })
end

if vim.fn.hasmapto("<Plug>(maven-test-section-debug)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mtd",
		"<Plug>(maven-test-section)",
		{ remap = true, desc = "Maven tests (debug mode)" }
	)
end
if vim.fn.hasmapto("<Plug>(maven-test-debug)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mtdt",
		"<Plug>(maven-test-debug)",
		{ remap = true, desc = "Open test selector (debug mode)" }
	)
end
if vim.fn.hasmapto("<Plug>(maven-test-class-debug)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mtdc",
		"<Plug>(maven-test-class-debug)",
		{ remap = true, desc = "Run current class tests (debug mode)" }
	)
end
if vim.fn.hasmapto("<Plug>(maven-test-all-debug)") == 0 then
	vim.keymap.set(
		"n",
		"<leader>Mtda",
		"<Plug>(maven-test-all-debug)",
		{ remap = true, desc = "Run all tests (debug mode)" }
	)
end

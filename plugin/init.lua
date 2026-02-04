-- maven-test.nvim - Maven test runner integration for Neovim
-- Maintainer: jflavoie
-- Version: 1.0.0
-- License: MIT (2026)

-- Define <Plug> mappings
-- vim.keymap.set("n", "<Plug>(maven-test-section)", "+Maven tests", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test)", ":MavenTest<CR>", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test-class)", ":MavenTestClass<CR>", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test-all)", ":MavenTestAll<CR>", { silent = true })

-- vim.keymap.set("n", "<Plug>(maven-test-debug-section)", "+Maven debug tests", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test-debug)", ":MavenTestDebug<CR>", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test-class-debug)", ":MavenTestClassDebug<CR>", { silent = true })
vim.keymap.set("n", "<Plug>(maven-test-all-debug)", ":MavenTestAllDebug<CR>", { silent = true })

vim.keymap.set("n", "<Plug>(maven-test-commands)", ":MavenTestCommands<CR>", { silent = true })

require("maven-test").setup()

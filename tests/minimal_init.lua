-- Minimal init.lua for running tests
vim.opt.runtimepath:append(".")
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/mini.test")

-- Ensure mini.test is available
local ok, _ = pcall(require, "mini.test")
if not ok then
	print("Error: mini.test not found. Install it first:")
	print("  git clone https://github.com/echasnovski/mini.nvim " .. vim.fn.stdpath("data") .. "/lazy/mini.nvim")
	vim.cmd("quitall!")
end

# maven.test.nvim

A Neovim plugin that provides Maven integration for testing Java projects. Using Neovim's treesitter, it detects Java test files and provides commands to run and debug tests using Maven.

**Version:** 1.0.0  
**License:** MIT  
**Year:** 2026

## Features

- 🎯 Run individual test methods
- 📦 Run entire test classes
- 🚀 Run complete test suites
- 🐛 Debug tests with breakpoints
- 🎨 Interactive floating window for test selection
- 🌲 Treesitter-based test detection
- 📺 Test output in terminal window inside Neovim

## Requirements

- Neovim >= 0.9.0
- Treesitter with Java parser installed
- Maven installed and available in PATH

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'jflavoie/maven.test.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('maven-test').setup({
      maven_command = "mvn",
      debug_port = 5005,
      floating_window = {
        width = 0.8,
        height = 0.6,
        border = "rounded",
      },
    })
  end,
}
```

## Usage

### Commands

**Normal Mode:**
- `:MavenTest` - Opens a floating window to select and run a specific test
- `:MavenTestClass` - Runs all tests in the current class
- `:MavenTestAll` - Runs all tests in the project

**Debug Mode:**
- `:MavenTestDebug` - Opens a floating window to select and debug a specific test
- `:MavenTestClassDebug` - Debugs all tests in the current class
- `:MavenTestAllDebug` - Debugs all tests in the project

Debug commands start Maven Surefire in debug mode, listening on the configured port (default: 5005). Attach your debugger to this port to debug tests with breakpoints.

### Keymaps

Default keymaps (can be overridden):
- `<leader>Mt` - Run test selector
- `<leader>Mc` - Run test class
- `<leader>Ma` - Run all tests

Custom keymaps example:

```lua
vim.keymap.set('n', '<leader>mt', '<cmd>MavenTest<cr>', { desc = 'Maven: Run test' })
vim.keymap.set('n', '<leader>mc', '<cmd>MavenTestClass<cr>', { desc = 'Maven: Run test class' })
vim.keymap.set('n', '<leader>ma', '<cmd>MavenTestAll<cr>', { desc = 'Maven: Run all tests' })

-- Debug mode
vim.keymap.set('n', '<leader>md', '<cmd>MavenTestDebug<cr>', { desc = 'Maven: Debug test' })
vim.keymap.set('n', '<leader>mD', '<cmd>MavenTestClassDebug<cr>', { desc = 'Maven: Debug test class' })
vim.keymap.set('n', '<leader>mA', '<cmd>MavenTestAllDebug<cr>', { desc = 'Maven: Debug all tests' })
```

### Interactive Test Selection

When you trigger the test selector, a floating window appears with:
- Option to run all tests in the current class
- List of all test methods in the file

Navigate using:
- `j/k` or arrow keys to move up/down
- `<Enter>` to select and run the test
- `q` or `<Esc>` to close the window

## Configuration

```lua
require('maven-test').setup({
  -- Maven command to use
  maven_command = "mvn",
  
  -- Debug port for Maven Surefire debug mode
  debug_port = 5005,
  
  -- Floating window configuration
  floating_window = {
    width = 0.8,        -- 80% of editor width
    height = 0.6,       -- 60% of editor height
    border = "rounded", -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
  },
})
```

## Debugging Tests

When using debug commands (`:MavenTestDebug`, `:MavenTestClassDebug`, `:MavenTestAllDebug`), Maven Surefire starts in debug mode and waits for a debugger to attach on port 5005 (configurable).

To debug:
1. Run a debug command (e.g., `:MavenTestDebug`)
2. Maven will pause and wait for debugger attachment
3. Attach your Java debugger (e.g., nvim-dap, IntelliJ IDEA, VS Code) to `localhost:5005`
4. Set breakpoints in your test code
5. Continue execution in your debugger

## License

MIT

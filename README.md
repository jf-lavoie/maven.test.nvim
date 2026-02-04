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
- 💾 Store, edit, and reuse custom Maven commands
- ⚡ Quick access to command history per project

## Requirements

- Neovim >= 0.9.0
- Treesitter with Java parser installed
- Maven installed and available in PATH

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'jf-lavoie/maven.test.nvim',
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

The plugin provides `<Plug>` mappings that you can use to create your own keymaps. No default keymaps are set, giving you full control over your key bindings.

#### Available `<Plug>` Mappings

- `<Plug>(maven-test)` - Open test selector
- `<Plug>(maven-test-class)` - Run all tests in current class
- `<Plug>(maven-test-all)` - Run all tests in project
- `<Plug>(maven-test-debug)` - Open test selector in debug mode
- `<Plug>(maven-test-class-debug)` - Debug all tests in current class
- `<Plug>(maven-test-all-debug)` - Debug all tests in project
- `<Plug>(maven-test-commands)` - Open stored commands viewer

#### Custom Keymap Examples

You can create your own mappings in your Neovim configuration:

```lua
-- Basic test commands
vim.keymap.set('n', '<leader>Xt', '<Plug>(maven-test)', { desc = 'Maven: Run test' })
vim.keymap.set('n', '<leader>Xc', '<Plug>(maven-test-class)', { desc = 'Maven: Run test class' })
vim.keymap.set('n', '<leader>Xa', '<Plug>(maven-test-all)', { desc = 'Maven: Run all tests' })

-- Debug mode
vim.keymap.set('n', '<leader>Xdt', '<Plug>(maven-test-debug)', { desc = 'Maven: Debug test' })
vim.keymap.set('n', '<leader>Xdc', '<Plug>(maven-test-class-debug)', { desc = 'Maven: Debug test class' })
vim.keymap.set('n', '<leader>Xda', '<Plug>(maven-test-all-debug)', { desc = 'Maven: Debug all tests' })

-- Command viewer
vim.keymap.set('n', '<leader>Xx', '<Plug>(maven-test-commands)', { desc = 'Maven: View commands' })
```

#### Filetype-Specific Mappings

To create mappings only for Java files, use an autocommand:

```lua
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function()
    vim.keymap.set('n', '<leader>Xt', '<Plug>(maven-test)', { buffer = true, desc = 'Maven: Run test' })
    vim.keymap.set('n', '<leader>Xc', '<Plug>(maven-test-class)', { buffer = true, desc = 'Maven: Run test class' })
    -- Add more mappings as needed
  end
})
```

Or create a file at `~/.config/nvim/ftplugin/java.lua`:

```lua
vim.keymap.set('n', '<leader>Xt', '<Plug>(maven-test)', { buffer = true, desc = 'Maven: Run test' })
vim.keymap.set('n', '<leader>Xc', '<Plug>(maven-test-class)', { buffer = true, desc = 'Maven: Run test class' })
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

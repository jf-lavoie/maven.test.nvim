# maven.test.nvim

A Neovim plugin that provides Maven integration for testing Java projects. Using Neovim's treesitter, it detects Java test files and provides commands to run and debug tests using Maven.

**Version:** 1.0.0  
**License:** MIT  
**Year:** 2026

## Features

- 🎯 **Run individual test methods** - Select and run specific tests
- 📦 **Run entire test classes** - Execute all tests in the current file
- 🚀 **Run complete test suites** - Run all tests in your project
- 🐛 **Debug tests with breakpoints** - Remote debugging support via Maven Surefire
- 🎨 **Interactive floating windows** - Two-pane UI for test selection with command preview
- 🌲 **Treesitter-based test detection** - Automatically finds `@Test` and `@ArchTest` annotations
- 💾 **Command storage and management** - Store, edit, and reuse custom Maven commands per project
- ⚙️ **Custom Maven arguments** - Define reusable arguments that apply to all commands
- 📋 **Maven lifecycle commands** - Quick access to common Maven goals (compile, package, install, etc.)
- ⚡ **Per-project configuration** - Each project maintains its own command store

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

### Available Commands

The plugin provides the following commands (available in Java buffers):

#### Test Execution Commands

| Command | Description |
|---------|-------------|
| `:MavenTest` | Opens floating window to select and run a specific test method |
| `:MavenTestClass` | Runs all tests in the current class |
| `:MavenTestAll` | Runs all tests in the project |

#### Debug Commands

| Command | Description |
|---------|-------------|
| `:MavenTestDebug` | Opens floating window to select and debug a specific test method |
| `:MavenTestClassDebug` | Debugs all tests in the current class |
| `:MavenTestAllDebug` | Debugs all tests in the project |

Debug commands start Maven Surefire in debug mode, listening on the configured port (default: 5005). Attach your debugger to this port to debug tests with breakpoints.

#### Management Commands

| Command | Description |
|---------|-------------|
| `:MavenTestCommands` | Opens floating window to view, edit, and run stored Maven commands |
| `:MavenTestCustomArguments` | Opens UI to manage custom Maven arguments |
| `:MavenTestRestoreCommandsStore` | Restores command store to default state |

### Keymaps

The plugin provides `<Plug>` mappings that you can use to create your own keymaps. No default keymaps are set, giving you full control over your key bindings.

#### Available `<Plug>` Mappings

| Mapping | Command | Description |
|---------|---------|-------------|
| `<Plug>(maven-test)` | `:MavenTest` | Open test selector |
| `<Plug>(maven-test-class)` | `:MavenTestClass` | Run all tests in current class |
| `<Plug>(maven-test-all)` | `:MavenTestAll` | Run all tests in project |
| `<Plug>(maven-test-debug)` | `:MavenTestDebug` | Open test selector in debug mode |
| `<Plug>(maven-test-class-debug)` | `:MavenTestClassDebug` | Debug all tests in current class |
| `<Plug>(maven-test-all-debug)` | `:MavenTestAllDebug` | Debug all tests in project |
| `<Plug>(maven-test-commands)` | `:MavenTestCommands` | Open stored commands viewer |
| `<Plug>(maven-test-custom-arguments)` | `:MavenTestCustomArguments` | Open custom arguments manager |

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

### Interactive Floating Windows

The plugin provides three types of floating windows for different tasks:

#### 1. Test Selector Window (`:MavenTest`, `:MavenTestDebug`)

When you run `:MavenTest` or `:MavenTestDebug`, a two-pane floating window appears:

**Layout:**
```
┌─────────────────────────────────────┐
│ Test Actions (Top Pane)             │
│ • Run all tests in class            │
│ • testMethod1() - line 42           │
│ • testMethod2() - line 58           │
│ • ...                                │
├─────────────────────────────────────┤
│ Commands (Bottom Pane)              │
│ mvn test -Dtest=com.example.Test#...│
│ ...                                  │
└─────────────────────────────────────┘
```

**Navigation:**
- `j/k` or arrow keys - Move cursor up/down in the current pane
- `<Space>` - Switch focus between top pane (actions) and bottom pane (commands)
- `<Enter>` - Execute the selected test (from top pane) or run selected command (from bottom pane)
- `m` - Edit the selected command (when in bottom pane)
- `d` - Delete the selected command (when in bottom pane, if multiple commands exist)
- `q` or `<Esc>` - Close the window

**Features:**
- The bottom pane shows a **preview** of the Maven command(s) that will be executed
- As you move the cursor in the top pane, the bottom pane updates to show relevant commands
- You can edit commands to add custom Maven flags or modify arguments
- Commands are stored per project and persist across sessions

#### 2. Maven Commands Window (`:MavenTestCommands`)

Opens a floating window displaying all stored Maven commands (including lifecycle goals):

**Layout:**
```
┌─────────────────────────────────────┐
│ Maven Commands                      │
│                                     │
│ mvn validate                        │
│ mvn compile                         │
│ mvn test                            │
│ mvn package                         │
│ mvn verify                          │
│ mvn install                         │
│ mvn deploy                          │
│ mvn clean                           │
│ mvn site                            │
│ <custom commands you've added>      │
└─────────────────────────────────────┘
```

**Navigation:**
- `j/k` or arrow keys - Move cursor up/down
- `<Enter>` or `<Space>` - Execute the selected command
- `m` - Edit the selected command
- `d` - Delete the selected command
- `q` or `<Esc>` - Close the window

**Features:**
- Quick access to common Maven lifecycle goals
- Run any Maven command directly from Neovim
- Add your own custom Maven commands (e.g., `mvn clean install -DskipTests`)
- Commands run in a terminal split within Neovim

#### 3. Custom Arguments Window (`:MavenTestCustomArguments`)

Manage Maven arguments that automatically apply to all test commands:

**Layout:**
```
┌─────────────────────────────────────┐
│ Custom Maven Arguments              │
│                                     │
│ [x] -DskipITs                       │
│ [ ] -Dmaven.test.failure.ignore=true│
│ [x] -X                              │
│ ...                                 │
└─────────────────────────────────────┘
```

**Navigation:**
- `j/k` or arrow keys - Move cursor up/down
- `<Space>` or `<Enter>` - Toggle argument on/off
- `a` - Add new custom argument
- `m` - Edit the selected argument
- `d` - Delete the selected argument
- `q` or `<Esc>` - Close the window

**Features:**
- Arguments marked with `[x]` are active and will be appended to all Maven commands
- Useful for common flags like `-X` (debug), `-DskipITs`, or custom properties
- Arguments persist per project

#### 4. Command Editor (opened via `m` keymap)

When editing a command, a full-window text editor appears:

**Features:**
- Opens in **insert mode** for immediate editing
- Supports multi-line commands (though Maven commands are typically single-line)
- `<Enter>` in normal mode - Save changes and return to previous window
- `<Esc>` or `q` in normal mode - Cancel editing and return without saving

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
  -- Maven command to use (default: "mvn")
  maven_command = "mvn",
  
  -- Debug port for Maven Surefire debug mode (default: 5005)
  debug_port = 5005,
  
  -- Floating window configuration
  floating_window = {
    width = 0.8,        -- 80% of editor width (default: 0.8)
    height = 0.6,       -- 60% of editor height (default: 0.6)
    border = "rounded", -- Border style: "none", "single", "double", "rounded", "solid", "shadow" (default: "rounded")
  },
  
  -- Data directory for storing commands (auto-generated per project)
  -- Default: ~/.local/share/nvim/maven.nvim.test/<project-name>/
  -- data_dir = vim.fn.stdpath("data") .. "/maven.nvim.test/my-project",
})
```

### Default Configuration

If you don't call `setup()`, the plugin uses these defaults:
- `maven_command = "mvn"`
- `debug_port = 5005`
- `floating_window.width = 0.8`
- `floating_window.height = 0.6`
- `floating_window.border = "rounded"`
- `data_dir = ~/.local/share/nvim/maven.nvim.test/<current-directory-name>/`

## Debugging Tests

When using debug commands (`:MavenTestDebug`, `:MavenTestClassDebug`, `:MavenTestAllDebug`), Maven Surefire starts in debug mode and waits for a debugger to attach on port 5005 (configurable).

### Debug Workflow

1. **Run a debug command** (e.g., `:MavenTestDebug`)
2. **Maven will pause** and display: `Listening for transport dt_socket at address: 5005`
3. **Attach your Java debugger** to `localhost:5005`
4. **Set breakpoints** in your test code
5. **Continue execution** in your debugger

### Debugger Setup Examples

#### Using nvim-dap

```lua
local dap = require('dap')

-- Java debug configuration
dap.configurations.java = {
  {
    type = 'java',
    request = 'attach',
    name = 'Attach to Maven Tests',
    hostName = 'localhost',
    port = 5005,
  },
}

-- After running :MavenTestDebug, use :DapContinue to attach
```

#### Using IntelliJ IDEA

1. Run → Edit Configurations
2. Add New Configuration → Remote JVM Debug
3. Set Host: `localhost`, Port: `5005`
4. Run the debug configuration to attach

#### Using VS Code

Add to `.vscode/launch.json`:

```json
{
  "type": "java",
  "name": "Attach to Maven Tests",
  "request": "attach",
  "hostName": "localhost",
  "port": 5005
}
```

### Debug Port Configuration

Change the default debug port in your setup:

```lua
require('maven-test').setup({
  debug_port = 8000,  -- Use port 8000 instead of 5005
})
```

## Command Storage

The plugin stores Maven commands per project in:
```
~/.local/share/nvim/maven.nvim.test/<project-name>/
├── store.json          # Maven command templates
└── arguments.json      # Custom Maven arguments
```

### Command Store Behavior

- **Per-Project Isolation**: Each project has its own command store
- **Automatic Persistence**: Commands are saved automatically when added/edited/deleted
- **Most Recently Used**: Commands you use are moved to the top of the list
- **Uniqueness**: Duplicate commands are not added to the store
- **Restore Defaults**: Use `:MavenTestRestoreCommandsStore` to reset to default commands

### Default Commands

On first run, the plugin creates these default commands:

**Test Commands:**
- `mvn test` (run all tests)
- `mvn test -Dtest=%s` (run specific class or method)

**Debug Commands:**
- `mvn test -Dmaven.surefire.debug="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005"`
- `mvn test -Dtest=%s -Dmaven.surefire.debug=...`

**Maven Lifecycle Commands:**
- `mvn validate`
- `mvn compile`
- `mvn test`
- `mvn package`
- `mvn verify`
- `mvn install`
- `mvn deploy`
- `mvn clean`
- `mvn site`

### Custom Maven Arguments

Use `:MavenTestCustomArguments` to define arguments that apply to **all** Maven commands:

**Examples:**
- `-X` - Enable Maven debug output
- `-DskipITs` - Skip integration tests
- `-Dmaven.test.failure.ignore=true` - Continue build on test failures
- `-Dtest.parallel=methods` - Run tests in parallel
- `-Dmaven.repo.local=/custom/path` - Use custom local repository

Active arguments are automatically appended to every Maven command before execution.

## Supported Test Annotations

The plugin uses Treesitter to detect Java test methods with these annotations:

- `@Test` - Standard JUnit test methods
- `@ArchTest` - ArchUnit test methods and fields

**Example:**
```java
package com.example;

import org.junit.jupiter.api.Test;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

public class MyTest {
    @Test
    public void shouldDoSomething() {
        // JUnit test
    }
    
    @ArchTest
    public void architectureTest() {
        // ArchUnit test method
    }
    
    @ArchTest
    static final ArchRule layerRule = classes()...;  // ArchUnit test field
}
```

All three test types will appear in the test selector window.

## Troubleshooting

### Tests Not Detected

- **Check Treesitter**: Run `:TSInstall java` to install Java parser
- **Verify filetype**: Run `:set filetype?` - should show `filetype=java`
- **Check annotations**: Ensure test methods have `@Test` or `@ArchTest` annotations

### Commands Not Running

- **Verify Maven**: Run `:!mvn --version` to check Maven is in PATH
- **Check directory**: Ensure you're in a Maven project directory (with `pom.xml`)
- **Review terminal output**: Check the terminal split for Maven error messages

### Debug Not Working

- **Port in use**: Check if port 5005 is available: `lsof -i :5005` (Unix) or `netstat -an | findstr 5005` (Windows)
- **Debugger configuration**: Ensure your debugger is configured to attach to the correct port
- **Firewall**: Check firewall settings aren't blocking localhost connections

### Store Not Persisting

- **Check permissions**: Verify write permissions for `~/.local/share/nvim/maven.nvim.test/`
- **Disk space**: Ensure sufficient disk space
- **Reset store**: Use `:MavenTestRestoreCommandsStore` to restore defaults

## License

MIT License (2026)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development

- **Lua Style**: 2-space indentation, `local M = {}` module pattern
- **Commit Format**: `<type>: <description>` (e.g., `feat: add telescope integration`)
- **Testing**: Manually test with Java files before submitting PR

## Related Projects

- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - Required for test detection
- [nvim-dap](https://github.com/mfussenegger/nvim-dap) - For debugging tests with breakpoints

---

**Maven Test Runner for Neovim** - Run and debug Java tests without leaving your editor.

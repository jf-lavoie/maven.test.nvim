# maven.test.nvim - Technical Specification

## Overview

A Neovim plugin that provides Maven integration for testing Java projects. It uses Neovim's treesitter to detect Java test files and provides commands to run and debug tests using Maven.

**Version:** 1.0.0  
**License:** MIT (2026)

## Core Capabilities

Users can:
- Run a single test method
- Run an entire test class
- Run all tests in the project
- Debug tests with Maven Surefire debug mode (port 5005)
- Store and manage custom Maven commands per project
- Edit and delete stored commands via interactive UI
- Configure custom Maven arguments that apply to all commands
- View and run Maven lifecycle commands (compile, test, package, install, etc.)

## Project Structure

```
lua/maven-test/
├── init.lua              - Plugin entry point, setup, and configuration
├── functions.lua         - High-level orchestration functions (business logic)
├── user_commands.lua     - User command registration via FileType autocmd
│
├── store/
│   ├── store.lua         - Command storage and retrieval (key-value store)
│   ├── arguments.lua     - Custom arguments storage and management
│   ├── custom_argument.lua - CustomArgument class definition
│   └── persistence.lua   - Disk persistence layer (JSON serialization)
│
├── runner/
│   └── runner.lua        - Maven command execution in terminal
│
├── tests/
│   ├── parser.lua        - Treesitter-based test detection (methods/fields)
│   └── ui.lua            - Test selector UI (two-pane layout)
│
├── commands/
│   └── ui.lua            - Maven commands list UI
│
└── ui/
    └── ui.lua            - Core UI components (FloatingWindow, command editor)

plugin/init.lua           - Plugin entry point with <Plug> mapping definitions
ftplugin/java.lua         - Java-specific settings (optional)
doc/maven-test.txt        - Vim help documentation
```

## Feature Definitions

### 1. Treesitter-Based Test Detection
- **Purpose**: Automatically identify test methods and fields in Java files
- **Supported Annotations**: 
  - `@Test` - Standard JUnit test methods
  - `@ArchTest` - ArchUnit test methods and fields
- **Detection Mechanism**: Treesitter queries parse Java AST to find annotated methods and fields
- **Extraction**: Method/field name, line number, type

### 2. Test Execution Modes
- **Single Method**: Run one specific test method via Maven `-Dtest=ClassName#methodName`
- **Test Class**: Run all tests in the current Java class via Maven `-Dtest=ClassName`
- **All Tests**: Run entire test suite via Maven `test` goal
- **Debug Mode**: All execution modes support debug flag `-Dmaven.surefire.debug` for remote debugging

### 3. Interactive UI System
- **Test Selector UI** (`tests/ui.lua`):
  - Two-pane floating window layout
  - Top pane: Test actions list (methods and class-level tests)
  - Bottom pane: Command preview showing Maven commands to be executed
  - Navigation: `j/k` for movement, `<Space>` to switch panes, `<Enter>` to execute
  - Command management: `m` to edit, `d` to delete commands
  
- **Command List UI** (`commands/ui.lua`):
  - Single-pane floating window showing stored Maven commands
  - Displays all Maven lifecycle commands (compile, test, package, install, etc.)
  - Actions: `<Enter>/<Space>` to run, `m` to edit, `d` to delete
  
- **Command Editor** (`ui/ui.lua`):
  - Floating window for editing command text
  - Opens in insert mode for immediate editing
  - `<Enter>` in normal mode to save, `<Esc>/q` to cancel

### 4. Command Storage System
- **Per-Project Storage**: Each project has isolated command store
- **Storage Location**: `~/.local/share/nvim/maven.nvim.test/<project-name>/`
  - `store.json` - Maven command templates
  - `arguments.json` - Custom Maven arguments
- **Command Types**:
  - `run_all` - Run all tests
  - `run_class` - Run test class (uses `%s` placeholder)
  - `run_method` - Run test method (uses `%s` placeholder)
  - `run_all_debug` - Debug all tests
  - `run_class_debug` - Debug test class
  - `run_method_debug` - Debug test method
  - `commands` - Maven lifecycle commands (compile, package, install, etc.)
- **Features**:
  - Multiple commands per action type
  - Most recently used command appears first
  - Uniqueness guarantee (no duplicates)
  - Automatic persistence on modifications

### 5. Custom Arguments System
- **Purpose**: Define Maven arguments that apply to all commands
- **Storage**: `arguments.json` in project data directory
- **Argument Structure**:
  - `text` - The Maven argument string
  - `active` - Boolean flag to enable/disable
- **Application**: Active arguments are appended to all Maven commands before execution
- **UI**: Dedicated editor for viewing, adding, editing, and toggling arguments

### 6. Terminal Integration
- **Execution**: Maven commands run in Neovim terminal buffer
- **Layout**: Terminal split opens at bottom of editor
- **Output**: Real-time Maven output display
- **Interactive**: Terminal starts in insert mode for user interaction

### 7. Debug Support
- **Maven Surefire Debug Mode**: Adds `-Dmaven.surefire.debug` with JDWP agent configuration
- **Default Port**: 5005 (configurable)
- **JDWP Settings**: `transport=dt_socket,server=y,suspend=y,address=<port>`
- **Workflow**: Maven waits for debugger attachment before running tests
- **Compatible With**: nvim-dap, IntelliJ IDEA, VS Code, or any JDWP-compliant debugger

## User Commands

All commands are registered as buffer-local commands via `FileType` autocmd for Java files.

### Test Execution Commands
- `:MavenTest` - Opens floating window to select and run a specific test method
- `:MavenTestClass` - Runs all tests in the current class
- `:MavenTestAll` - Runs all tests in the project

### Debug Commands
- `:MavenTestDebug` - Opens floating window to select and debug a specific test method
- `:MavenTestClassDebug` - Debugs all tests in the current class
- `:MavenTestAllDebug` - Debugs all tests in the project

### Management Commands
- `:MavenTestCommands` - Opens floating window to view, edit, delete, and run stored Maven commands
- `:MavenTestCustomArguments` - Opens UI to manage custom Maven arguments
- `:MavenTestRestoreCommandsStore` - Restores the command store to default state

## Keymaps

### <Plug> Mappings (User-Defined)

The plugin provides `<Plug>` mappings **without default keybinds**. Users must define their own mappings.

**Available Mappings:**
- `<Plug>(maven-test)` - `:MavenTest`
- `<Plug>(maven-test-class)` - `:MavenTestClass`
- `<Plug>(maven-test-all)` - `:MavenTestAll`
- `<Plug>(maven-test-debug)` - `:MavenTestDebug`
- `<Plug>(maven-test-class-debug)` - `:MavenTestClassDebug`
- `<Plug>(maven-test-all-debug)` - `:MavenTestAllDebug`
- `<Plug>(maven-test-commands)` - `:MavenTestCommands`
- `<Plug>(maven-test-custom-arguments)` - `:MavenTestCustomArguments`

### User Mapping Examples

**Global mappings:**
```lua
vim.keymap.set('n', '<leader>Xt', '<Plug>(maven-test)', { desc = 'Maven: Run test' })
vim.keymap.set('n', '<leader>Xc', '<Plug>(maven-test-class)', { desc = 'Maven: Run class' })
vim.keymap.set('n', '<leader>Xa', '<Plug>(maven-test-all)', { desc = 'Maven: Run all tests' })
```

**Filetype-specific mappings (via autocmd):**
```lua
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function()
    vim.keymap.set('n', '<leader>Xt', '<Plug>(maven-test)', { buffer = true })
  end
})
```

**Filetype-specific mappings (via ftplugin/java.lua):**
```lua
vim.keymap.set('n', '<leader>Xt', '<Plug>(maven-test)', { buffer = true })
```

## Configuration

The plugin can be configured via `setup()`:

```lua
require('maven-test').setup({
  maven_command = "mvn",           -- Maven command to use
  debug_port = 5005,               -- Port for Maven Surefire debug mode
  floating_window = {
    width = 0.8,                   -- 80% of editor width
    height = 0.6,                  -- 60% of editor height
    border = "rounded",            -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
  },
  data_dir = "<auto-generated>",   -- Command store location (default: per-project)
})
```

**Default Configuration:**
- `maven_command`: `"mvn"`
- `debug_port`: `5005`
- `floating_window.width`: `0.8` (80% of editor width)
- `floating_window.height`: `0.6` (60% of editor height)
- `floating_window.border`: `"rounded"`
- `data_dir`: `~/.local/share/nvim/maven.nvim.test/<project-name>/`

**Data Directory Structure:**
- Automatically derived from current working directory
- Project name: `vim.fn.fnamemodify(vim.fn.getcwd(), ":t")`
- Location: `vim.fn.stdpath("data") .. "/maven.nvim.test/" .. project_name`

## UI Behavior

### Test Selector UI (`:MavenTest`, `:MavenTestDebug`)

When the user triggers `:MavenTest` or `:MavenTestDebug`:

1. A floating window appears with two sections:
   - **Top section (actions)**: List of test methods and option to run all tests in class
   - **Bottom section (commands)**: Preview of Maven command(s) that will be executed

2. Navigation:
   - Use `j/k` or arrow keys to move through the list in the actions section
   - Press `<Space>` to switch focus to the commands section
   - Press `<Enter>` to execute the selected test
   - Press `m` in commands section to edit the selected command
   - Press `d` in commands section to delete the selected command (if more than one exists)
   - Press `q` or `<Esc>` to close the window

3. The preview updates dynamically as the cursor moves to show the exact command(s) for the selected item

4. Upon selection, a terminal split opens at the bottom showing Maven output in real-time

### Command List UI (`:MavenTestCommands`)

When the user triggers `:MavenTestCommands`:

1. A floating window displays all stored Maven commands for the current action type

2. Navigation:
   - Use `j/k` or arrow keys to move through the command list
   - Press `<Enter>` or `<Space>` to execute the selected command
   - Press `m` to edit the selected command
   - Press `d` to delete the selected command
   - Press `q` or `<Esc>` to close the window

3. The command list updates automatically when commands are deleted

### Command Editor

When editing a command (via `m` keymap):

1. A floating window appears with the current command as editable text
2. The editor starts in insert mode for immediate editing
3. Press `<Enter>` in normal mode to save changes and return to the previous UI
4. Press `<Esc>` or `q` in normal mode to cancel and return without saving

## Parser Details

The parser (`parser.lua`) uses treesitter queries to find:

- **`@Test` methods**: Standard JUnit test methods
- **`@ArchTest` methods**: ArchUnit test methods
- **`@ArchTest` fields**: ArchUnit test rules defined as fields

It extracts:
- Method/field name
- Line number
- Type (currently always "method")

## Runner Details

The runner (`runner.lua`) constructs Maven commands:

- **Run method**: `mvn test -Dtest=com.example.ClassName#methodName`
- **Run class**: `mvn test -Dtest=com.example.ClassName`
- **Run all**: `mvn test`
- **Debug mode**: Adds `-Dmaven.surefire.debug` flag (Surefire waits on port 5005)

Commands are executed in a new terminal split using `jobstart()` with `term = true`.

## Command Store

The store maintains multiple Maven command templates per action type. Keys used:

- `run_all` - Command to run all tests
- `run_class` - Command template to run a test class (uses `%s` placeholder)
- `run_method` - Command template to run a test method (uses `%s` placeholder)
- `run_all_debug` - Debug version of run_all
- `run_class_debug` - Debug version of run_class
- `run_method_debug` - Debug version of run_method

### Store API

Located in `store.lua`:

```lua
-- Add command to store (inserts at front if unique)
add_to_store(key, value)

-- Remove command from store
remove_from_store(key, value)

-- Get first command for key (most recently used)
first(key)

-- Get all commands for key
get(key)

-- Load store from disk
load()
```

### Store Persistence

Located in `store_persistence.lua`:

```lua
-- Initialize with data directory path
initialize(datadir)

-- Save store to disk as JSON
save(store_data)

-- Load store from disk
load()
```

Store file location: `~/.local/share/nvim/maven.nvim.test/<project-name>/store.json`


### UI Modules

The UI is split into three modules:

- **`ui.lua`**: Core floating window components and the command editor
  - `FloatingWindow` class for creating floating windows
  - `show_command_editor()` function for editing commands
  
- **`ui-tests.lua`**: Test selector with two-pane layout
  - Top pane: Lists test methods and test class with line numbers
  - Bottom pane: Shows available commands for the selected test
  - Supports navigation between panes with `<Space>`
  - Allows editing (`m`) and deleting (`d`) commands from the bottom pane
  
- **`ui-commands.lua`**: Command list viewer and manager
  - Single-pane window showing all stored commands for an action
  - Supports running (`<Enter>`), editing (`m`), and deleting (`d`) commands
  - Updates the UI automatically after deletions<Enter>, q and <Esc>).

## Development Patterns

### Architecture Principles

1. **Separation of Concerns**: Each module has a single, well-defined responsibility
   - `parser.lua`: Treesitter integration and test detection
   - `runner.lua`: Maven command construction and execution
   - `ui.lua`: Core UI components (FloatingWindow class, command editor)
   - `tests/ui.lua`: Test-specific UI (two-pane test selector)
   - `commands/ui.lua`: Maven commands UI
   - `store/store.lua`: In-memory command storage (key-value store)
   - `store/persistence.lua`: Disk I/O and JSON serialization
   - `store/arguments.lua`: Custom arguments storage
   - `user_commands.lua`: Neovim command registration
   - `functions.lua`: Business logic orchestration

2. **Module Dependency Flow**
   ```
   plugin/init.lua (defines <Plug> mappings)
        ↓
   user_commands.lua (registers :Maven* commands via FileType autocmd)
        ↓
   functions.lua (orchestrates business logic)
        ↓
   ┌────────────┬─────────────┬───────────────┬──────────────┐
   ↓            ↓             ↓               ↓              ↓
   tests/ui    commands/ui   runner/runner   store/store   tests/parser
        ↓            ↓             ↓               ↓
   ui/ui.lua    ui/ui.lua     store/arguments   store/persistence
                                    ↓
                              store/custom_argument
   ```

3. **Initialization Pattern**
   - Plugin auto-initializes via `plugin/init.lua` on first load
   - User commands are registered lazily per-buffer via `FileType` autocmd
   - Store is loaded once on first use (lazy initialization with memoization)
   - Default commands are added to store if not present

4. **Store-First Architecture**
   - Commands are stored in the store, not hard-coded
   - UI displays commands from the store
   - Runner executes commands from the store
   - Modifications persist automatically to disk

5. **UI Component Pattern**
   - `FloatingWindow` class: Reusable base component for all floating windows
   - Specialized UI modules: `tests/ui.lua`, `commands/ui.lua` use FloatingWindow
   - Command editor: Shared by all UIs for consistent editing experience

### Code Patterns

#### Store Operations
```lua
-- Always check if store has value before using
local commands = store.get(key)  -- Returns array (never nil)
if #commands > 0 then
  local cmd = commands[1]  -- First is most recently used
end

-- Add to store (idempotent, uniqueness enforced)
store.add(key, value)

-- Remove from store
store.remove(key, value)

-- Get first (most recent)
local cmd = store.first(key)  -- Returns first item or nil
```

#### Lazy Initialization
```lua
local initialized = false

local function _initialize()
  if initialized then return end
  initialized = true
  -- initialization code
end

function M.some_function()
  _initialize()
  -- function logic
end
```

#### FloatingWindow Usage
```lua
local FloatingWindow = require("maven-test.ui.ui").FloatingWindow

local win = FloatingWindow.new({
  width = 0.8,
  height = 0.6,
  border = "rounded",
})

win:show(lines)  -- Display content
win:close()       -- Close window
```

#### Command Execution
```lua
-- Always format command with placeholder
local cmd_template = store.first(RUN_METHOD_KEY)
local cmd = string.format(cmd_template, fully_qualified_test)

-- Append custom arguments before execution
for _, arg in ipairs(custom_arguments) do
  if arg.active then
    cmd = arg:append_to_command(cmd)
  end
end

-- Execute
runner.run_command(cmd)
```

### Testing Patterns

- Test detection via treesitter queries (no regex parsing)
- Package name extraction: Parse first 50 lines for `package` declaration
- Class name extraction: Use treesitter query for `class_declaration`
- Fully qualified test name: `package.ClassName#methodName`

### Error Handling Patterns

```lua
-- Check for required data
if not class_name or not package_name then
  vim.notify("Could not determine test class or package", vim.log.levels.ERROR)
  return
end

-- Graceful degradation: If treesitter unavailable, class/all tests still work
```

### UI Interaction Patterns

```lua
-- Keymap registration in buffers
vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Enter>', '', {
  callback = function() execute_action() end,
  noremap = true,
  silent = true,
})

-- Cursor position tracking
vim.api.nvim_win_get_cursor(win)

-- Dynamic content update
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
```

## Non-Functional Requirements

### Store Guarantees

1. **Non-nil Guarantee**: Store operations always return non-nil values
   - `store.get(key)` returns empty array `{}` if key doesn't exist
   - `store.first(key)` returns `nil` if key doesn't exist or array is empty

2. **Uniqueness**: Store enforces uniqueness per key
   - Adding duplicate value has no effect
   - Uniqueness check uses string equality

3. **Order Preservation**: Most recently used items appear first
   - New items inserted at index 1
   - Existing items maintain their position

4. **Automatic Persistence**: Store saves to disk after each modification
   - `add()` triggers save
   - `remove()` triggers save
   - Failed saves do not crash the plugin

5. **Per-Project Isolation**: Each project has its own isolated store
   - Store location based on project directory name
   - No cross-project data leakage

### Keymap Requirements

1. **<Plug> Mappings Only**: All keymaps must be `<Plug>` type
   - Allows user customization
   - No default keybinds provided by plugin

2. **User-Defined Mappings**: Users must define their own keymaps
   - Document examples in README
   - Support both global and buffer-local mappings

3. **Buffer-Local Commands**: User commands registered per-buffer
   - Commands only available in Java buffers
   - Registered via `FileType` autocmd

### Performance

1. **Lazy Loading**: Plugin loads only when needed
   - Commands registered on Java file open
   - Store initialized on first use
   - No overhead for non-Java files

2. **Fast Parsing**: Treesitter queries are efficient
   - Only current buffer is parsed
   - Queries run on-demand, not continuously

3. **Async Execution**: Maven commands run asynchronously
   - Terminal job runs in background
   - Editor remains responsive
   - No blocking operations

4. **Minimal Memory**: Store kept in memory, synced to disk
   - Small JSON files per project
   - No large data structures in memory

### Reliability

1. **Graceful Degradation**: Plugin works without treesitter
   - Test method selection requires treesitter
   - Class and all-tests commands work without treesitter
   - Clear error messages when treesitter unavailable

2. **Error Handling**: Invalid operations display clear errors
   - Missing Maven command
   - Missing package/class name
   - Corrupt store files

3. **Safe Persistence**: Store corruption does not crash plugin
   - JSON parse errors caught
   - Empty store returned on parse failure
   - User can restore defaults with `:MavenTestRestoreCommandsStore`

4. **Data Validation**: Store validates data before saving
   - Empty commands not added to store
   - Invalid argument structures rejected

### User Experience

1. **Real-time Feedback**: UI updates immediately
   - Command preview updates on cursor movement
   - Command list updates after deletion
   - Notifications for actions (info, error levels)

2. **Terminal Integration**: Maven runs in Neovim terminal
   - Output visible in editor
   - Terminal split at bottom
   - Starts in insert mode for interaction

3. **Visual Clarity**: UI separates concerns
   - Test selector: actions (top) vs commands (bottom)
   - Command editor: full-window editing experience
   - Clear visual boundaries between sections

4. **Intuitive Navigation**: Standard Vim keybinds
   - `j/k` for movement
   - `<Enter>` for selection/execution
   - `<Esc>/q` for cancel/close
   - `<Space>` for pane switching (test selector)

5. **Consistent Behavior**: All UIs follow same patterns
   - `m` to edit command
   - `d` to delete command
   - Same command editor for all contexts

## Implementation Details

### Plugin Initialization

1. **Entry Point**: `plugin/init.lua`
   - Registers `FileType` autocmd for Java files
   - Defines `<Plug>` mappings for user customization
   - Does NOT call `setup()` automatically

2. **User Commands Registration**: `user_commands.lua`
   - Triggered by `FileType` autocmd when Java file opened
   - Creates buffer-local commands (`:MavenTest`, etc.)
   - Calls `ensure_loaded()` to initialize plugin if needed

3. **Setup Function**: `init.lua`
   - Merges user config with defaults
   - Initializes data directory path
   - Sets `vim.g.loaded_maven_test = 1` flag

4. **Store Initialization**: `functions.lua`
   - Lazy initialization via `_initialize()` function
   - Loads store from disk on first use
   - Adds default commands if store is empty

### Store API

**Location**: `store/store.lua`

```lua
-- Core operations
M.add(key, value)       -- Add command to store (idempotent)
M.remove(key, value)    -- Remove command from store
M.get(key)              -- Get all commands for key (returns array)
M.first(key)            -- Get first command for key (returns string or nil)
M.load()                -- Reload store from disk
M.empty_store()         -- Clear all store data

-- Keys used:
-- "run_all", "run_class", "run_method"
-- "run_all_debug", "run_class_debug", "run_method_debug"
-- "commands" (Maven lifecycle commands)
```

### Arguments API

**Location**: `store/arguments.lua`

```lua
-- Operations
M.add(arg)              -- Add custom argument (CustomArgument object)
M.update(arg)           -- Update argument's active state
M.remove(arg)           -- Remove argument
M.list()                -- Get all arguments (returns array)

-- CustomArgument structure:
{
  text = "maven-argument-string",
  active = true/false,
  append_to_command = function(cmd) return cmd .. " " .. self.text end
}
```

### Persistence Layer

**Location**: `store/persistence.lua`

```lua
-- Persistence class
local p = Persistence.new("filename.json")
p:save(data)            -- Save data to JSON file
p:load()                -- Load data from JSON file (returns table)

-- Error handling:
-- - Returns {} on parse failure
-- - Creates directory if missing
-- - Logs errors via vim.notify
```

### Parser Details

**Location**: `tests/parser.lua`

Treesitter queries detect:
```lua
-- @Test annotated methods
(method_declaration
  (modifiers (marker_annotation name: (identifier) @annotation))
  name: (identifier) @method_name)

-- @ArchTest annotated methods
(method_declaration
  (modifiers (marker_annotation name: (identifier) @annotation))
  name: (identifier) @method_name)

-- @ArchTest annotated fields
(field_declaration
  (modifiers (marker_annotation name: (identifier) @annotation))
  declarator: (variable_declarator name: (identifier) @field_name))

-- Class declaration
(class_declaration name: (identifier) @class_name)

-- Package declaration (regex fallback)
"^package%s+([%w%.]+)" in first 50 lines
```

**Extracted Data**:
```lua
{
  name = "testMethodName",
  line = 42,
  type = "method"  -- Currently always "method" even for fields
}
```

### Runner Details

**Location**: `runner/runner.lua`

**Command Construction**:
```lua
-- Single method
"mvn test -Dtest=com.example.ClassName#methodName"

-- Test class
"mvn test -Dtest=com.example.ClassName"

-- All tests
"mvn test"

-- Debug mode (adds to any command)
' -Dmaven.surefire.debug="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005"'
```

**Execution Flow**:
1. Get command template from store
2. Format with test name (if applicable)
3. Append active custom arguments
4. Open terminal split (`botright split | enew`)
5. Start job with `jobstart(command, { term = true })`
6. Enter insert mode in terminal

### UI Component Details

**FloatingWindow Class** (`ui/ui.lua`):
```lua
local win = FloatingWindow.new({
  width = 0.8,   -- 80% of editor width
  height = 0.6,  -- 60% of editor height
  border = "rounded",
})

win:show(lines)  -- Create/update window with content
win:close()      -- Close window and buffer
win.bufnr        -- Buffer number
win.winid        -- Window ID
```

**Test Selector UI** (`tests/ui.lua`):
- Two-pane layout using horizontal split
- Top pane: Test actions (class + methods)
- Bottom pane: Command preview
- Keymaps: `j/k`, `<Space>`, `<Enter>`, `m`, `d`, `q`, `<Esc>`

**Command List UI** (`commands/ui.lua`):
- Single-pane layout
- Shows all Maven commands from store
- Keymaps: `j/k`, `<Enter>`, `<Space>`, `m`, `d`, `q`, `<Esc>`

**Command Editor** (`ui/ui.lua`):
- Full-window text editor
- Starts in insert mode
- Multi-line support
- Keymaps: `<Enter>` (save), `<Esc>/q` (cancel)

### Default Commands

Added to store on first initialization:

```lua
-- Test execution
"mvn test"                           -- run_all
"mvn test -Dtest=%s"                 -- run_class, run_method

-- Debug mode
'mvn test -Dmaven.surefire.debug="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005"'  -- run_all_debug
'mvn test -Dtest=%s -Dmaven.surefire.debug="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005"'  -- run_class_debug, run_method_debug

-- Maven lifecycle commands (in order)
"mvn validate"
"mvn compile"
"mvn test"
"mvn package"
"mvn verify"
"mvn install"
"mvn deploy"
"mvn clean"
"mvn site"
```

## Testing Strategy

### Manual Testing Checklist

1. **Test Detection**
   - [ ] Detect `@Test` methods
   - [ ] Detect `@ArchTest` methods
   - [ ] Detect `@ArchTest` fields
   - [ ] Extract correct line numbers
   - [ ] Handle files without tests

2. **Test Execution**
   - [ ] Run single test method
   - [ ] Run test class
   - [ ] Run all tests
   - [ ] Debug mode for each execution type
   - [ ] Custom arguments apply correctly

3. **Store Operations**
   - [ ] Add commands (uniqueness enforced)
   - [ ] Remove commands
   - [ ] Load/save from disk
   - [ ] Per-project isolation
   - [ ] Restore defaults

4. **UI Interactions**
   - [ ] Test selector navigation
   - [ ] Pane switching in test selector
   - [ ] Command editor opens/saves/cancels
   - [ ] Command deletion updates UI
   - [ ] Commands list UI

5. **Error Handling**
   - [ ] Missing treesitter parser
   - [ ] No tests in file
   - [ ] Invalid Maven command
   - [ ] Corrupt store file

### Integration Points to Test

- Treesitter Java parser
- Neovim terminal integration
- File system I/O (store persistence)
- Maven command execution
- Debugger attachment (JDWP)

## Common Development Tasks

### Adding a New User Command

1. Add command to `user_commands.lua`:
   ```lua
   vim.api.nvim_buf_create_user_command(args.buf, "MavenNewCommand", function()
     ensure_loaded()
     require("maven-test.functions").new_function()
   end, { desc = "Description" })
   ```

2. Add function to `functions.lua`:
   ```lua
   function M.new_function()
     _initialize()
     -- implementation
   end
   ```

3. Add `<Plug>` mapping to `plugin/init.lua`:
   ```lua
   vim.keymap.set("n", "<Plug>(maven-new-command)", ":MavenNewCommand<CR>", { silent = true })
   ```

### Adding a New Store Key

1. Define constant in `functions.lua`:
   ```lua
   local NEW_KEY = "new_key"
   ```

2. Add default command in `_default_commands()`:
   ```lua
   if #store.get(NEW_KEY) == 0 then
     store.add(NEW_KEY, "mvn new-goal")
   end
   ```

3. Use in function:
   ```lua
   local cmd = store.first(NEW_KEY)
   require("maven-test.runner.runner").run_command(cmd)
   ```

### Adding a New UI Component

1. Create function in appropriate UI module:
   ```lua
   function M.show_new_ui(get_items, delete_item, update_item)
     local FloatingWindow = require("maven-test.ui.ui").FloatingWindow
     local win = FloatingWindow.new(config)
     
     -- Setup keymaps
     -- Display content
     
     win:show(lines)
   end
   ```

2. Call from `functions.lua`:
   ```lua
   function M.show_new_ui()
     _initialize()
     require("maven-test.new.ui").show_new_ui(
       function() return store.get(KEY) end,
       function(val) store.remove(KEY, val) end,
       function(val) store.add(KEY, val) end
     )
   end
   ```

### Modifying Command Templates

Edit `_default_commands()` in `functions.lua`:
```lua
if #store.get(RUN_METHOD_KEY) == 0 then
  store.add(RUN_METHOD_KEY, options.maven_command .. " test -Dtest=%s -DnewFlag")
end
```

### Adding Custom Argument Types

1. Extend `CustomArgument` class in `custom_argument.lua`:
   ```lua
   function CustomArgument:new_method()
     -- implementation
   end
   ```

2. Update `append_to_command()` logic if needed

3. Update UI in `ui/ui.lua` to display new properties

## Troubleshooting

### Store Not Persisting

- Check data directory exists: `~/.local/share/nvim/maven.nvim.test/<project>/`
- Verify write permissions
- Check for JSON syntax errors in store files
- Use `:MavenTestRestoreCommandsStore` to reset

### Treesitter Not Finding Tests

- Verify Java parser installed: `:TSInstall java`
- Check annotation syntax matches expected patterns
- Test files must have `@Test` or `@ArchTest` annotations
- Ensure file is recognized as Java: `:set filetype?`

### Commands Not Running

- Verify Maven is in PATH: `:!mvn --version`
- Check command format in store (correct placeholders)
- Review terminal output for Maven errors
- Ensure current directory is Maven project root

### Debug Mode Not Working

- Verify debug port is not in use: `lsof -i :5005` (Unix) or `netstat -an | findstr 5005` (Windows)
- Check debugger configuration matches port
- Ensure Maven Surefire plugin supports debug mode
- Look for JDWP agent errors in terminal output

## Known Limitations

1. **Single Terminal Strategy**: Only one test terminal at a time
   - Opening new test closes previous terminal
   - Cannot run multiple tests in parallel

2. **Treesitter Dependency**: Test method selection requires treesitter
   - Must have Java parser installed
   - Falls back to class/all tests if unavailable

3. **Maven-Specific**: Only supports Maven (not Gradle, Ant, etc.)
   - Commands assume Maven Surefire plugin
   - Debug mode uses Surefire-specific flags

4. **Package Detection**: Limited to first 50 lines
   - Package declaration must be near top of file
   - Non-standard package declarations may not be detected

5. **Command Placeholders**: Only supports `%s` placeholder
   - Cannot use multiple placeholders in one command
   - Placeholder replacement is simple string formatting

6. **No Test Result Parsing**: Terminal output is raw Maven output
   - No test result summary in UI
   - No test failure navigation

7. **Project Detection**: Based on current working directory
   - Changing CWD changes active project
   - No support for multi-module Maven projects

## Future Enhancements

### Planned Features
- [ ] Integration with telescope/fzf for better selection UI
- [ ] Per-project configuration files (`.maven-test.json`)
- [ ] Support for additional test frameworks (TestNG, Spock, etc.)
- [ ] Command history with timestamp and result tracking
- [ ] Ability to rerun last test without opening selector
- [ ] Command templates with user-defined variables (e.g., `${PROJECT_ROOT}`)
- [ ] Test result parsing and summary display
- [ ] Quick fix list integration for test failures
- [ ] Parallel test execution in multiple terminals
- [ ] Multi-module Maven project support
- [ ] Custom keymaps per project (stored in project data dir)

### Possible Improvements
- [ ] Test coverage display integration
- [ ] Test execution time tracking
- [ ] Failed test history and quick access
- [ ] Maven goal completion in command editor
- [ ] Argument templates library (common Maven flags)
- [ ] Export/import command templates between projects
- [ ] CI/CD integration (run same commands locally as in CI)
- [ ] Watch mode (auto-rerun tests on file save)
- [ ] Test tagging and filtering (JUnit 5 tags)
- [ ] Parameterized test support (display parameter values)

## Changelog

### Version 1.0.0 (2026)
- Initial release
- Treesitter-based test detection (`@Test`, `@ArchTest`)
- Run single test, test class, or all tests
- Debug mode with Maven Surefire remote debugging
- Interactive floating window UI with test selector
- Command storage and persistence per project
- Command editing and deletion via UI
- Custom arguments system
- Maven lifecycle commands viewer
- `<Plug>` mappings for user-defined keybinds
- Per-project command stores in `~/.local/share/nvim/`

## License

MIT License (2026)

## Contributing Guidelines

### Code Style
- Use Lua 5.1 compatible syntax (Neovim's Lua version)
- 2-space indentation (tabs converted to spaces)
- Local variables preferred over globals
- Module pattern: `local M = {}` with `return M`
- Function naming: `snake_case` for local functions, `M.snake_case` for exports

### Module Organization
- Keep modules focused on single responsibility
- Use separate files for UI, logic, and storage
- Avoid circular dependencies
- Document public API functions with comments

### Commit Messages
- Format: `<type>: <description>`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- Example: `feat: add telescope integration for test selection`

### Pull Request Guidelines
1. Create feature branch from `main`
2. Add tests if applicable
3. Update documentation (README, copilot-instructions)
4. Ensure no breaking changes to public API
5. Provide clear PR description with use case

### Testing Before PR
- [ ] Manual test with Java test files
- [ ] Test with and without treesitter
- [ ] Test store persistence (add/edit/delete)
- [ ] Test debug mode
- [ ] Test with custom arguments
- [ ] Verify no Lua errors (`:messages`)

---

## Quick Reference

### Key Files
- `lua/maven-test/init.lua` - Plugin setup and config
- `lua/maven-test/functions.lua` - Main orchestration logic
- `lua/maven-test/user_commands.lua` - Command registration
- `plugin/init.lua` - Plugin entry point and `<Plug>` mappings

### Key Commands
- `:MavenTest` - Run test selector
- `:MavenTestClass` - Run current class
- `:MavenTestAll` - Run all tests
- `:MavenTestCommands` - View/manage commands
- `:MavenTestCustomArguments` - Manage custom arguments
- `:MavenTestRestoreCommandsStore` - Reset to defaults

### Key Keymaps (in UI)
- `j/k` - Navigate
- `<Enter>` - Execute/select
- `<Space>` - Switch pane (test selector)
- `m` - Edit command
- `d` - Delete command
- `q/<Esc>` - Close window

# maven.test.nvim

This project is a nvim plugin. It provides integration with Maven for testing Java projects.
Using nvim treesitter, it detects Java test files and provides commands to run tests using Maven.

The user can select to run a single test function or a test class or the whole suits of tests.


## Features

- use treesitter to detect Java test files, classes, and functions
- chose to run a specific test function, a test class, or all tests
- test output in a terminal window inside nvim
- debug test. Start the test in debug mode with breakpoints



## How user interacts with the plugin

Once the user trigger the configured shortcut, a floating window appears with the list of detected test functions and classes.
The user can navigate using the arrows to go up in the tree or go down. On every list item change, the list is updated to show the relevant test functions or classes.
When the user selects a test function or class, the plugin runs the corresponding Maven command to execute the tests.

The default mappings are:
- <leader>Mt : run all tests
- <leader>Mc : open the test class selection window
- <leader>Ml : open the test local function selection window


## Plugin features guidelines

When a user selects a test or a series of test to run, a command terminal window opens at the bottom of nvim, showing the Maven output in real time.

The custom user commands should exists only when in a Java file.

The plugin should support tests that are annotated with @Test and @ArchTest annotations.

The plugin displays the command that is going to be executed in the picker. The picker display 2 areas. The method and classes on the top and the command that will be executed if the given line is selected in the bottom area.

<!---->
<!-- ## Feature: edit commands -->
<!---->
<!-- This feature allows the users to edit their command they want to run.  -->
<!-- The plugin provide defaults commands to execute the tests. But the users should be able to edit those commands. -->
<!-- The edited commands are saved in $HOME/.local/share/nvim/maven.nvin.test/<project-name>/<function name>.custom -->
<!-- on opening the app, the custom commands are loaded into the plugin. -->
<!---->
<!---->


### Future improvements

* integration with pickers for better selection UI
* display command to be executed in the floating window before running the tests
* ability to add custom arguments to commands. This should be done on a per project basis, maybe using a configuration file.
* ability to configure which test specs to use (e.g., JUnit, TestNG, ArchUnit, etc.)





## commands store

Users are able to choose and edit their commands. 


The commands store is a store to save commands. The key is the command name and the value is all the possible values the users have created for this command.

It's API is:

-- add a new value to the key. If key is non existent, an array with a single item (the value) is created.
-- if the key exists, the values is inserted in the array at the first position if it does not already exists.
add_to_store(key, value) 

-- removes the value in the key's array
remove_from_store(key, value)

-- returns the first element of the array at key
first(key)

-- returns the array of values at key. If key does not exists, return an empty array
get(key)


### store persistence

store persistence is another component that saves the store to the disk and load it from the disk. 

It's api is:

-- constructor takes a path to where data should be saved
new(path)

-- saves the store to the disk
save(store)

-- loads the store from disk and returns a store
load()

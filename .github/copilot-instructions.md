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


## Plugin guidelines

When a user selects a test or a series of test to run, a command terminal window opens at the bottom of nvim, showing the Maven output in real time.

The custom user commands should exists only when in a Java file.





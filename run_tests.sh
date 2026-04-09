#!/bin/bash
# Run mini.test tests

TEST_FILE="${1:-tests/key_value_store_spec.lua}"

nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "lua MiniTest = require('mini.test'); MiniTest.run_file('$TEST_FILE')" \
  -c "quitall"

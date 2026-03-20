--- Maven command store module
--- Manages storage and retrieval of Maven command templates
--- Store structure: { [key: string]: string[] }
--- Commands are stored as arrays, with most recently used first
--- @module 'maven-test.commands.store'

local KeyValuesStore = require("maven-test.store.key_values_store").KeyValuesStore

--- In-memory key-value store where values are arrays of strings
local store = KeyValuesStore.new("store.json")

return store

--- Maven command store module
--- Manages storage and retrieval of Maven command templates
--- Store structure: { [key: string]: string[] }
--- Commands are stored as arrays, with most recently used first
--- @module 'maven-test.commands.store'

local KeyValueStore = require("maven-test.store.key_values_store").KeyValueStore

--- In-memory key-value store where values are arrays of strings
local store = KeyValueStore.new("store.json")

return store

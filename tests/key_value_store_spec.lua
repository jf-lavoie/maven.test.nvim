local MiniTest = require("mini.test")
local new_set = MiniTest.new_set

local function get_test_file_path(filename)
	return vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_/test-project/" .. filename
end

local T = new_set({
	hooks = {
		pre_case = function()
			require("maven-test").config.data_dir = vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_"
			-- Clean up any test files before each test
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
		post_once = function()
			-- Clean up after all tests
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

local KeyValueStore = require("maven-test.store.key_value_store").KeyValueStore

-- Helper to create a test file path

T["KeyValueStore.new"] = new_set({
	hooks = {
		pre_case = function()
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

T["KeyValueStore.new"]["creates new instance"] = function()
	local store = KeyValueStore.new("test.json")
	MiniTest.expect.no_equality(store, nil)
	MiniTest.expect.equality(type(store.store), "table")
	MiniTest.expect.no_equality(store.persistence, nil)
end

T["KeyValueStore.new"]["creates instance with onDataLoaded callback"] = function()
	local callback = function(data)
		return { transformed = true, value = data }
	end
	local store = KeyValueStore.new("test.json", callback)
	MiniTest.expect.no_equality(store, nil)
	MiniTest.expect.equality(store.onDataLoaded, callback)
end

T["KeyValueStore:add"] = new_set({
	hooks = {
		pre_case = function()
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

T["KeyValueStore:add"]["adds string value"] = function()
	local store = KeyValueStore.new("test.json")
	store:add("key1", "value1")
	MiniTest.expect.equality(store.store["key1"], "value1")
end

T["KeyValueStore:add"]["adds number value"] = function()
	local store = KeyValueStore.new("test.json")
	store:add("key1", 42)
	MiniTest.expect.equality(store.store["key1"], 42)
end

T["KeyValueStore:add"]["adds table value"] = function()
	local store = KeyValueStore.new("test.json")
	local value = { enabled = true, name = "test" }
	store:add("key1", value)
	MiniTest.expect.equality(store.store["key1"].enabled, true)
	MiniTest.expect.equality(store.store["key1"].name, "test")
end

T["KeyValueStore:add"]["overwrites existing key"] = function()
	local store = KeyValueStore.new("test.json")
	store:add("key1", "value1")
	store:add("key1", "value2")
	MiniTest.expect.equality(store.store["key1"], "value2")
end

T["KeyValueStore:add"]["persists to disk"] = function()
	local store1 = KeyValueStore.new("test.json")
	store1:add("key1", "value1")

	local store2 = KeyValueStore.new("test.json")
	local val = store2:get("key1")
	MiniTest.expect.equality(val, "value1")
end

T["KeyValueStore:update"] = new_set({
	hooks = {
		pre_case = function()
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

T["KeyValueStore:update"]["updates existing key"] = function()
	local store = KeyValueStore.new("test.json")
	store:add("key1", "value1")
	store:update("key1", "updated_value")
	MiniTest.expect.equality(store.store["key1"], "updated_value")
end

T["KeyValueStore:update"]["does not create new key if it doesn't exist"] = function()
	local store = KeyValueStore.new("test.json")
	store:update("nonexistent", "value")
	MiniTest.expect.equality(store.store["nonexistent"], nil)
end

T["KeyValueStore:update"]["persists changes to disk"] = function()
	local store1 = KeyValueStore.new("test.json")
	store1:add("key1", "value1")
	store1:update("key1", "updated")

	local store2 = KeyValueStore.new("test.json")
	store2:_initialize_store()
	MiniTest.expect.equality(store2.store["key1"], "updated")
end

T["KeyValueStore:remove"] = new_set({
	hooks = {
		pre_case = function()
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

T["KeyValueStore:remove"]["removes existing key"] = function()
	local store = KeyValueStore.new("test.json")
	store:add("key1", "value1")
	store:remove("key1")
	MiniTest.expect.equality(store.store["key1"], nil)
end

T["KeyValueStore:remove"]["is no-op for non-existent key"] = function()
	local store = KeyValueStore.new("test.json")
	store:add("key1", "value1")
	store:remove("nonexistent")
	MiniTest.expect.equality(store.store["key1"], "value1")
end

T["KeyValueStore:remove"]["persists removal to disk"] = function()
	local store1 = KeyValueStore.new("test.json")
	store1:add("key1", "value1")
	store1:add("key2", "value2")
	store1:remove("key1")

	local store2 = KeyValueStore.new("test.json")
	store2:_initialize_store()
	MiniTest.expect.equality(store2.store["key1"], nil)
	MiniTest.expect.equality(store2.store["key2"], "value2")
end

T["KeyValueStore:get"] = new_set({
	hooks = {
		pre_case = function()
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

T["KeyValueStore:get"]["returns value for existing key"] = function()
	local store = KeyValueStore.new("test.json")
	store:add("key1", "value1")
	local value = store:get("key1")
	MiniTest.expect.equality(value, "value1")
end

T["KeyValueStore:get"]["returns nil for non-existent key"] = function()
	local store = KeyValueStore.new("test.json")
	local value = store:get("nonexistent")
	MiniTest.expect.equality(value, nil)
end

T["KeyValueStore:list"] = new_set({
	hooks = {
		pre_case = function()
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

T["KeyValueStore:list"]["returns empty array for empty store"] = function()
	local store = KeyValueStore.new("test.json")
	local items = store:list()
	MiniTest.expect.equality(type(items), "table")
	MiniTest.expect.equality(#items, 0)
end

T["KeyValueStore:list"]["returns all values as array"] = function()
	local store = KeyValueStore.new("test.json")
	store:add("key1", "value1")
	store:add("key2", "value2")
	store:add("key3", "value3")

	local items = store:list()
	MiniTest.expect.equality(#items, 3)

	local values = {}
	for _, v in ipairs(items) do
		values[v] = true
	end
	MiniTest.expect.no_equality(values["value1"], nil)
	MiniTest.expect.no_equality(values["value2"], nil)
	MiniTest.expect.no_equality(values["value3"], nil)
end

T["KeyValueStore:list"]["returns shallow copy"] = function()
	local store = KeyValueStore.new("test.json")
	store:add("key1", "value1")

	local items1 = store:list()
	local items2 = store:list()

	-- Test they are not the same reference (different tables)
	MiniTest.expect.equality(rawequal(items1, items2), false)
end

T["KeyValueStore:empty_store"] = new_set({
	hooks = {
		pre_case = function()
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

T["KeyValueStore:empty_store"]["clears all data"] = function()
	local store = KeyValueStore.new("test.json")
	store:add("key1", "value1")
	store:add("key2", "value2")
	store:empty_store()

	MiniTest.expect.equality(vim.tbl_count(store.store), 0)
end

T["KeyValueStore:empty_store"]["persists empty state to disk"] = function()
	local store1 = KeyValueStore.new("test.json")
	store1:add("key1", "value1")
	store1:empty_store()

	local store2 = KeyValueStore.new("test.json")
	store2:_initialize_store()
	MiniTest.expect.equality(vim.tbl_count(store2.store), 0)
end

T["KeyValueStore:load"] = new_set({
	hooks = {
		pre_case = function()
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

T["KeyValueStore:load"]["reloads data from disk"] = function()
	local store1 = KeyValueStore.new("test.json")
	store1:add("key1", "value1")

	local store2 = KeyValueStore.new("test.json")
	store2:_initialize_store()
	store2.store["key1"] = "modified_in_memory"

	store2:load()
	MiniTest.expect.equality(store2.store["key1"], "value1")
end

T["KeyValueStore:load"]["discards in-memory changes"] = function()
	local store = KeyValueStore.new("test.json")
	store:add("key1", "value1")
	store.store["key2"] = "in_memory_only"
	store:load()

	MiniTest.expect.equality(store.store["key1"], "value1")
	MiniTest.expect.equality(store.store["key2"], nil)
end

T["onDataLoaded callback"] = new_set({
	hooks = {
		pre_case = function()
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

T["onDataLoaded callback"]["transforms data on initialization"] = function()
	local store1 = KeyValueStore.new("test.json")
	store1:add("key1", { value = 10 })

	local transformer = function(data)
		return { transformed = true, originalValue = data.value }
	end

	local store2 = KeyValueStore.new("test.json", transformer)
	store2:_initialize_store()

	local item = store2.store["key1"]
	MiniTest.expect.equality(item.transformed, true)
	MiniTest.expect.equality(item.originalValue, 10)
end

T["onDataLoaded callback"]["is applied to all values"] = function()
	local store1 = KeyValueStore.new("test.json")
	store1:add("key1", { value = 1 })
	store1:add("key2", { value = 2 })
	store1:add("key3", { value = 3 })

	local transformer = function(data)
		return { doubled = data.value * 2 }
	end

	local store2 = KeyValueStore.new("test.json", transformer)
	store2:_initialize_store()

	MiniTest.expect.equality(store2.store["key1"].doubled, 2)
	MiniTest.expect.equality(store2.store["key2"].doubled, 4)
	MiniTest.expect.equality(store2.store["key3"].doubled, 6)
end

T["lazy initialization"] = new_set({
	hooks = {
		pre_case = function()
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

T["lazy initialization"]["store is empty before initialization"] = function()
	local store1 = KeyValueStore.new("test.json")
	store1:add("key1", "value1")

	local store2 = KeyValueStore.new("test.json")
	MiniTest.expect.equality(vim.tbl_count(store2.store), 0)
end

T["lazy initialization"]["initializes only once"] = function()
	local call_count = 0
	local store1 = KeyValueStore.new("test.json")
	store1:add("key1", "value1")

	local transformer = function(data)
		call_count = call_count + 1
		return data
	end

	local store2 = KeyValueStore.new("test.json", transformer)
	store2:_initialize_store()
	store2:_initialize_store()
	store2:_initialize_store()

	MiniTest.expect.equality(call_count, 1)
end

T["persistence integration"] = new_set({
	hooks = {
		pre_case = function()
			vim.fn.delete(vim.fn.stdpath("data") .. "/maven.nvim.test/_tests_", "rf")
		end,
	},
})

T["persistence integration"]["multiple operations persist correctly"] = function()
	local store1 = KeyValueStore.new("test.json")
	store1:add("key1", "value1")
	store1:add("key2", "value2")
	store1:update("key1", "updated")
	store1:remove("key2")
	store1:add("key3", { data = "complex" })

	local store2 = KeyValueStore.new("test.json")
	store2:_initialize_store()

	MiniTest.expect.equality(store2.store["key1"], "updated")
	MiniTest.expect.equality(store2.store["key2"], nil)
	MiniTest.expect.equality(store2.store["key3"].data, "complex")
end

return T

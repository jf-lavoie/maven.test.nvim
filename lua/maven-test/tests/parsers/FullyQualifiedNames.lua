local M = {}

M.JavaFullyQualifiedClassName = {}
M.JavaFullyQualifiedClassName.__index = M.JavaFullyQualifiedClassName

function M.JavaFullyQualifiedClassName.new(package, class, filepath)
	local self = setmetatable({}, M.JavaFullyQualifiedClassName)
	self.package = package
	self.class = class
	self.filepath = filepath
	return self
end

function M.JavaFullyQualifiedClassName:fullyQualifiedClassName()
	return self.package.name .. "." .. self.class.name
end

function M.JavaFullyQualifiedClassName:templateValues()
	return {
		package = self.package.name,
		class = self.class.name,
		filepath = self.filepath,
	}
end

M.GoFullyQualifiedClassName = {}
M.GoFullyQualifiedClassName.__index = M.GoFullyQualifiedClassName

function M.GoFullyQualifiedClassName.new(package, filepath)
	local self = setmetatable({}, M.GoFullyQualifiedClassName)
	self.package = package
	self.filepath = filepath
	return self
end

function M.GoFullyQualifiedClassName:fullyQualifiedClassName()
	return self.package.name .. "." .. self.class.name
end

function M.GoFullyQualifiedClassName:templateValues()
	return {
		package = self.package.name,
		filepath = self.filepath,
	}
end

M.JavaFullyQualifiedMethodName = {}
M.JavaFullyQualifiedMethodName.__index = M.JavaFullyQualifiedMethodName

function M.JavaFullyQualifiedMethodName.new(package, class, method)
	local self = setmetatable({}, M.JavaFullyQualifiedMethodName)
	self.package = package
	self.class = class
	self.method = method
	return self
end

function M.JavaFullyQualifiedMethodName:fullyQualifiedMethodName()
	local output = ""
	output = self.package.name .. "." .. self.class.name .. "#" .. self.method.name

	return output
end

function M.JavaFullyQualifiedMethodName:displayString()
	return self:fullyQualifiedMethodName() .. " // line " .. self.method.line
end

function M.JavaFullyQualifiedMethodName:templateValues()
	return {
		package = self.package.name,
		class = self.class.name,
		filepath = self.class.filepath,
		method = self.method.name,
	}
end

M.GoFullyQualifiedMethodName = {}
M.GoFullyQualifiedMethodName.__index = M.GoFullyQualifiedMethodName

function M.GoFullyQualifiedMethodName.new(package, method)
	local self = setmetatable({}, M.GoFullyQualifiedMethodName)
	self.package = package
	self.method = method
	return self
end

function M.GoFullyQualifiedMethodName:fullyQualifiedMethodName()
	local output = ""
	output = self.method.name

	return output
end

function M.GoFullyQualifiedMethodName:displayString()
	return self.package.name .. " > " .. self:fullyQualifiedMethodName() .. " // line " .. self.method.line
end

function M.GoFullyQualifiedMethodName:templateValues()
	return {
		package = self.package.name,
		class = "",
		method = self.method.name,
	}
end

M.Package = {}
M.Package.__index = M.Package

function M.Package.new(name)
	local self = setmetatable({}, M.Package)
	self.name = name
	return self
end

function M.Package:toString()
	return self.name
end

function M.Package:isClass()
	return false
end

function M.Package:isMethod()
	return false
end

function M.Package:isPackage()
	return true
end

M.Class = {}
M.Class.__index = M.Class

function M.Class.new(name, line)
	local self = setmetatable({}, M.Class)
	self.name = name
	self.line = line
	return self
end

function M.Class:toString()
	return self.name
end

function M.Class:isClass()
	return true
end

function M.Class:isMethod()
	return false
end

function M.Class:isPackage()
	return true
end

M.Method = {}
M.Method.__index = M.Method

function M.Method.new(name, line, is_current)
	local self = setmetatable({}, M.Method)
	self.name = name
	self.line = line
	self.is_current = is_current
	return self
end

function M.Method:toString()
	return self.name
end

function M.Method:isClass()
	return false
end

function M.Method:isMethod()
	return true
end

function M.Method:isPackage()
	return true
end
--- --- Fully qualified name class
--- --- Represents a test identifier with its line number
--- --- @class FullyQualifiedName
--- --- @field package_name string The Java package name
--- --- @field class string The class name
--- --- @field test_name string? The test method or field name (nil for class-level tests)
--- --- @field line number The line number where the test is defined
--- --- @field is_current boolean Whether this test is the current one under the cursor
--- M.FullyQualifiedName = {}
--- M.FullyQualifiedName.__index = M.FullyQualifiedName
---
--- --- Creates a new FullyQualifiedName instance
--- --- @param package_name string The Java package name (e.g., "com.example")
--- --- @param class string The class name
--- --- @param test_name string? The test method or field name (nil for class-level tests)
--- --- @param line number The line number where the test is defined
--- --- @param is_current boolean Whether this test is at the current cursor position
--- --- @return FullyQualifiedName
--- function M.FullyQualifiedName.new(package_name, class, test_name, line, is_current)
--- 	local self = setmetatable({}, M.FullyQualifiedName)
--- 	self.package_name = package_name
--- 	self.class = class
--- 	self.test_name = test_name
--- 	self.line = line
--- 	self.is_current = is_current
--- 	return self
--- end
---
--- --- Generates the fully qualified name text for the test
--- --- Returns either "package.Class#method" for test methods or "package.Class" for class-level tests
--- --- @return string The fully qualified test name in Maven format
--- function M.FullyQualifiedName:text()
--- 	if self.test_name then
--- 		return self.package_name .. "." .. self.class .. "#" .. self.test_name
--- 	else
--- 		return self.package_name .. "." .. self.class
--- 	end
--- end
---
--- --- Checks if this represents a class-level test
--- --- Returns true if test_name is nil (indicating a class-level test action)
--- --- @return boolean True if this is a class-level test, false if it's a method-level test
--- function M.FullyQualifiedName:isClass()
--- 	return self.test_name == nil
--- end
---
--- --- Converts the test identifier to a human-readable string
--- --- Combines the fully qualified name with its line number
--- --- @return string The test identifier in format "package.Class#method (line N)"
--- function M.FullyQualifiedName:toString()
--- 	return self:text() .. " (line " .. self.line .. ")"
--- end

return M

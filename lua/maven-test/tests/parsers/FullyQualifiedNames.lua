--- Module for handling fully qualified names for Java and Go test execution
--- Provides classes to represent and format fully qualified names for different test runners:
--- - JavaFullyQualifiedClassName: For Maven test execution via -Dtest parameter
--- - GoFullyQualifiedClassName: For Go test execution via go test
--- - JavaFullyQualifiedMethodName: For Maven test method execution via -Dtest=Class#method
--- - GoFullyQualifiedMethodName: For Go test method execution via go test -run pattern
--- @module 'maven-test.tests.parsers.FullyQualifiedNames'
local M = {}

--- Represents a project-level fully qualified name for project-wide test execution
--- Used when running all tests in the project or executing project-level commands
--- @class ProjectFullyQualifiedName
M.ProjectFullyQualifiedName = {}
M.ProjectFullyQualifiedName.__index = M.ProjectFullyQualifiedName

--- Creates a new ProjectFullyQualifiedName instance
--- @return ProjectFullyQualifiedName A new instance for project-level test execution
function M.ProjectFullyQualifiedName.new()
	local self = setmetatable({}, M.ProjectFullyQualifiedName)
	return self
end

--- Returns the fully qualified file name for project-level execution
--- @return string Always returns "all" to indicate all tests
function M.ProjectFullyQualifiedName:fullyQualifiedFileName()
	return "all"
end

--- Returns a display string for UI presentation
--- @return string The display string "(all)" indicating all tests
function M.ProjectFullyQualifiedName:displayString()
	return "(all)"
end

--- Returns template values for command formatting
--- @return table Empty table as project-level commands don't need template substitution
function M.ProjectFullyQualifiedName:templateValues()
	return {}
end

--- Represents a fully qualified Java class name for test execution
--- Used when running all tests in a Java class via Maven's -Dtest parameter
--- @class JavaFullyQualifiedClassName
--- @field package_ Package The package containing this class
--- @field class_ Class The class information (name and line number)
--- @field filepath string The absolute file path where this class is defined
M.JavaFullyQualifiedClassName = {}
M.JavaFullyQualifiedClassName.__index = M.JavaFullyQualifiedClassName

--- Creates a new JavaFullyQualifiedClassName instance
--- @param package_ Package The package containing the class (e.g., Package.new("com.example"))
--- @param class_ Class The class information with name and line number
--- @param filepath string The absolute file path where the class is defined
--- @return JavaFullyQualifiedClassName A new instance for Maven test class execution
function M.JavaFullyQualifiedClassName.new(package_, class_, filepath)
	local self = setmetatable({}, M.JavaFullyQualifiedClassName)
	self.package_ = package_
	self.class_ = class_
	self.filepath = filepath
	return self
end

--- Returns the fully qualified class name in Java format
--- @return string The fully qualified name (e.g., "com.example.MyClass")
function M.JavaFullyQualifiedClassName:fullyQualifiedFileName()
	return self.package_.name .. "." .. self.class_.name
end

--- Returns a display string for the Java class
--- @return string The fully qualified class name (e.g., "com.example.MyClass")
function M.JavaFullyQualifiedClassName:displayString()
	return self.package_.name .. "." .. self.class_.name
end

--- Returns template values for Maven command formatting
--- These values are used to substitute placeholders in command templates
--- @return table<string, string> Template values with keys: package, class, filepath, dirname
function M.JavaFullyQualifiedClassName:templateValues()
	return {
		package = self.package_.name,
		class = self.class_.name,
		filepath = self.filepath,
		dirname = vim.fs.dirname(self.filepath),
	}
end

--- Represents a fully qualified Go package name for test execution
--- Used when running all tests in a Go package via go test
--- @class GoFullyQualifiedFileName
--- @field package_ Package The Go package information
--- @field filepath string The absolute file path where this package is defined
M.GoFullyQualifiedFileName = {}
M.GoFullyQualifiedFileName.__index = M.GoFullyQualifiedFileName

--- Creates a new GoFullyQualifiedFileName instance
--- @param package_ Package The Go package (e.g., Package.new("mypackage"))
--- @param filepath string The absolute file path where the package is defined
--- @return GoFullyQualifiedFileName A new instance for Go package test execution
function M.GoFullyQualifiedFileName.new(package_, filepath)
	local self = setmetatable({}, M.GoFullyQualifiedFileName)
	self.package_ = package_
	self.filepath = filepath
	return self
end

--- Returns the file path for Go test execution
--- For Go, the filepath is used directly as the test target
--- @return string The absolute file path
function M.GoFullyQualifiedFileName:fullyQualifiedFileName()
	return self.filepath
end

--- Returns a display string for the Go package file
--- @return string The absolute file path
function M.GoFullyQualifiedFileName:displayString()
	return self.filepath
end

--- Returns template values for Go test command formatting
--- These values are used to substitute placeholders in command templates
--- @return table<string, string> Template values with keys: package, class (empty), filepath, dirname
function M.GoFullyQualifiedFileName:templateValues()
	return {
		package = self.package_.name,
		class = "",
		filepath = self.filepath,
		dirname = vim.fs.dirname(self.filepath),
	}
end

--- Represents a fully qualified Java method name for single test execution
--- Used when running a specific test method via Maven's -Dtest=Class#method parameter
--- @class JavaFullyQualifiedMethodName
--- @field package_ Package The package containing the method
--- @field class_ Class The class containing the method (includes filepath)
--- @field filepath string The absolute file path where the class is defined
--- @field method Method The method information (name, line number, cursor position flag)
M.JavaFullyQualifiedMethodName = {}
M.JavaFullyQualifiedMethodName.__index = M.JavaFullyQualifiedMethodName

--- Creates a new JavaFullyQualifiedMethodName instance
--- @param package Package The package containing the method (e.g., Package.new("com.example"))
--- @param class Class The class containing the method with name, line, and filepath
--- @param filepath string The absolute file path where the class is defined
--- @param method Method The method information with name, line, and is_current flag
--- @return JavaFullyQualifiedMethodName A new instance for Maven single test method execution
function M.JavaFullyQualifiedMethodName.new(package, class, filepath, method)
	local self = setmetatable({}, M.JavaFullyQualifiedMethodName)
	self.package_ = package
	self.class_ = class
	self.filepath = filepath
	self.method = method
	return self
end

--- Returns the fully qualified method name in Maven Surefire test format
--- This format is used with Maven's -Dtest parameter to run a single test method
--- @return string The fully qualified name in format "package.Class#method" (e.g., "com.example.MyClass#testMethod")
function M.JavaFullyQualifiedMethodName:fullyQualifiedMethodName()
	local output = ""
	output = self.package_.name .. "." .. self.class_.name .. "#" .. self.method.name

	return output
end

--- Returns a display string with line number information
--- @return string The display string (e.g., "com.example.MyClass#testMethod // line 42")
function M.JavaFullyQualifiedMethodName:displayString()
	return self:fullyQualifiedMethodName() .. " // line " .. self.method.line
end

--- Returns template values for Maven test command formatting
--- These values are used to substitute placeholders in command templates
--- @return table<string, string> Template values with keys: package, class, filepath, method, dirname
function M.JavaFullyQualifiedMethodName:templateValues()
	return {
		package = self.package_.name,
		class = self.class_.name,
		filepath = self.filepath,
		method = self.method.name,
		dirname = vim.fs.dirname(self.filepath),
	}
end

--- Represents a fully qualified Go test function name for single test execution
--- Used when running a specific Go test function via go test -run parameter
--- @class GoFullyQualifiedMethodName
--- @field package_ Package The package containing the test function
--- @field filepath string The absolute file path where the test function is defined
--- @field method Method The test function information (name, line number, cursor position flag)
M.GoFullyQualifiedMethodName = {}
M.GoFullyQualifiedMethodName.__index = M.GoFullyQualifiedMethodName

--- Creates a new GoFullyQualifiedMethodName instance
--- @param package Package The package containing the test (e.g., Package.new("mypackage"))
--- @param filepath string The absolute file path where the test function is defined (not used in fully qualified name but included for consistency)
--- @param method Method The test function information with name, line, and is_current flag
--- @return GoFullyQualifiedMethodName A new instance for Go single test function execution
function M.GoFullyQualifiedMethodName.new(package, filepath, method)
	local self = setmetatable({}, M.GoFullyQualifiedMethodName)
	self.package_ = package
	self.filepath = filepath
	self.method = method
	return self
end

--- Returns the test function name for Go test execution
--- In Go, only the function name is needed (e.g., "TestMyFunction")
--- @return string The test function name without package prefix
function M.GoFullyQualifiedMethodName:fullyQualifiedMethodName()
	local output = ""
	output = self.method.name

	return output
end

--- Returns a human-readable display string for UI presentation
--- Includes package context and line number for easy identification
--- @return string The display string in format "package > TestFunction // line N" (e.g., "mypackage > TestMyFunction // line 42")
function M.GoFullyQualifiedMethodName:displayString()
	return self.package_.name .. " > " .. self:fullyQualifiedMethodName() .. " // line " .. self.method.line
end

--- Returns template values for Go test command formatting
--- These values are used to substitute placeholders in command templates
--- @return table<string, string> Template values with keys: package, class (empty), method, filepath, dirname
function M.GoFullyQualifiedMethodName:templateValues()
	return {
		package = self.package_.name,
		class = "",
		method = self.method.name,
		filepath = self.filepath,
		dirname = vim.fs.dirname(self.filepath),
	}
end

--- Represents a package namespace (Java or Go)
--- Base component for building fully qualified names
--- @class Package
--- @field name string The package name (e.g., "com.example" for Java, "mypackage" for Go)
M.Package = {}
M.Package.__index = M.Package

--- Creates a new Package instance
--- @param name string The package name
--- @return Package
function M.Package.new(name)
	local self = setmetatable({}, M.Package)
	self.name = name
	return self
end

--- Returns the package name as a string
--- @return string The package name
function M.Package:toString()
	return self.name
end

--- Checks if this is a class
--- @return boolean Always false for packages
function M.Package:isClass()
	return false
end

--- Checks if this is a method
--- @return boolean Always false for packages
function M.Package:isMethod()
	return false
end

--- Checks if this is a package
--- @return boolean Always true for packages
function M.Package:isPackage()
	return true
end

--- Represents a Java class with its source location
--- Used as a component in fully qualified names
--- @class Class
--- @field name string The class name (e.g., "MyTestClass")
--- @field line number The line number where the class is defined
--- @field filepath string? Optional absolute file path where the class is defined
M.Class = {}
M.Class.__index = M.Class

--- Creates a new Class instance
--- @param name string The class name (e.g., "MyTestClass")
--- @param line number The line number where the class declaration starts
--- @return Class A new class instance
function M.Class.new(name, line)
	local self = setmetatable({}, M.Class)
	self.name = name
	self.line = line
	return self
end

--- Returns the class name as a string
--- @return string The class name
function M.Class:toString()
	return self.name
end

--- Checks if this is a class
--- @return boolean Always true for classes
function M.Class:isClass()
	return true
end

--- Checks if this is a method
--- @return boolean Always false for classes
function M.Class:isMethod()
	return false
end

--- Checks if this is a package
--- @return boolean Always false for classes
function M.Class:isPackage()
	return false
end

--- Represents a test method/function with its source location and cursor context
--- Used as a component in fully qualified method names
--- @class Method
--- @field name string The method/function name (e.g., "testSomething" for Java, "TestSomething" for Go)
--- @field line number The line number where the method is defined
--- @field is_current boolean Whether this method contains or is at the current cursor position
M.Method = {}
M.Method.__index = M.Method

--- Creates a new Method instance
--- @param name string The method/function name (e.g., "testMyFeature")
--- @param line number The line number where the method declaration starts
--- @param is_current boolean True if cursor is within this method's scope
--- @return Method A new method instance
function M.Method.new(name, line, is_current)
	local self = setmetatable({}, M.Method)
	self.name = name
	self.line = line
	self.is_current = is_current
	return self
end

--- Returns the method name as a string
--- @return string The method name
function M.Method:toString()
	return self.name
end

--- Checks if this is a class
--- @return boolean Always false for methods
function M.Method:isClass()
	return false
end

--- Checks if this is a method
--- @return boolean Always true for methods
function M.Method:isMethod()
	return true
end

--- Checks if this is a package
--- @return boolean Always false for methods
function M.Method:isPackage()
	return false
end

return M

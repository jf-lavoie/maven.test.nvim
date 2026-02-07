--- Argument class for managing Maven command arguments
--- Represents a custom Maven argument that can be toggled on/off
--- and appended to Maven commands
--- @module 'maven-test.store.custom_argument'

local M = {}

--- Argument class
--- @class Argument
--- @field text string The Maven argument text (e.g., "-X", "-DskipTests")
--- @field active boolean Whether this argument is currently active
M.Argument = {}
M.Argument.__index = M.Argument

--- Create a new Argument instance
--- @param text string The Maven argument text
--- @param active boolean Whether the argument is active
--- @return Argument New Argument instance
--- @usage
---   local arg = Argument.new("-X", true)
---   local inactive_arg = Argument.new("-DskipTests", false)
function M.Argument.new(text, active)
	local self = setmetatable({}, M.Argument)

	self.text = text

	self.active = active

	return self
end

--- Toggle the active state of this argument
--- Flips the active flag between true and false
--- @return Argument Returns self for method chaining
--- @usage
---   local arg = Argument.new("-X", true)
---   arg:toggle_active()  -- Now active = false
---   arg:toggle_active()  -- Now active = true again
function M.Argument:toggle_active()
	self.active = not self.active

	return self
end

--- Append this argument to a Maven command
--- Only appends if the argument text is not already present in the command
--- Prevents duplicate arguments in the same command
--- @param command string The Maven command to append to
--- @return string The command with the argument appended (or unchanged if already present)
--- @usage
---   local arg = Argument.new("-X", true)
---   local cmd = "mvn test"
---   cmd = arg:append_to_command(cmd)  -- Returns "mvn test -X"
---   cmd = arg:append_to_command(cmd)  -- Returns "mvn test -X" (no duplicate)
function M.Argument:append_to_command(command)
	if not command:find(self.text, 1, true) then
		return command .. " " .. self.text
	end
	return command
end

return M

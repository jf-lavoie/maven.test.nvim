local M

M = {}

M.CustomArgument = {}
M.CustomArgument.__index = M.CustomArgument

function M.CustomArgument.new(text, active)
	local self = setmetatable({}, M.CustomArgument)

	self.text = text

	self.active = active

	return self
end

function M.CustomArgument:toggle_active()
	self.active = not self.active

	return self
end

function M.CustomArgument:append_to_command(command)
	if not command:find(self.text, 1, true) then
		return command .. " " .. self.text
	end
	return command
end

return M

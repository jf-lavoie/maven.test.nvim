local M = {}

local function file_exists(path)
	local stat = vim.loop.fs_stat(path)
	return stat and stat.type == "file"
end

local function find_project_root(markers)
	local current_dir = vim.fn.expand("%:p:h")
	local root = vim.fn.finddir(".git", current_dir .. ";")

	if root == "" then
		root = current_dir
	else
		root = vim.fn.fnamemodify(root, ":h")
	end

	for _, marker in ipairs(markers) do
		if file_exists(root .. "/" .. marker) then
			return root
		end
	end

	return nil
end

--- Detect all project types and their root directories
--- Supports repositories with multiple language/build systems
--- @param projectConfigs MavenTestConfig.projects Project detection configuration
--- @return table<number, {[1]: string, [2]: string}> projects List of tuples [project_type, root_path]
function M.detect_project_type(projectConfigs)
	local projects = {}

	for project_pattern, config in pairs(projectConfigs) do
		if config.root_markers then
			local root = find_project_root(config.root_markers)
			if root then
				table.insert(projects, { project_pattern, root })
			end
		end
	end

	return projects
end

return M

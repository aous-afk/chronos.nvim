local Config = require("chronos.config")
local vim = vim

local M = {}

function M.parse_explicit_project_and_desc(cmd)
  local args = cmd.fargs or {}
  local explicit_project = nil
  local priority = nil -- "H" | "M" | "L" | nil (none)
  local desc_parts = {}

  local i = 1
  while i <= #args do
    local a = args[i]

    if a == "-p" then
      explicit_project = args[i + 1]
      i = i + 2

    elseif a == "-H" then
      priority = "H"
      i = i + 1

    elseif a == "-M" then
      priority = "M"
      i = i + 1

    elseif a == "-L" then
      priority = "L"
      i = i + 1

    elseif a == "-N" then
      priority = nil -- explicit none
      i = i + 1

    else
      table.insert(desc_parts, a)
      i = i + 1
    end
  end

  local description = table.concat(desc_parts, " ")
  return explicit_project, description, priority
end

function M.resolve_project(explicit_project, cb)
    -- 1) explicit flag always wins
    if explicit_project and explicit_project ~= "" then
	-- persist explicit choice as current project for next time
	Config.set_current_project(explicit_project)
	require("chronos.projects").refresh()
	return cb(explicit_project)
    end

    -- 2) use saved current project if present
    local current = Config.get_current_project and Config.get_current_project() or Config.opts.current_project
    if current and current ~= "" then
	return cb(current)
    end
    require("chronos.projects").refresh(function(ok, projects)
	if not ok or not projects or #projects == 0 then
	    vim.notify("Chronos: no projects found (set -p manually)", vim.log.levels.ERROR)
	    return
	end

	vim.ui.select(projects, { prompt = "Select project" }, function(choice)
	    if not choice then return end
	    Config.set_current_project(choice)
	    cb(choice)
	end)
    end)
end

function M.project_select()
    require("chronos.projects").refresh(function(ok, projects)
	if not ok or not projects or #projects == 0 then
	    vim.notify("Chronos: no projects found", vim.log.levels.WARN)
	    return
	end

	vim.ui.select(projects, { prompt = "Select Chronos project" }, function(choice)
	    if not choice then return end
	    Config.set_current_project(choice)
	    vim.notify("Chronos project set: " .. choice)
	end)
    end)
end

function M.apply_prio_tag(priority, description)
  if not priority or priority == "" then return description end
  return ("prio:%s %s"):format(priority, description)
end

return M

local Projects = require("chronos.projects")

local M = {}

local PRIORITY_FLAGS = { "-H", "-M", "-L", "-N", "-p" }

local function completing_after_dash_p(cmdline, cursorpos)
    local left = cmdline:sub(1, cursorpos)
    return left:match("%-p%s+[^%s]*$") ~= nil
end

local function completing_flag_prefix(arglead)
    return arglead:match("^%-") ~= nil
end

function M.chronos_args(ArgLead, CmdLine, CursorPos)
    -- completing the project value after "-p "
    if completing_after_dash_p(CmdLine, CursorPos) then
	if not Projects.is_loaded() then
	    Projects.refresh()
	    return {}
	end

	local out = {}
	for _, p in ipairs(Projects.get() or {}) do
	    if ArgLead == "" or p:find("^" .. vim.pesc(ArgLead)) then
		table.insert(out, p)
	    end
	end
	return out
    end

    -- completing a flag (-*)
    if completing_flag_prefix(ArgLead) then
	local out = {}
	for _, f in ipairs(PRIORITY_FLAGS) do
	    if ArgLead == "" or f:find("^" .. vim.pesc(ArgLead)) then
		table.insert(out, f)
	    end
	end
	return out
    end

    -- description word completion: none (don’t spam suggestions)
    return {}
end

local function is_completing_project(cmdline, cursorpos)
  local left = cmdline:sub(1, cursorpos)
  return left:match("%-p%s+[^%s]*$") ~= nil
end

function M.project_arg(ArgLead, CmdLine, CursorPos)
  if not is_completing_project(CmdLine, CursorPos) then
    return {}
  end

  -- Completion must be synchronous; use cached projects.
  if not Projects.is_loaded or not Projects.is_loaded() then
    Projects.refresh() -- async; next completion attempt will have data
    return {}
  end

  local out = {}
  for _, p in ipairs(Projects.get() or {}) do
    if ArgLead == "" or p:find("^" .. vim.pesc(ArgLead)) then
      table.insert(out, p)
    end
  end
  return out
end

return M

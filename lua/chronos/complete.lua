local Projects = require("chronos.projects")

local M = {}

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

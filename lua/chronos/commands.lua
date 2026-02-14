local Config = require("chronos.config")

local M = {}

function M.add(cmd)
  local args = cmd.fargs
  local project = nil
  local desc_parts = {}

  local i = 1
  while i <= #args do
    if args[i] == "-p" then
      project = args[i + 1]
      i = i + 2
    else
      table.insert(desc_parts, args[i])
      i = i + 1
    end
  end

  if not project then
    project = Config.opts.default_project
  end

  local description = table.concat(desc_parts, " ")

  if description == "" then
    vim.notify("ChronosAdd: description required", vim.log.levels.ERROR)
    return
  end

local Task = require("chronos.backend.task")
local Time = require("chronos.backend.time")

Task.add(description, project)
Time.start(description, project)
end

return M

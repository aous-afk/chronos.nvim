local M = {}

function M.add(description, project)
  vim.notify(string.format("backend.task.add(desc=%s, project=%s)", description, project))
  -- later: call `task add ...`
  return true
end

return M

local M = {}

function M.start(description, project)
  vim.notify(string.format("backend.time.start(desc=%s, project=%s)", description, project))
  -- later: call `bartib start -p ... -d ...`
  return true
end

return M

local Task = require("chronos.backend.task")

local M = {}

local pr_weight = { H = 3, M = 2, L = 1 }

local function sort_by_priority_then_id(tasks)
  table.sort(tasks, function(a, b)
    local ap = pr_weight[a.priority] or 0
    local bp = pr_weight[b.priority] or 0
    if ap ~= bp then return ap > bp end
    return (a.id or 0) < (b.id or 0)
  end)
  return tasks
end

function M.pick(status, opts, on_choice)
  opts = opts or {}
  on_choice = on_choice or function() end

  Task.export_status(status, function(ok, tasks)
    if not ok then return end
    if #tasks == 0 then
      vim.notify(("Chronos: no %s tasks"):format(status), vim.log.levels.INFO)
      return
    end

    tasks = sort_by_priority_then_id(tasks)

    vim.ui.select(tasks, {
      prompt = opts.prompt or ("Select task (" .. status .. ")"),
      format_item = opts.format_item,
    }, on_choice)
  end)
end

return M

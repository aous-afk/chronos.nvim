local Config = require("chronos.config")
local U = require("chronos.util")

local M = {}

--- Create a Taskwarrior task
--- @param project string
--- @param description string
--- @param cb fun(ok:boolean, res:table)|nil
function M.add(project, description, cb)
  cb = cb or function() end
  local bin = Config.opts.task_bin or "task"

  -- task add project:<name> <description...>
  U.system({ bin, "add", ("project:%s"):format(project), description }, { text = true }, function(r)
    if not r.ok then
      U.notify_fail("task add", r)
      return cb(false, r)
    end
    cb(true, r)
  end)
end

function M.projects(cb)
  cb = cb or function() end
  local bin = Config.opts.task_bin or "task"

  -- Flat list; avoids parsing "task projects" report table
  -- Taskwarrior examples explicitly mention rc.list.all.projects=1 with _projects. :contentReference[oaicite:5]{index=5}
  U.system({ bin, "rc.list.all.projects=1", "_projects" }, { text = true }, function(r)
    if not r.ok then
      U.notify_fail("task _projects", r)
      return cb(false, r)
    end

    local out = {}
    for line in (r.stdout .. "\n"):gmatch("([^\n]*)\n") do
      local name = vim.trim(line)
      if name ~= "" then table.insert(out, name) end
    end

    cb(true, out)
  end)
end

function M.export_pending(cb)
  cb = cb or function() end
  local bin = Config.opts.task_bin or "task"

  U.system({ bin, "status:pending", "export" }, { text = true }, function(r)
    if not r.ok then
      U.notify_fail("task export", r)
      return cb(false, r)
    end

    local ok, data = pcall(vim.json.decode, r.stdout or "")
    if not ok or type(data) ~= "table" then
      vim.notify("Chronos: failed to decode Taskwarrior JSON export", vim.log.levels.ERROR)
      return cb(false, { ok = false, code = -1, stdout = r.stdout, stderr = "json decode failed" })
    end

    cb(true, data)
  end)
end

function M.done(uuid, cb)
    cb = cb or function() end
    local bin = Config.opts.task_bin or "task"

    if not uuid or uuid == "" then
	vim.notify("Chronos: task.done missing uuid", vim.log.levels.ERROR)
	return cb(false, { ok = false, code = -1, stdout = "", stderr = "missing uuid" })
    end

    U.system({ bin, uuid, "done" }, { text = true }, function(r)
	if not r.ok then
	    U.notify_fail("task done", r)
	    return cb(false, r)
	end
	cb(true, r)
    end)
end

return M

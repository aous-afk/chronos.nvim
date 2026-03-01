local Config = require("chronos.config")
local U = require("chronos.util")

local M = {}

-- task status:<status> export (raw JSON text)
function M.export_raw(status, cb)
    cb = cb or function() end
    local bin = Config.opts.task_bin or "task"
    status = status or "pending"

    U.system({ bin, "status:" .. status, "export" }, { text = true }, function(r)
	vim.schedule(function() cb(r) end)
    end)
end

--- Create a Taskwarrior task
--- @param project string
--- @param description string
--- @param cb fun(ok:boolean, res:table)|nil
function M.add(project, description, priority, cb)
    cb = cb or function() end
    local bin = Config.opts.task_bin or "task"

    local args = { bin, "add" }
    if project and project ~= "" then
	table.insert(args, "project:" .. project)
    end
    if priority and priority ~= "" then
	table.insert(args, "priority:" .. priority) -- H/M/L
    end
    table.insert(args, description)
    -- task add project:<name> <description...>
    U.system(args, { text = true }, function(r)
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

function M.export_status(status, cb)
    cb = cb or function() end

    M.export_raw(status, function(r)
	if not r.ok then
	    U.notify_fail("task export", r)
	    return cb(false, r)
	end

	local ok, tasks = pcall(vim.json.decode, r.stdout or "[]")
	if not ok or type(tasks) ~= "table" then
	    local err = { ok = false, code = r.code or -1, stdout = r.stdout or "", stderr = "invalid task JSON" }
	    vim.notify("Chronos: failed to decode task export JSON", vim.log.levels.ERROR)
	    return cb(false, err)
	end

	cb(true, tasks)
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

function M.reopen(uuid, cb)
    cb = cb or function() end
    local bin = Config.opts.task_bin or "task"

    if not uuid or uuid == "" then
	vim.notify("Chronos: task.done missing uuid", vim.log.levels.ERROR)
	return cb(false, { ok = false, code = -1, stdout = "", stderr = "missing uuid" })
    end

    U.system({ bin, uuid, "modify", "status:pending" }, { text = true }, function(r)
	if not r.ok then
	    U.notify_fail("task reopen", r)
	    return cb(false, r)
	end
	cb(true, r)
    end)
end

function M.set_priority(uuid, priority, cb)
    cb = cb or function() end
    local bin = Config.opts.task_bin or "task"

    if not uuid or uuid == "" then
	vim.notify("Chronos: set_priority missing uuid", vim.log.levels.ERROR)
	return cb(false)
    end

    local args = { bin, uuid, "modify" }

    if priority and priority ~= "" then
	table.insert(args, "priority:" .. priority)
    else
	table.insert(args, "priority:") -- clears priority
    end

    U.system(args, { text = true }, function(r)
	if not r.ok then
	    U.notify_fail("task set_priority", r)
	    return cb(false, r)
	end
	cb(true, r)
    end)
end

function M.export_pending(cb)
    return M.export_status("pending", cb)
end

function M.count_pending(project, cb)
    cb = cb or function() end
    local bin = Config.opts.task_bin or "task"

    local args = { bin, "status:pending" }
    if project and project ~= "" then
	table.insert(args, ("project:%s"):format(project))
    end
    table.insert(args, "count")

    U.system(args, { text = true }, function(r)
	vim.schedule(function() cb(r) end)
    end)
end

return M

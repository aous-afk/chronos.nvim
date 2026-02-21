-- lua/chronos/backend/time.lua
local Config = require("chronos.config")
local U = require("chronos.util")

local M = {}

--- Start tracking time in bartib
--- @param project string
--- @param description string
--- @param cb fun(ok:boolean, res:table)|nil
function M.start(project, description, cb)
  cb = cb or function() end
  local bin = Config.opts.bartib_bin or "bartib"

  U.system({ bin, "start", "-p", project, "-d", description }, { text = true }, function(r)
    if not r.ok then
      U.notify_fail("bartib start", r)
      return cb(false, r)
    end
    cb(true, r)
  end)
end

--- Stop current tracking in bartib
--- @param cb fun(ok:boolean, res:table)|nil
function M.stop(cb)
  cb = cb or function() end
  local bin = Config.opts.bartib_bin or "bartib"

  U.system({ bin, "stop" }, { text = true }, function(r)
    if not r.ok then
      U.notify_fail("bartib stop", r)
      return cb(false, r)
    end
    cb(true, r)
  end)
end

function M.last(cb)
  cb = cb or function() end
  local bin = Config.opts.bartib_bin or "bartib"

  U.system({ bin, "last" }, { text = true }, function(r)
    if not r.ok then
      U.notify_fail("bartib last", r)
      return cb(false, r)
    end

    local items = {}
    for line in (r.stdout .. "\n"):gmatch("([^\n]*)\n") do
      -- matches: [3] More Urgent Task Y Just Another Project B
      local idx, rest = line:match("^%s*%[(%d+)%]%s+(.+)%s*$")
      if idx and rest then
        -- Heuristic split: two+ spaces separate description and project in bartib's table output
        local desc, proj = rest:match("^(.-)%s%s+(.+)$")
        table.insert(items, {
          idx = tonumber(idx),
          description = desc or rest,
          project = proj,
          raw = line,
        })
      end
    end

    cb(true, { items = items, raw = r.stdout })
  end)
end

function M.continue(idx, cb)
  cb = cb or function() end
  local bin = Config.opts.bartib_bin or "bartib"

  local argv = { bin, "continue" }
  if idx ~= nil then
    table.insert(argv, tostring(idx))
  end

  U.system(argv, { text = true }, function(r)
    if not r.ok then
      U.notify_fail("bartib continue", r)
      return cb(false, r)
    end
    cb(true, r)
  end)
end

function M.projects(cb)
    cb = cb or function() end
    local bin = Config.opts.bartib_bin or "bartib"

    U.system({ bin, "projects" }, { text = true }, function(r)
	if not r.ok then
	    U.notify_fail("bartib projects", r)
	    return cb(false, r)
	end

	local out = {}
	for line in (r.stdout .. "\n"):gmatch("([^\n]*)\n") do
	    local name = vim.trim(line)
	    if name ~= "" then
		-- bartib may print quoted names like "Work"
		name = name:gsub('^"(.*)"$', "%1")
		table.insert(out, name)
	    end
	end

	cb(true, out)
    end)
end

return M

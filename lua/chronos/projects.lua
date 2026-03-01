local Time = require("chronos.backend.time")
local Task = require("chronos.backend.task")
local Config = require("chronos.config")

local M = {
  _cache = {},
  _loaded = false,
  _refreshing = false,
}

local function merge_unique(a, b, c)
  local seen, out = {}, {}
  local function add(list)
    for _, name in ipairs(list or {}) do
      if name and name ~= "" and not seen[name] then
        seen[name] = true
        table.insert(out, name)
      end
    end
  end
  add(a); add(b); add(c)
  table.sort(out)
  return out
end

function M.get()
  return M._cache
end

function M.is_loaded()
  return M._loaded
end

--- Refresh cache asynchronously (non-blocking)
--- @param cb fun(ok:boolean, projects:string[]|nil)|nil
function M.refresh(cb)
    local cfg_projects = (Config.opts and Config.opts.projects) or {}
    cb = cb or function() end
    if M._refreshing then
	return cb(true, M._cache)
    end
    M._refreshing = true

    Time.projects(function(ok1, bartib_projects)
	if not ok1 then
	    M._refreshing = false
	    return cb(false)
	end
	Task.projects(function(ok2, task_projects)
	    M._refreshing = false
	    if not ok2 then
		return cb(false)
	    end

	    M._cache = merge_unique(bartib_projects, task_projects, cfg_projects)
	    M._loaded = true
	    cb(true, M._cache)
	end)
    end)
end

return M

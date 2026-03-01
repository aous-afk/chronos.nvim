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

-- bartib report --current_week
function M.report_current_week(cb)
    cb = cb or function() end
    local bin = Config.opts.bartib_bin or "bartib"
    U.system({ bin, "report", "--current_week" }, { text = true }, function(r)
	vim.schedule(function() cb(r) end)
    end)
end

function M.current(cb)
    cb = cb or function() end
    local bin = Config.opts.bartib_bin or "bartib"
    U.system({ bin, "current" }, { text = true }, function(r)
	vim.schedule(function() cb(r) end)
    end)
end

local function strip_ansi(s)
  return (s or ""):gsub("\27%[[0-9;]*m", "")
end

function M.parse_bartib_current(stdout)
  if not stdout or stdout == "" then
    return nil
  end

  -- 1) strip ANSI
  local s = strip_ansi(stdout)

  -- 2) normalize newlines
  s = s:gsub("\r\n", "\n")

  -- 3) normalize weird whitespace (NBSP + narrow NBSP)
  s = s:gsub("\194\160", " ")      -- U+00A0
  s = s:gsub("\226\128\175", " ")  -- U+202F

  -- 4) collapse multiple spaces
  s = s:gsub("[ \t]+", " ")

  local lines = vim.split(s, "\n", { plain = true, trimempty = true })

  local row = nil
  for _, l in ipairs(lines) do
    -- match actual data row: 2026-03-01 00:23 ...
    if l:match("^%d%d%d%d%-%d%d%-%d%d%s+%d%d:%d%d") then
      row = l
      break
    end
  end

  if not row then
    return nil
  end

  local cols = {}
  for tok in row:gmatch("%S+") do
    table.insert(cols, tok)
  end

  if #cols < 5 then
    return nil
  end

  local date = cols[1]
  local time = cols[2]

  -- detect duration (3h 49m OR <1m)
  local last = cols[#cols]
  local prev = cols[#cols - 1]

  local duration
  local project_index

  if last:match("^%d+m$") or last:match("^<%d+m$") then
    if prev and prev:match("^%d+h$") then
      duration = prev .. " " .. last
      project_index = #cols - 2
    else
      duration = last
      project_index = #cols - 1
    end
  else
    return nil
  end

  local project = cols[project_index]
  if not project then
    return nil
  end

  local desc_parts = {}
  for i = 3, project_index - 1 do
    table.insert(desc_parts, cols[i])
  end

  local description = table.concat(desc_parts, " ")
  if description == "" then
    description = "(no description)"
  end

  return {
    started_at = date .. " " .. time,
    project = project,
    description = description,
    duration = duration,
  }
end

return M

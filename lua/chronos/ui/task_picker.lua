local Task = require("chronos.backend.task")

local M = {}

local pr_weight = { H = 3, M = 2, L = 1 }


local function default_format(t)
    local id = t.id and ("#" .. t.id .. " ") or ""
    local proj = t.project and ("[" .. t.project .. "] ") or ""
    local pr = t.priority and ("(" .. t.priority .. ") ") or ""
    return id .. pr .. proj .. (t.description or "<no description>")
end

local function sort_by_priority_then_id(tasks)
    table.sort(tasks, function(a, b)
	local ap = pr_weight[a.priority] or 0
	local bp = pr_weight[b.priority] or 0
	if ap ~= bp then return ap > bp end
	return (a.id or 0) < (b.id or 0)
    end)
    return tasks
end
-- Generic picker (status-driven)
function M.pick(status, opts, on_choice)
    opts = opts or {}
    on_choice = on_choice or function() end
    status = status or "pending"

    Task.export_status(status, function(ok, tasks)
	if not ok then return end
	if #tasks == 0 then
	    vim.notify(("Chronos: no %s tasks"):format(status), vim.log.levels.INFO)
	    return
	end

	if type(opts.filter) == "function" then
	    local filtered = {}
	    for _, t in ipairs(tasks) do
		if opts.filter(t) then table.insert(filtered, t) end
	    end
	    tasks = filtered
	    if #tasks == 0 then
		vim.notify(("Chronos: no %s tasks (filtered)"):format(status), vim.log.levels.INFO)
		return
	    end
	end

	if opts.sort == nil then
	    tasks = sort_by_priority_then_id(tasks)
	elseif type(opts.sort) == "function" then
	    tasks = opts.sort(tasks) or tasks
	end

	vim.ui.select(tasks, {
	    prompt = opts.prompt or ("Select task (" .. status .. ")"),
	    format_item = opts.format_item or default_format,
	}, on_choice)
    end)
end

function M.pick_pending(opts, on_choice)
    return M.pick("pending", opts, on_choice)
end

function M.pick_completed(opts, on_choice)
    return M.pick("completed", opts, on_choice)
end

function M.default_format()
    return default_format
end

function M.choose(items, opts, cb)
    opts = opts or {}
    cb = cb or function() end

    vim.ui.select(items, {
	prompt = opts.prompt,
	format_item = opts.format_item,
    }, function(choice)
	    if not choice then return end
	    cb(choice)
	end)
end

function M.choose_priority(cb)
    local items = {
	{ label = "High", value = "-H" },
	{ label = "Medium", value = "-M" },
	{ label = "Low", value = "-L" },
	{ label = "None", value = "-N" },
    }

    return M.choose(items, {
	prompt = "Priority",
	format_item = function(it) return it.label end,
    }, function(choice)
	    cb(choice.value)
	end)
end

return M

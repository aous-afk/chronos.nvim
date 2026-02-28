local Time = require("chronos.backend.time")
local Task = require("chronos.backend.task")
local c = require("chronos.commands")
local Pick = require("chronos.ui.task_picker")
local vim = vim

local M = {}
-- Simple format without priority (for pickers that don't show it)
local function fmt_no_priority(t)
  local id = t.id and ("#" .. t.id .. " ") or ""
  local proj = t.project and ("[" .. t.project .. "] ") or ""
  return id .. proj .. (t.description or "<no description>")
end

function M.task_add(cmd)
    local explicit_project, description, priority = c.parse_explicit_project_and_desc(cmd)

    if description == "" then
	vim.notify("ChronosTaskAdd: description required", vim.log.levels.ERROR)
	return
    end

    c.resolve_project(explicit_project, function(project)
	Task.add(project, description, priority, function(ok)
	    if ok then
		require("chronos.projects").refresh()
		vim.notify(("Task added: [%s] %s"):format(project, description))
	    end
	end)
    end)
end

function M.task_add_start(cmd)
    local explicit_project, description, priority = c.parse_explicit_project_and_desc(cmd)

    if description == "" then
	vim.notify("ChronosTaskAddStart: description required", vim.log.levels.ERROR)
	return
    end

    c.resolve_project(explicit_project, function(project)
	Task.add(project, description, priority, function(ok_add)
	    if not ok_add then return end

	    Time.start(project, description, function(ok_start)
		if ok_start then
		    require("chronos.projects").refresh()
		    vim.notify(("Task added + tracking started: [%s] %s"):format(project, description))
		end
	    end)
	end)
    end)
end

function M.task_start()
    Pick.pick_pending({ prompt = "Start task", format_item = fmt_no_priority}, function(choice)
	if not choice then return end
	local description = choice.description or ""
	if description == "" then
	    vim.notify("Chronos: selected task has no description", vim.log.levels.ERROR)
	    return
	end

	c.resolve_project(choice.project, function(project)
	    Time.start(project, description, function(ok2)
		if ok2 then
		    require("chronos.projects").refresh()
		    vim.notify(("Tracking started: [%s] %s"):format(project, description))
		end
	    end)
	end)
    end)
end

function M.task_done()
    Pick.pick_pending({ prompt = "Done task" }, function(choice)
	if not choice then return end

	local uuid = choice.uuid
	if not uuid or uuid == "" then
	    vim.notify("Chronos: selected task has no uuid", vim.log.levels.ERROR)
	    return
	end

	Task.done(uuid, function(ok_done)
	    if ok_done then
		vim.notify(("Task done: %s"):format(choice.description or uuid))
		require("chronos.projects").refresh()
	    end
	end)
    end)
end

function M.task_reopen()
    Pick.pick_completed({ prompt = "Reopen task" }, function(choice)
	if not choice then return end

	local uuid = choice.uuid
	if not uuid or uuid == "" then
	    vim.notify("Chronos: selected task has no uuid", vim.log.levels.ERROR)
	    return
	end

	Task.reopen(uuid, function(ok_reopen)
	    if ok_reopen then
		vim.notify(("Task reopened: %s"):format(choice.description or uuid))
	    end
	end)
    end)
end

function M.task_done_stop()
    -- stop time first, then mark task done
    Time.stop(function(ok_stop)
	if not ok_stop then return end

	M.task_done()
    end)
end

local function choose_priority(task)
    local priorities = {
	{ label = "High (H)", value = "H" },
	{ label = "Medium (M)", value = "M" },
	{ label = "Low (L)", value = "L" },
	{ label = "None", value = nil },
    }

    vim.ui.select(priorities, {
	prompt = "Set priority",
	format_item = function(p) return p.label end,
    }, function(pchoice)
	    if not pchoice then return end

	    Task.set_priority(task.uuid, pchoice.value, function(ok_set)
		if ok_set then
		    vim.notify(("Priority updated: %s → %s"):format(
			task.description or task.uuid,
			pchoice.value or "None"
		    ))
		end
	    end)
	end)
end

function M.task_priority()
    Pick.pick_pending({
	prompt = "Select from pending tasks to set priority",
    }, function(choice)
	    if not choice then return end
	    choose_priority(choice)
	end)
end

return M

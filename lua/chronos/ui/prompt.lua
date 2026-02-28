local commands = require("chronos.commands")
local taskCmds = require("chronos.commands.task")
local timeCmds = require("chronos.commands.time")
local Projects = require("chronos.projects")
local Pick = require("chronos.ui.task_picker")

local M = {}

local function pick_project(cb)
    local list = Projects.get() or {}
    if #list == 0 then
	return commands.resolve_project(nil, cb) -- will prompt using your resolver logic
    end
    vim.ui.select(list, { prompt = "Project" }, function(choice)
	if not choice then return end
	cb(choice)
    end)
end

local function pick_priority(cb)
    Pick.choose_priority(cb)
end

local function input_desc(prompt, cb)
    vim.ui.input({ prompt = prompt }, function(text)
	if not text or text == "" then return end
	cb(text)
    end)
end

function M.task_add_prompt()
    pick_project(function(project)
	pick_priority(function(prio_flag)
	    input_desc("Task description: ", function(desc)
		taskCmds.task_add({ fargs = { "-p", project, prio_flag, desc } })
	    end)
	end)
    end)
end

function M.task_add_start_prompt()
    pick_project(function(project)
	pick_priority(function(prio_flag)
	    input_desc(function(desc)
		taskCmds.task_add_start({ fargs = { "-p", project, prio_flag, desc } })
	    end)
	end)
    end)
end

function M.time_start_prompt()
    pick_project(function(project)
	pick_priority(function(prio_flag)
	    input_desc("Activity description: ", function(desc)
		timeCmds.time_start({ fargs = { "-p", project, prio_flag, desc } })
	    end)
	end)
    end)
end

return M

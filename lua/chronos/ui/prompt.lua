local taskCmds = require("chronos.commands.task")
local timeCmds = require("chronos.commands.time")
local Pick = require("chronos.ui.task_picker")

local M = {}

local function input_desc(prompt, cb)
    vim.ui.input({ prompt = prompt }, function(text)
	if not text or text == "" then return end
	cb(text)
    end)
end

function M.task_add_prompt()
    Pick.choose_project(function(project)
	Pick.choose_priority(function(prio_flag)
	    input_desc("Task description: ", function(desc)
		taskCmds.task_add({ fargs = { "-p", project, prio_flag, desc } })
	    end)
	end)
    end)
end

function M.task_add_start_prompt()
    Pick.choose_project(function(project)
	Pick.choose_priority(function(prio_flag)
	    input_desc("Task description: ", function(desc)
		taskCmds.task_add_start({ fargs = { "-p", project, prio_flag, desc } })
	    end)
	end)
    end)
end

function M.time_start_prompt()
    Pick.choose_project(function(project)
	Pick.choose_priority(function(prio_flag)
	    input_desc("Activity description: ", function(desc)
		timeCmds.time_start({ fargs = { "-p", project, prio_flag, desc } })
	    end)
	end)
    end)
end

return M

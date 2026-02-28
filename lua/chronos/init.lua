local M = {}
local commands = require("chronos.commands")
local timeCmds = require("chronos.commands.time")
local taskCmds = require("chronos.commands.task")
local vim = vim

function M.setup(opts)
    require("chronos.config").setup(opts)
    require("chronos.projects").refresh()

    vim.api.nvim_create_user_command("ChronosTimeStart", function(cmd)
	timeCmds.time_start(cmd)
    end, {
	    nargs = "+",
	    complete = "customlist,v:lua.require'chronos.complete'.project_arg"
	})

    vim.api.nvim_create_user_command("ChronosTimeStop", function()
	timeCmds.time_stop()
    end, {})

    vim.api.nvim_create_user_command("ChronosTimeContinue", function()
	timeCmds.time_continue()
    end, {})

    vim.api.nvim_create_user_command("ChronosProjectSelect", function()
	commands.project_select()
    end, {})

    vim.api.nvim_create_user_command("ChronosTaskAdd", function(cmd)
	taskCmds.task_add(cmd)
    end, {
	    nargs = "+",
	    complete = "customlist,v:lua.require'chronos.complete'.project_arg"
	})

    vim.api.nvim_create_user_command("ChronosTaskAddStart", function(cmd)
	taskCmds.task_add_start(cmd)
    end, {
	    nargs = "+",
	    complete = "customlist,v:lua.require'chronos.complete'.project_arg"
	})

    vim.api.nvim_create_user_command("ChronosTaskStart", function()
	taskCmds.task_start()
    end, {})

    vim.api.nvim_create_user_command("ChronosProjectsRefresh", function()
	require("chronos.projects").refresh(function(ok, list)
	    if ok then
		vim.notify(("Chronos: refreshed projects (%d)"):format(#list))
	    end
	end)
    end, {})

    vim.api.nvim_create_user_command("ChronosTaskDone", function()
	taskCmds.task_done()
    end, {})

    vim.api.nvim_create_user_command("ChronosTaskDoneStop", function()
	taskCmds.task_done_stop()
    end, {})

    vim.api.nvim_create_user_command("ChronosTaskReopen", function()
	taskCmds.task_reopen()
    end, {})

    vim.api.nvim_create_user_command("ChronosTaskPriority", function()
	taskCmds.task_priority()
    end, {})

end

return M

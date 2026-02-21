-- local M = {}
--
-- function M.setup(opts)
--     opts = opts or {}
--
--     vim.api.nvim_create_user_command("ChronosStart", function()
-- 	vim.system(
-- 	    { "task", "status:pending", "export" },
-- 	    { text = true },
-- 	    function(res)
-- 		vim.schedule(function()
-- 		    if res.code ~= 0 then
-- 			vim.notify("Task export failed:\n" .. (res.stderr or ""), vim.log.levels.ERROR)
-- 			return
-- 		    end
--
-- 		    local ok, data = pcall(vim.json.decode, res.stdout or "")
-- 		    if not ok then
-- 			vim.notify("Failed to decode Taskwarrior JSON", vim.log.levels.ERROR)
-- 			return
-- 		    end
--
-- 		    vim.notify("Chronos: found " .. tostring(#data) .. " pending tasks")
-- 		end)
-- 	    end
-- 	)
--     end, {})
-- end
--
-- return M
--
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

end

return M

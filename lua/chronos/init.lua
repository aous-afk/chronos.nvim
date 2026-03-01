local M = {}
local commands = require("chronos.commands")
local timeCmds = require("chronos.commands.time")
local taskCmds = require("chronos.commands.task")
local vim = vim

local function create(name, fn, opts)
  vim.api.nvim_create_user_command(name, fn, opts or {})
end

function M.setup(opts)
    if opts and opts.keymaps then
	require("chronos.keymaps").setup(opts.keymaps)
    end
    require("chronos.config").setup(opts)
    require("chronos.projects").refresh()
    local complete_project = "customlist,v:lua.require'chronos.complete'.chronos_args"
    local defs = {
	-- Time
	{ "ChronosTimeStart",    function(cmd) timeCmds.time_start(cmd) end,    { nargs = "+", complete = complete_project } },
	{ "ChronosTimeStop",     function() timeCmds.time_stop() end,           {} },
	{ "ChronosTimeContinue", function() timeCmds.time_continue() end,       {} },

	-- Project
	{ "ChronosProjectSelect", function() commands.project_select() end,      {} },
	{ "ChronosProjectsRefresh", function()
	    require("chronos.projects").refresh(function(ok, list)
		if ok then vim.notify(("Chronos: refreshed projects (%d)"):format(#list)) end
	    end)
	end, {} },

	-- Task
	{ "ChronosTaskAdd",      function(cmd) taskCmds.task_add(cmd) end,       { nargs = "+", complete = complete_project } },
	{ "ChronosTaskAddStart", function(cmd) taskCmds.task_add_start(cmd) end, { nargs = "+", complete = complete_project } },
	{ "ChronosTaskStart",    function() taskCmds.task_start() end,           {} },
	{ "ChronosTaskDone",     function() taskCmds.task_done() end,            {} },
	{ "ChronosTaskDoneStop", function() taskCmds.task_done_stop() end,       {} },
	{ "ChronosTaskReopen",   function() taskCmds.task_reopen() end,          {} },
	{ "ChronosTaskPriority", function() taskCmds.task_priority() end,        {} },
    }

    for _, d in ipairs(defs) do
	create(d[1], d[2], d[3])
    end

end

return M

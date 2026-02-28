local M = {}
local Time = require("chronos.backend.time")
local c = require("chronos.commands")
local vim = vim

function M.time_start(cmd)
    local explicit_project, description, priority = c.parse_explicit_project_and_desc(cmd)

    if description == "" then
	vim.notify("ChronosTimeStart: description required", vim.log.levels.ERROR)
	return
    end

    description = c.apply_prio_tag(priority, description)

    c.resolve_project(explicit_project, function(project)
	Time.start(project, description, function(ok)
	    if ok then
		require("chronos.projects").refresh()
		vim.notify(("Started bartib: [%s] %s"):format(project, description))
	    end
	end)
    end)
end

function M.time_stop()
  Time.stop(function(ok)
    if ok then
      vim.notify("Stopped bartib")
    end
  end)
end

function M.time_continue()
    Time.last(function(ok, res)
	if not ok then return end

	local items = (res.items or {})
	if #items == 0 then
	    vim.notify("No recent bartib activities to continue", vim.log.levels.INFO)
	    return
	end

	vim.ui.select(
	    items,
	    {
		prompt = "Continue activity",
		format_item = function(it)
		    local p = it.project and (" [" .. it.project .. "]") or ""
		    return ("[%d] %s%s"):format(it.idx, it.description, p)
		end,
	    },
	    function(choice)
		if not choice then return end
		Time.continue(choice.idx, function(ok2)
		    if ok2 then
			require("chronos.projects").refresh()
			vim.notify(("Continued: [%d] %s"):format(choice.idx, choice.description))
		    end
		end)
	    end)
    end)
end

return M

local M = {}

local function defaults()
    local A = require("chronos.actions")

    return {
	-- time
	ts = { "n", "ts", A.time_start_prompt, "Start time tracking" },
	tt = { "n", "tt", A.time_stop, "Stop time tracking" },
	tc = { "n", "tc", A.time_continue, "Continue last activity" },

	-- task
	ka = { "n", "ka", A.task_add_prompt, "Add new task" },
	kA = { "n", "kA", A.task_add_start_prompt, "Add and start task" },
	ks = { "n", "ks", A.task_start, "Start existing task" },
	kd = { "n", "kd", A.task_done, "Mark task done" },
	kD = { "n", "kD", A.task_done_stop, "Done task and stop" },
	kr = { "n", "kr", A.task_reopen, "Reopen completed task" },
	kp = { "n", "kp", A.task_priority, "Set task priority" },

	-- project
	ps = { "n", "ps", A.project_select, "Select active project" },
	pr = { "n", "pr", A.projects_refresh, "Refresh project cache" },
    }
end

local function apply_disable(map_tbl, disable)
    if type(disable) ~= "table" then return end
    for _, id in ipairs(disable) do
	map_tbl[id] = nil
    end
end

local function apply_overrides(map_tbl, overrides)
    if type(overrides) ~= "table" then return end
    for id, def in pairs(overrides) do
	if def == false then
	    map_tbl[id] = nil
	elseif type(def) == "table" then
	    map_tbl[id] = def
	end
    end
end

local function sorted_keys(t)
    local keys = {}
    for k, _ in pairs(t) do table.insert(keys, k) end
    table.sort(keys)
    return keys
end

function M.setup(opts)
    opts = opts or {}
    if not opts.enabled then
	return
    end

    local prefix = opts.prefix or "<leader>m"
    local maps = defaults()

    apply_disable(maps, opts.disable)
    apply_overrides(maps, opts.overrides)

    for _, id in ipairs(sorted_keys(maps)) do
	local def = maps[id]
	local mode, lhs_suffix, rhs, desc, extra = def[1], def[2], def[3], def[4], def[5]

	local lhs = prefix .. lhs_suffix
	local km_opts = { noremap = true, silent = true, desc = desc }
	if type(extra) == "table" then
	    km_opts = vim.tbl_extend("force", km_opts, extra)
	end

	vim.keymap.set(mode, lhs, rhs, km_opts)
    end
end

return M

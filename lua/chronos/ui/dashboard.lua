local Config = require("chronos.config")
local Time = require("chronos.backend.time")
local Task = require("chronos.backend.task")
local vim = vim

local M = {}

local state = {
    buf = nil,
    win = nil,
    ns = vim.api.nvim_create_namespace("chronos_dashboard"),
    -- Maps 1-based line number → task uuid, rebuilt on every task render.
    line_task_map = {},
    -- Remembers which task view is active so `d` and `a` can refresh it.
    -- Values: "all" | "project"
    last_task_view = nil,
}
local function flatten_newlines(s)
    s = s or ""
    s = s:gsub("\r\n", "\n"):gsub("\r", "\n")
    s = s:gsub("\n", " ")
    return s
end

local function pad_right(s, width)
    s = s or ""
    if #s >= width then return s end
    return s .. string.rep(" ", width - #s)
end

local function compact(s)
    s = flatten_newlines(s)
    s = s:gsub("%s+", " ")
    return s:gsub("^%s+", ""):gsub("%s+$", "")
end
local function oneline(s)
    s = s or ""
    s = s:gsub("\r\n", "\n"):gsub("\r", "\n")
    s = s:gsub("\n", " ")      -- flatten newlines
    s = s:gsub("%s+", " ")     -- collapse whitespace
    return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function strip_ansi(s)
    -- remove CSI sequences like ESC[1m, ESC[0m, ESC[38;5;...m, etc.
    return (s or ""):gsub("\27%[[0-9;]*m", "")
end

local function load_state(cb)
    cb = cb or function() end

    local project = (Config.get_current_project and Config.get_current_project()) or Config.opts.default_project
    if not project or project == "" then project = Config.opts.default_project end

    local state_lines = {
	("Project: %s"):format(project),
	"Tracking: (loading...)",
	"Pending: (loading...)",
    }

    Time.current(function(r)
	if r and r.ok then
	    local info = Time.parse_bartib_current(r.stdout)
	    if info then
		state_lines[2] = ("Tracking: [%s] %s (%s)"):format(
		    info.project or "?",
		    compact(info.description or ""),
		    info.duration or "?"
		)
	    else
		state_lines[2] = "Tracking: none"
	    end
	else
	    state_lines[2] = "Tracking: none"
	end

	Task.count_pending(project, function(r2)
	    local pending = "?"
	    if r2 and r2.ok then
		local out2 = compact(r2.stdout)
		if out2:match("^%d+$") then pending = out2 end
	    end
	    state_lines[3] = ("Pending: %s"):format(pending)

	    cb(state_lines)
	end)
    end)
end

local function clear_hl()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
    vim.api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)
end

local function hl_range(line0, col_start, col_end, group)
    vim.api.nvim_buf_add_highlight(state.buf, state.ns, group, line0, col_start, col_end)
end

local function apply_task_highlights()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
    clear_hl()

    local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)

    for i, line in ipairs(lines) do
	local l0 = i - 1

	-- highlight "#123"
	do
	    local s, e = line:find("#%d+")
	    if s then hl_range(l0, s - 1, e, "Identifier") end
	end

	-- highlight "prio:H/M/L"
	do
	    local s, e = line:find("prio:%u")
	    if s then hl_range(l0, s - 1, e, "Type") end
	end

	-- highlight "[Project.Name]"
	do
	    local s, e = line:find("%b[]")
	    if s then hl_range(l0, s - 1, e, "Title") end
	end
    end
end

local function apply_report_highlights()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end

    vim.api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)

    local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
    for i, line in ipairs(lines) do
	-- rough: "Project............. 5h 51m"
	if line:match("^%S") and line:match("%.%.") and line:match("%d") then
	    vim.api.nvim_buf_add_highlight(state.buf, state.ns, "Title", i - 1, 0, -1)
	elseif line:match("^%s+") then
	    -- sub-items slightly dimmer
	    vim.api.nvim_buf_add_highlight(state.buf, state.ns, "Comment", i - 1, 0, -1)
	end
    end
end

local function set_lines(lines, opts)
    opts = opts or {}
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
    if opts.sanitize then
	for i, l in ipairs(lines or {}) do
	    if type(l) ~= "string" then lines[i] = tostring(l) end
	    lines[i] = flatten_newlines(lines[i])
	end
    end

    vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
end

local function header(state_lines)
    local lines = { "Chronos", "", "Current state:" }
    for _, l in ipairs(state_lines or {}) do
	table.insert(lines, "  " .. l)
    end

    table.insert(lines, "")
    table.insert(lines, "Keys:")

    table.insert(lines, "  w  Weekly report (bartib)")

    local colw = 40
    table.insert(lines,
	"  " .. pad_right("p  Pending (current project)", colw) .. "t  Pending (all)"
    )
    table.insert(lines,
	"  " .. pad_right("d  Mark task done (on task line)", colw) .. "a  Add task"
    )
    table.insert(lines,
	"  " .. pad_right("r  Refresh state", colw) .. "q  Close"
    )

    table.insert(lines, "")
    return lines
end

local function render_with_state(build_body_lines, apply_hl)
    load_state(function(state_lines)
	local head = header(state_lines)
	local body = build_body_lines() or {}
	set_lines(vim.list_extend(head, body), { sanitize = true })
	if apply_hl then apply_hl() end
    end)
end

function M.show_weekly_report()
    render_with_state(function()
	return { "Loading weekly report...", "" }
    end)

    Time.report_current_week(function(res)
	if res.code ~= 0 then
	    return render_with_state(function()
		return { "ERROR: bartib report failed", res.stderr or "" }
	    end)
	end

	local out = strip_ansi(res.stdout):gsub("\r\n", "\n")
	local report_lines = vim.split(out, "\n", { plain = true })

	render_with_state(function()
	    return report_lines
	end, apply_report_highlights)
    end)
end

-- Rebuild line→uuid map by scanning the buffer for rendered task lines.
-- Called after every task render so `d` always has fresh data.
local function rebuild_line_task_map(tasks)
    state.line_task_map = {}
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end

    -- Build id→uuid lookup from the task list (id is the short numeric id)
    local id_to_uuid = {}
    for _, t in ipairs(tasks or {}) do
	if t.id and t.uuid then
	    id_to_uuid[tostring(t.id)] = t.uuid
	end
    end

    local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
    for i, line in ipairs(lines) do
	-- task lines look like:  "- #42 prio:H [Project] description"
	local id_str = line:match("^%- #(%d+)")
	if id_str and id_to_uuid[id_str] then
	    state.line_task_map[i] = id_to_uuid[id_str]
	end
    end
end

local function render_pending_tasks(tasks, title_line)
    render_with_state(function()
	table.sort(tasks, function(a, b) return (a.id or 0) < (b.id or 0) end)

	local out = {}
	if title_line and title_line ~= "" then
	    table.insert(out, title_line)
	    table.insert(out, "")
	end

	if #tasks == 0 then
	    table.insert(out, "(no pending tasks)")
	    return out
	end

	for _, t in ipairs(tasks) do
	    local id = t.id and ("#" .. t.id .. " ") or ""
	    local pr = t.priority and ("prio:" .. t.priority .. " ") or ""
	    local proj = t.project and ("[" .. t.project .. "] ") or ""
	    local desc = t.description or "<no description>"
	    table.insert(out, ("- %s%s%s%s"):format(id, pr, proj, desc))
	end
	return out
    end, function()
	    apply_task_highlights()
	    rebuild_line_task_map(tasks)
	end)
end

function M.show_pending_tasks_all()
    state.last_task_view = "all"
    render_with_state(function() return { "Loading pending tasks (all)...", "" } end)

    Task.export_raw("pending", function(res)
	if res.code ~= 0 then
	    return render_with_state(function()
		return { "ERROR: task export failed", res.stderr or "" }
	    end)
	end

	local ok, tasks = pcall(vim.json.decode, res.stdout or "[]")
	if not ok or type(tasks) ~= "table" then
	    return render_with_state(function()
		return { "ERROR: failed to decode task JSON" }
	    end)
	end

	render_pending_tasks(tasks, "Pending tasks: (all)")
    end)
end

function M.show_pending_tasks_current_project()
    state.last_task_view = "project"
    local current = Config.get_current_project and Config.get_current_project()
    if not current or current == "" then current = Config.opts.default_project end

    render_with_state(function()
	return { ("Loading pending tasks (project: %s)..."):format(current), "" }
    end)

    Task.export_raw("pending", function(res)
	if res.code ~= 0 then
	    return render_with_state(function()
		return { "ERROR: task export failed", res.stderr or "" }
	    end)
	end

	local ok, tasks = pcall(vim.json.decode, res.stdout or "[]")
	if not ok or type(tasks) ~= "table" then
	    return render_with_state(function()
		return { "ERROR: failed to decode task JSON" }
	    end)
	end

	local filtered = {}
	for _, t in ipairs(tasks) do
	    if t.project == current then table.insert(filtered, t) end
	end

	render_pending_tasks(filtered, "Current project: " .. current)
    end)
end

local function close()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
	vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil

    -- wipe buffer so it doesn't accumulate
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
	vim.api.nvim_buf_delete(state.buf, { force = true })
    end
    state.buf = nil
end

function M.open()
    -- if window exists, just focus it
    if state.win and vim.api.nvim_win_is_valid(state.win) then
	vim.api.nvim_set_current_win(state.win)
	return
    end

    -- reuse existing buffer if still valid; otherwise create it once
    if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(state.buf, "chronos://dashboard")
	vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
	vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
	vim.api.nvim_buf_set_option(state.buf, "filetype", "markdown")
    end

    local ui = vim.api.nvim_list_uis()[1]
    local width = math.floor(ui.width * 0.75)
    local height = math.floor(ui.height * 0.75)
    local row = math.floor((ui.height - height) / 2)
    local col = math.floor((ui.width - width) / 2)

    state.win = vim.api.nvim_open_win(state.buf, true, {
	relative = "editor",
	row = row,
	col = col,
	width = width,
	height = height,
	style = "minimal",
	border = "rounded",
    })

    vim.api.nvim_win_set_option(state.win, "wrap", false)
    vim.api.nvim_win_set_option(state.win, "cursorline", true)

    local opts = { nowait = true, silent = true, buffer = state.buf }
    vim.keymap.set("n", "q", close, vim.tbl_extend("force", opts, { desc = "Close" }))
    vim.keymap.set("n", "w", M.show_weekly_report, vim.tbl_extend("force", opts, { desc = "Weekly report" }))
    vim.keymap.set("n", "p", M.show_pending_tasks_current_project, vim.tbl_extend("force", opts, { desc = "Pending tasks (project)" }))
    vim.keymap.set("n", "t", M.show_pending_tasks_all, vim.tbl_extend("force", opts, { desc = "Pending tasks (all)" }))

    vim.keymap.set("n", "d", function()
	local line = vim.api.nvim_win_get_cursor(state.win)[1] -- 1-based
	local uuid = state.line_task_map[line]
	if not uuid then
	    vim.notify("Chronos: no task on this line", vim.log.levels.WARN)
	    return
	end
	Task.done(uuid, function(ok)
	    if ok then
		vim.notify("Task done ✓")
		-- Refresh whichever task view is currently showing
		if state.last_task_view == "all" then
		    M.show_pending_tasks_all()
		elseif state.last_task_view == "project" then
		    M.show_pending_tasks_current_project()
		end
	    end
	end)
    end, vim.tbl_extend("force", opts, { desc = "Mark task done" }))

    vim.keymap.set("n", "a", function()
	local current = Config.get_current_project and Config.get_current_project()
	if not current or current == "" then current = Config.opts.default_project end

	vim.ui.input({ prompt = ("Add task [%s]: "):format(current) }, function(input)
	    if not input or vim.trim(input) == "" then return end
	    local description = vim.trim(input)
	    Task.add(current, description, nil, function(ok)
		if ok then
		    vim.notify(("Task added: [%s] %s"):format(current, description))
		    -- Refresh the current task view, or default to project view
		    if state.last_task_view == "all" then
			M.show_pending_tasks_all()
		    else
			state.last_task_view = "project"
			M.show_pending_tasks_current_project()
		    end
		end
	    end)
	end)
    end, vim.tbl_extend("force", opts, { desc = "Add task" }))
    vim.keymap.set("n", "r", function()
	set_lines(header({ "Refreshing..." }), { sanitize = true })
	load_state(function(lines)
	    set_lines(header(lines), { sanitize = true })
	end)
    end, vim.tbl_extend("force", opts, { desc = "Refresh state" }))

    set_lines(header({ "Loading..." }))
    load_state(function(lines)
	set_lines(header(lines), { sanitize = true })
    end)
end

return M

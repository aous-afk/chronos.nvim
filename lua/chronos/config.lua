local M = {}

M.opts = {
    default_project = "Work",
    current_project = nil,
    bartib_bin = "bartib",
    task_bin = "task",
}
local function state_file()
    return vim.fn.stdpath("state") .. "/chronos.json"
end

function M.load_state()
    local path = state_file()
    local ok, txt = pcall(vim.fn.readfile, path)
    if not ok or not txt or #txt == 0 then return end

    local decoded_ok, data = pcall(vim.json.decode, table.concat(txt, "\n"))
    if decoded_ok and type(data) == "table" and type(data.current_project) == "string" then
	M.opts.current_project = data.current_project
    end
end

function M.save_state()
    local path = state_file()
    local payload = vim.json.encode({ current_project = M.opts.current_project })
    pcall(vim.fn.writefile, { payload }, path)
end

function M.set_current_project(name)
    M.opts.current_project = name
    M.save_state()
end

function M.get_current_project()
    return M.opts.current_project
end

function M.setup(opts)
    M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
    M.load_state()
end

return M

local M = {}

local function state_file()
    return vim.fn.stdpath("state") .. "/chronos.log"
end

function M.log(msg, level)
    local levels = {
	["error"] = vim.log.levels.ERROR,
	["warn"] = vim.log.levels.WARN,
	["info"] = vim.log.levels.INFO,
	["debug"] = vim.log.levels.DEBUG,
    }
    local lvl = levels[level] or vim.log.levels.INFO
    vim.notify("Chronos: " .. msg, lvl)
    local path = state_file()
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local log_entry = string.format("[%s] %s: %s", timestamp, level:upper(), msg)
    local ok, _ = pcall(vim.fn.writefile, { log_entry }, path, "a")
    if not ok then
	vim.notify("Chronos: failed to write log entry", vim.log.levels.ERROR)
    end
end


return M

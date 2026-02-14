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

function M.setup(opts)
    require("chronos.config").setup(opts)
    local commands = require("chronos.commands")
    vim.api.nvim_create_user_command("ChronosAdd", function(cmd)
	commands.add(cmd)
    end, { nargs = "+", complete = nil })
    vim.api.nvim_create_user_command("ChronosAddStart", function(cmd)
	commands.add_start(cmd)
    end, { nargs = "+", complete = nil })
end

return M

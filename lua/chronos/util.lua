local M = {}

--- Run a command (argv array) and invoke cb on the main thread.
--- @param argv string[] e.g. { "task", "status:pending", "export" }
--- @param opts table|nil passed to vim.system (we typically use { text = true })
--- @param cb fun(res: { ok:boolean, code:integer, stdout:string, stderr:string })
function M.system(argv, opts, cb)
  opts = opts or {}
  cb = cb or function() end

  vim.system(argv, opts, function(res)
    -- Ensure any UI work happens on main thread
    vim.schedule(function()
      cb({
        ok = (res.code == 0),
        code = res.code,
        stdout = res.stdout or "",
        stderr = res.stderr or "",
      })
    end)
  end)
end

--- Convenience: notify error with context
function M.notify_fail(label, r)
  local msg = string.format("%s failed (code %d)\n%s", label, r.code, r.stderr ~= "" and r.stderr or r.stdout)
  vim.notify(msg, vim.log.levels.ERROR)
end

return M

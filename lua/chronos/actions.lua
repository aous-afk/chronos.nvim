local M = {}

function M.time_start_prompt()
  require("chronos.ui.prompt").time_start_prompt()
end

function M.task_add_prompt()
  require("chronos.ui.prompt").task_add_prompt()
end

function M.task_add_start_prompt()
  require("chronos.ui.prompt").task_add_start_prompt()
end

-- Direct commands
function M.time_stop() vim.cmd("ChronosTimeStop") end
function M.time_continue() vim.cmd("ChronosTimeContinue") end

function M.project_select() vim.cmd("ChronosProjectSelect") end
function M.projects_refresh() vim.cmd("ChronosProjectsRefresh") end

function M.task_start() vim.cmd("ChronosTaskStart") end
function M.task_done() vim.cmd("ChronosTaskDone") end
function M.task_done_stop() vim.cmd("ChronosTaskDoneStop") end
function M.task_reopen() vim.cmd("ChronosTaskReopen") end
function M.task_priority() vim.cmd("ChronosTaskPriority") end

return M

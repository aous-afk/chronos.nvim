# chronos.nvim

Chronos integrates **Taskwarrior** and **bartib** inside Neovim.

- Taskwarrior = task database
- bartib = time tracking engine
- Chronos = orchestration + project consistency layer

Projects are merged from both tools and cached for completion.

---

## Requirements

- Neovim ≥ 0.10
- `task` (Taskwarrior) available in `$PATH`
- `bartib` available in `$PATH`

---

## Configuration

All configuration is optional.

```lua
opts = {
    default_project = "Work",
    bartib_bin = "bartib",
    task_bin = "task",

    -- Optional: seed additional projects (merged into project cache)
    projects = nil, -- { "backend", "frontend", "Home.Kitchen" }

    -- Optional: keymap installer (opt-in)
    -- If nil, Chronos does not install any keymaps.
    keymaps = nil,
    -- or
    -- keymaps = {
        -- enabled = true,
        -- prefix = "m",
        -- overrides = {
        -- 	ts = { "n", "ms", function() require("chronos.actions").time_start_prompt() end, "Start time tracking" },
        -- },
        -- disable = { "pr" },
    -- },

}
```

### Custom Projects

You can seed additional projects:

```lua
opts = {
  projects = { "backend", "frontend", "Home.Kitchen" },
}
```

These are merged with:

- `bartib projects`
- Taskwarrior project values
- your configured list

All merged and deduplicated.

---

## Project Model

- Projects are simple strings.
- Both Taskwarrior and bartib implicitly create projects if they do not exist.
- Chronos maintains:
  - a current project
  - a cached merged project list (from Taskwarrior + bartib)
- `-p <project>` acts as a context switch and updates the current project.
- Project names support native Neovim command-line completion after `-p`.

---

## Commands

| Command | Description |
|---|---|
| `:ChronosProjectSelect` | Prompts you to select a project (merged from Taskwarrior + bartib) and sets it as the current project. |
| `:ChronosProjectsRefresh` | Refreshes the internal merged project cache manually. |
| `:ChronosTimeStart [-p <project>] <description>` | Starts a bartib activity. Uses `-p` if provided; otherwise uses the current project or prompts once. |
| `:ChronosTimeStop` | Stops the currently running bartib activity. |
| `:ChronosTimeContinue` | Lists recent bartib activities and continues the selected one. |
| `:ChronosTaskAdd [-p <project>] <description>` | Creates a Taskwarrior task under the resolved project. |
| `:ChronosTaskAddStart [-p <project>] <description>` | Creates a Taskwarrior task and immediately starts tracking it in bartib. |
| `:ChronosTaskStart` | Shows pending Taskwarrior tasks, lets you select one, and starts tracking it in bartib (does not change task status). |
| `:ChronosTaskDone` | Shows pending Taskwarrior tasks and marks the selected task as done (uses UUID for stability). |
| `:ChronosTaskDoneStop` | Stops the current bartib activity, then marks the selected pending task as done. |
| `:ChronosTaskReopen` | Shows completed tasks and reopens the selected task (`status:pending`). |
| `:ChronosTaskPriority` | Select a pending task and update its priority (H / M / L / None). |

---

## Behavior Notes

- `-p <project>` updates the global current project.
- Project cache is refreshed automatically after:
  - successful time start
  - successful task add
  - successful task add+start
  - successful task completion
- Completion for `-p` uses the cached project list.
- Projects are merged and deduplicated from:
  - `bartib projects`
  - Taskwarrior project list
  - `opts.projects` (if configured)
- `ChronosTaskDone` and `ChronosTaskDoneStop` use Taskwarrior UUIDs to avoid instability of numeric IDs.

---

## Command-line Completion

### Commands supporting `-p`:

- `:ChronosTimeStart`
- `:ChronosTaskAdd`
- `:ChronosTaskAddStart`

Usage:

```vim
:ChronosTimeStart -p <Tab>
:ChronosTaskAdd -p <Tab>
:ChronosTaskAddStart -p <Tab>
```

Completion uses Neovim native `customlist` completion.

### Priority Flags

Commands that support priority flags:

- `:ChronosTaskAdd`
- `:ChronosTaskAddStart`
- `:ChronosTimeStart` (adds `prio:` tag to description for consistency)

Supported flags:

- `-H` → High priority
- `-M` → Medium priority
- `-L` → Low priority
- `-N` → Remove priority (None)

Examples:

```vim
:ChronosTaskAdd -p backend -H Fix login bug
:ChronosTaskAddStart -M Refactor service layer
:ChronosTimeStart -L Minor cleanup
```

### Interactive Flow (Project → Priority → Description)

When using Chronos through interactive actions (keymaps or dashboard):

1. Select project  
2. Select priority (High / Medium / Low / None)  
3. Enter description  

The command is then executed internally with the correct flags.

Example flow:

- Pick project → `backend`
- Pick priority → `High`
- Enter description → `Fix login bug`

Internally becomes:

```vim
:ChronosTaskAddStart -p backend -H Fix login bug
```

You only need to type flags when using commands manually.
Interactive usage handles this automatically.

---

## Example Workflows

### Select project once

```vim
:ChronosProjectSelect
:ChronosTimeStart Implement feature X
```

### Switch project via -p

```vim
:ChronosTimeStart -p backend Fix login bug
```

### Create and track immediately

```vim
:ChronosTaskAddStart -p frontend Implement new UI
```

### Track existing task

```vim
:ChronosTaskStart
```

### Complete a task

```vim
:ChronosTaskDone
```

### Stop time and complete a task

```vim
:ChronosTaskDoneStop
```

### Reopen a completed task

```vim
:ChronosTaskReopen
```

---

## Default Keymaps

``` lua
    -- default prefix "<leader>m"

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
```

---

## Notes

- `ChronosTimeContinue` uses `bartib last` and continues by index.
- Parsing is intentionally minimal (index only) to avoid brittle column parsing.
- Task completion is done via `task <uuid> done` for stability.
- Dashboard currently displays raw CLI output; long-term plan is structured JSON via backend.

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
- `ChronosTaskDone` and `ChronosTaskDoneStop` use Taskwarrior UUIDs to avoid instability of numeric IDs.

---

## Command-line Completion

Commands supporting `-p`:

- `:ChronosTimeStart`
- `:ChronosTaskAdd`
- `:ChronosTaskAddStart`

Usage:

```vim
:ChronosTimeStart -p <Tab>
:ChronosTaskAdd -p <Tab>
:ChronosTaskAddStart -p <Tab>
```

Completion is native Neovim `customlist` completion.

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

## Notes

- `ChronosTimeContinue` uses `bartib last` and continues by index.
- Parsing is intentionally minimal (index only) to avoid brittle column parsing.
- Task completion is done via `task <uuid> done` for stability.

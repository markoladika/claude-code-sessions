# claude-code-sessions

Small quality-of-life kit for managing **Claude Code** CLI **sessions**: named & resumable
sessions, `ls`/`rm` management, a compact status line, and a Shift+Tab bypass toggle.
Works on macOS and Linux. No tmux required.

> A **session** here = a **Claude Code conversation** (a transcript you can name/resume).
> Not to be confused with an *agent* in [orchestrator-protocol](https://github.com/markoladika/orchestrator-protocol),
> where an agent = a session **+** a durable notebook **+** a worktree. The two are independent
> and share no files (this touches `~/.claude/projects/`); they compose if you name a session
> the same as an agent slice. Use either alone, or both.

> Not affiliated with or endorsed by Anthropic. "Claude" and "Claude Code" are trademarks of Anthropic.

## What you get

A thin `claude` shell wrapper (your real `claude` is untouched — called via `command claude`):

| Command | Does |
|---|---|
| `claude <name>` | **Resume** the saved session of that name if it exists, else start a **new** named session |
| `claude ls` | List this project's saved sessions (name · modified · id) |
| `claude rm <name>` | Delete a saved session (so `claude <name>` starts fresh) |
| `claude` / `claude --resume` … | Normal launch; **bypass-permissions** available via **Shift+Tab** |
| `claude mcp` / `config` / … | Real subcommands pass through untouched |

Plus an optional **status line**:

```
ctx:2% | token:23k | 5h:6pm ▓░░░░ 31% | 7d:Thu 4am 10% | Opus 4.8
```
context-window %, current context tokens, 5h/7d rate-limit reset times + a small usage bar, and the model.

## Install

```bash
git clone https://github.com/markoladika/claude-code-sessions.git
cd claude-code-sessions

# 1) session wrapper + helpers (zsh by default; pass ~/.bashrc for bash)
bash setup_claude_wrapper.sh            # or: bash setup_claude_wrapper.sh ~/.bashrc
source ~/.zshrc

# 2) (optional) status line — point Claude Code at it:
#    add to ~/.claude/settings.json:
#    { "statusLine": { "type": "command", "command": "<abs-path>/statusline.sh" } }
```

The wrapper installer is idempotent (re-run any time; it backs up your rc first) and
**relocatable** — it bakes in the absolute path to `cc-sessions.py` wherever you cloned the repo.

## Files
- `setup_claude_wrapper.sh` — installs the `claude()` wrapper + `ls`/`rm` routing into your shell rc.
- `cc-sessions.py` — backend: resolves a session name → id, lists, and deletes sessions for the
  current project (reads `~/.claude/projects/<cwd>/*.jsonl`, where `claude --name` is stored as `customTitle`).
- `statusline.sh` — the status line script.

## How it works
Claude Code already persists every session as `~/.claude/projects/<cwd-with-slashes-as-dashes>/<id>.jsonl`
and stores the `--name` value as `customTitle`. `cc-sessions.py` reads those to map name→id, so
`claude <name>` runs the native `claude -r <id>` (full history + context restored) when a match exists,
or `claude --name <name>` when it doesn't. Nothing is stored outside Claude Code's own session files.

**Orchestration-aware (optional, auto-detected).** If the repo ships
[orchestrator-protocol](https://github.com/markoladika/orchestrator-protocol)'s
`orchestration/agent-bind.sh`, `claude <name>` also **binds the session to the matching agent**:
it points the session at `orchestration/agents/<name>/` (durable notebook) and, for a new name,
asks once before creating that notebook. If that file isn't present, the wrapper behaves exactly as
above — so this stays a standalone tool and only re-couples when the orchestrator is set up in the repo.

## Requirements
- Claude Code CLI (`claude`) v2.1.32+
- `python3` (session wrapper) and `jq` (status line)
- zsh or bash; macOS or Linux (reset-time formatting handles both BSD and GNU `date`)

## Caveats
- **Sessions are per project directory** — `claude billing` in two different repos are two different sessions; `ls`/`rm` act on your current folder.
- Resume restores the conversation history + model context; if a session was compacted, the model carries the post-compaction summary (the full raw transcript stays on disk).
- `claude rm` permanently deletes a session transcript (and its attachments).
- **Bypass-permissions skips ALL permission checks** when you toggle it — use deliberately.

## Uninstall
- Remove the `# >>> cc-kit >>>` … `# <<< cc-kit <<<` block from your shell rc (a `.bak` was saved at install).
- Remove the `statusLine` entry from `~/.claude/settings.json` if you added it.

## License
MIT

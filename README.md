# cursor-agent-sleep-hooks

Keep your computer awake while **Cursor agent chat sessions** are open.

Long agent runs (builds, tests, multi-step tasks) often outlast your display or system sleep timer. This repo installs **user-level [Cursor hooks](https://cursor.com/docs/agent/hooks)** that temporarily prevent sleep for the duration of an agent session, then restore normal behavior when the session ends.

Works on **macOS**, **Windows**, and **Linux**. No extra packages required.

## Features

- **Automatic** — starts on agent `sessionStart`, stops on `sessionEnd`
- **Global** — applies to all Cursor projects (user hooks in `~/.cursor`)
- **Multi-chat safe** — reference counting; sleep stays off until the **last** agent session closes
- **No network** — scripts only run locally; no data is sent anywhere
- **Reversible** — one-command uninstall

## Requirements

| Requirement | Notes |
|-------------|-------|
| [Cursor](https://cursor.com) with **Hooks** support | Check **Cursor Settings → Hooks** |
| macOS | Built-in `caffeinate` |
| Windows | Built-in PowerShell |
| Linux | `systemd-inhibit` (preferred) or `caffeinate` if installed |

## Quick install

### macOS / Linux

```bash
git clone https://github.com/Mahmoudiyan/cursor-agent-sleep-hooks.git
cd cursor-agent-sleep-hooks
chmod +x install.sh
./install.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/Mahmoudiyan/cursor-agent-sleep-hooks.git
cd cursor-agent-sleep-hooks
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

### After install

1. **Restart Cursor** (or reload the window)
2. Open **Cursor Settings → Hooks** — you should see `sessionStart` and `sessionEnd` entries
3. Start an agent chat → your machine should stay awake
4. Close the agent chat → sleep behavior returns to normal

## Remote SSH (Linux servers)

When you use **Cursor Remote SSH**, the agent runs on the **remote server**. Hooks must be installed in that server's `~/.cursor/`, not on your laptop.

From your Mac or Linux dev machine (with SSH access):

```bash
# One host
./install-remote.sh dev-server

# Several hosts
./install-remote.sh dev-server staging-server

# Hosts listed in remote-hosts.txt
cp remote-hosts.txt.example remote-hosts.txt   # first time only
./install-remote.sh --all
```

Install **locally and on remotes** in one step:

```bash
./install.sh --remote-all
# or
./install.sh --remote dev-server
```

Then **reload** the Remote SSH Cursor window and check **Settings → Hooks** on the remote connection.

Uninstall from remotes:

```bash
./uninstall-remote.sh --all
```

| Machine | Hooks location | Install command |
|---------|----------------|-----------------|
| Your Mac / Windows PC | Local `~/.cursor/` | `./install.sh` or `install.ps1` |
| Linux VPS (Remote SSH) | Remote `~/.cursor/` | `./install-remote.sh <host>` |

**Note:** Remote hooks keep the **server** awake. Your **local Mac** still needs its own install if you want the laptop awake during local (non-SSH) work.

## How it works

Cursor runs small scripts at hook events. This repo registers two hooks in `~/.cursor/hooks.json`:

| Event | Action |
|-------|--------|
| `sessionStart` | Increment session counter; if first session, start sleep inhibition |
| `sessionEnd` | Decrement counter; if zero, stop sleep inhibition |

### Platform details

| OS | Mechanism | What it does |
|----|-----------|--------------|
| **macOS** | `caffeinate -dims` | Prevents idle, disk, and display sleep while active |
| **Windows** | `SetThreadExecutionState` | Windows API power assertion (same class of behavior as `caffeinate`) |
| **Linux** | `systemd-inhibit` | Blocks idle/sleep/lid-close while agent runs; falls back to `caffeinate` if available |

The installer detects your OS and copies the matching scripts:

```
install.sh   → mac/ or linux/
install.ps1  → windows/
```

### What gets installed

```
~/.cursor/
├── hooks.json                          # Hook registration
├── hooks/
│   ├── prevent-sleep-start.{sh,cmd,ps1}
│   ├── prevent-sleep-stop.{sh,cmd,ps1}
│   └── prevent-sleep-daemon.ps1        # Windows only
├── agent-caffeinate.pid                # Runtime (created on use)
└── agent-caffeinate.count              # Runtime (created on use)
```

On Windows, `~` means `%USERPROFILE%`.

## Verify it is working

### macOS

```bash
# While an agent chat is open:
pgrep -lf caffeinate
```

### Windows (PowerShell)

```powershell
# While an agent chat is open — look for a hidden PowerShell running prevent-sleep-daemon.ps1
Get-Process powershell | Where-Object { $_.MainWindowTitle -eq '' }
```

### Linux

```bash
pgrep -af 'systemd-inhibit|sleep infinity|caffeinate'
```

### Cursor

Open **Output** panel → select **Hooks** channel to see hook execution logs.

## Uninstall

```bash
# macOS / Linux
./uninstall.sh
```

```powershell
# Windows
.\uninstall.ps1
```

Then restart Cursor.

### Manual cleanup (if needed)

```bash
rm -f ~/.cursor/hooks.json
rm -f ~/.cursor/hooks/prevent-sleep-*
rm -f ~/.cursor/agent-caffeinate.pid ~/.cursor/agent-caffeinate.count
```

On Windows, replace `~/.cursor` with `%USERPROFILE%\.cursor`.

## Troubleshooting

### Hooks do not appear in Cursor Settings

- Restart Cursor after running the installer
- Confirm `~/.cursor/hooks.json` exists
- On Windows, ensure `.cmd` wrappers were copied to `~/.cursor/hooks/`

### Mac still sleeps during agent work

- Confirm an **agent chat session** is open (hooks fire on session boundaries, not per tool call)
- Check **Output → Hooks** for errors
- Run manual cleanup (above), reinstall, restart Cursor

### Windows: script execution blocked

Run install with execution policy bypass (see install steps) or:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### Linux: nothing starts

Install `systemd` user session tools, or install `caffeinate` from your distro. The start script exits quietly if neither is available.

### Stale sleep hold after a crash

```bash
# macOS / Linux
kill "$(cat ~/.cursor/agent-caffeinate.pid)" 2>/dev/null
rm -f ~/.cursor/agent-caffeinate.pid ~/.cursor/agent-caffeinate.count
```

On Windows, end the hidden PowerShell process listed in the PID file, then delete the PID/count files.

## FAQ

**Does this keep the display on?**  
On macOS, yes (`caffeinate -d`). On Windows, display-required is requested. On Linux, behavior depends on `systemd-inhibit` settings.

**Does it work on battery?**  
Yes. It does not change system power settings permanently — only holds sleep while the agent session is active.

**Project hooks vs user hooks?**  
This installs **user hooks** (all projects). For a single repo only, copy `mac/`, `linux/`, or `windows/` into that repo's `.cursor/` instead of running the global installer.

**Is it safe to run?**  
All scripts are short and open source. They only write to `~/.cursor/` and start/stop OS sleep inhibition. Review the `mac/`, `windows/`, and `linux/` folders before installing.

**Will this conflict with my other hooks?**  
The installer **replaces** `~/.cursor/hooks.json`. If you already have custom hooks, merge the `sessionStart` / `sessionEnd` entries manually instead of running the installer as-is.

**Remote SSH window has no hooks?**  
Install on the **remote Linux host** with `./install-remote.sh <ssh-host>`. Local hooks do not apply to Remote SSH sessions.

## Repository layout

```
cursor-agent-sleep-hooks/
├── install.sh / install.ps1       # Local installers
├── install-remote.sh              # Deploy to SSH hosts (Linux)
├── uninstall.sh / uninstall.ps1
├── uninstall-remote.sh
├── remote-hosts.txt.example       # Template for your SSH host list
├── mac/                           # macOS scripts + hooks.json
├── windows/                       # Windows scripts + hooks.json
├── linux/                         # Linux scripts + hooks.json
├── LICENSE                        # MIT
└── README.md
```

## Contributing

Issues and pull requests are welcome. For platform-specific behavior, edit the files under `mac/`, `windows/`, or `linux/`, then run the matching installer on that OS to test.

## License

[MIT](LICENSE) — free to use, modify, and distribute.

# cursor-agent-sleep-hooks

Prevent your computer from sleeping while a Cursor agent chat session is open.

Installs user-level Cursor hooks (`~/.cursor/hooks.json`) that work across all projects.

## Supported platforms

| OS | Mechanism |
|----|-----------|
| macOS | `caffeinate` (built-in) |
| Windows | PowerShell `SetThreadExecutionState` (built-in) |
| Linux | `systemd-inhibit` (fallback: `caffeinate`) |

Multiple agent chats are reference-counted: sleep prevention stays on until the last session closes.

## Install

### macOS / Linux

```bash
git clone git@github.com:Mahmoudiyan/cursor-agent-sleep-hooks.git
cd cursor-agent-sleep-hooks
chmod +x install.sh
./install.sh
```

### Windows (PowerShell)

```powershell
git clone git@github.com:Mahmoudiyan/cursor-agent-sleep-hooks.git
cd cursor-agent-sleep-hooks
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

Then restart Cursor and check **Settings → Hooks**.

## Uninstall

- macOS / Linux: `./uninstall.sh`
- Windows: `.\uninstall.ps1`

## How it works

- `sessionStart` → start sleep inhibition
- `sessionEnd` → stop sleep inhibition (when last session closes)

See `INSTALL.txt` for manual cleanup if needed.

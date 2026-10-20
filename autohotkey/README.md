# Spectacle for Windows (AutoHotkey)

`Spectacle.ahk` is an AutoHotkey v2 script that recreates the Mac app Spectacle's window
keybindings. It also switches virtual desktops with Win+1–5, and those switches only
affect the primary monitor.

## Setup on a fresh Windows install

Requires Windows 11 and `winget`, which comes with Windows 11.

1. Clone this repo.
2. From the repo root, run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\autohotkey\install.ps1
   ```
   The script:
   - installs AutoHotkey v2 with winget
   - downloads the latest
     [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor) DLL into
     `autohotkey\VirtualDesktopAccessor\` (git-ignored)
   - adds a Startup-folder shortcut so the script runs at login
   - starts the script

   You can safely run it again; it closes the running copy and starts it again.

The Startup shortcut points at the script in this repo. To change something, edit
`Spectacle.ahk` here, reload it (right-click the green **H** tray icon → **Reload Script**),
and commit.

## Keybindings

Spectacle's modifiers are translated as: control → **Ctrl**, option → **Win**, command → **Alt**.

| Spectacle | Windows | Action |
|---|---|---|
| ⌥⌘ ← → ↑ ↓ | Win+Alt+arrows | Left/right/top/bottom half. Pressing again cycles ½ → ⅔ → ⅓ |
| ⌥⌘F | Win+Alt+F | Fill the screen (not covering the taskbar) |
| ⌥⌘C | Win+Alt+C | Center |
| ⌃⌘ ← / → | Ctrl+Alt+←/→ | Top-left / top-right quarter |
| ⌃⇧⌘ ← / → | Ctrl+Shift+Alt+←/→ | Bottom-left / bottom-right quarter |
| ⌃⌥⌘ ← / → | Ctrl+Win+Alt+←/→ | Previous / next monitor, ordered left to right |
| ⌃⌥ ← / → | Ctrl+Win+←/→ | Previous / next third |
| ⌃⌥⇧ ← / → | Ctrl+Win+Shift+←/→ | Make smaller / larger |
| ⌥⌘Z / ⌥⇧⌘Z | Win+Alt+Z / Win+Shift+Alt+Z | Undo / redo |
| — | Win+1 … Win+5 | Go to virtual desktop N, creating it if needed |

These replace some built-in Windows shortcuts: Win+1–5 normally opens pinned taskbar apps,
Ctrl+Win+←/→ normally switches desktops, and Game Bar or snapping uses some Win+Alt
combinations.

## Primary-monitor-only desktops

Windows virtual desktops always cover every monitor. To make desktop switches affect only
the primary monitor, the script pins every window on a non-primary monitor to all desktops
(checking twice a second). If you move a window it pinned to the primary monitor, it gets
unpinned. Windows you pinned yourself are never unpinned, and closing the script unpins
everything it pinned.

## Troubleshooting

- **"VirtualDesktopAccessor failed to load" notification:** a Windows update probably
  changed the undocumented virtual desktop API. Check the project's releases for one that
  supports your build, then run `install.ps1 -UpdateDll`. Until then, Win+1–5 still works,
  but it switches every monitor and moves through each desktop in between.
- **A window won't move or pin:** windows running as administrator, such as Task Manager
  or an elevated terminal, can't be controlled by a non-elevated script.

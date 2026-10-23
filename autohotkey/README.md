# Spectacle for Windows (AutoHotkey)

`Spectacle.ahk` is an AutoHotkey v2 script that recreates the Mac app Spectacle's window
keybindings. It also switches virtual desktops with Win+1–5, and those switches only
affect the primary monitor.

## Setup on a fresh Windows install

Requires Windows 11 and `winget`, which comes with Windows 11.

1. Clone this repo.
2. From the repo root, in an **administrator** PowerShell, run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\autohotkey\install.ps1
   ```
   The script:
   - installs AutoHotkey v2 with winget
   - downloads the latest
     [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor) DLL into
     `autohotkey\VirtualDesktopAccessor\` (git-ignored)
   - registers a Task Scheduler task (`Spectacle`) that starts the script as administrator at
     login with no UAC prompt, so its hotkeys also work in administrator windows such as
     elevated terminals
   - starts the script

   You can safely run it again; it closes the running copy and starts it again.

The scheduled task points at the script in this repo. To change something, edit
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

## Per-monitor wallpapers

When more than one virtual desktop exists, Windows 11's Settings app only offers a wallpaper
per desktop, which applies to every monitor. Use the tray icon's **Set wallpaper for
monitor N...** items instead. They set a wallpaper for one monitor on every desktop.

If a desktop picks up its own wallpaper again, for example after you use "Set for desktop N"
in Settings, switch to that desktop and use the tray menu once to clear it.

## Troubleshooting

- **"VirtualDesktopAccessor failed to load" notification:** a Windows update probably
  changed the undocumented virtual desktop API. Check the project's releases for one that
  supports your build, then run `install.ps1 -UpdateDll`. Until then, Win+1–5 still works,
  but it switches every monitor and moves through each desktop in between.
- **Hotkeys don't work in administrator windows:** the script must run as administrator,
  which the `Spectacle` scheduled task does. If you started it some other way, such as by
  double-clicking the file, exit it from the tray and run `Start-ScheduledTask Spectacle`.

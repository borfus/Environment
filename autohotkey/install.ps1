# Sets up Spectacle.ahk: installs AutoHotkey v2, downloads VirtualDesktopAccessor.dll,
# adds a Startup shortcut, and (re)starts the script. Safe to re-run.
#
#   powershell -ExecutionPolicy Bypass -File .\install.ps1            # set up / restart
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -UpdateDll # also re-download the latest DLL
param([switch]$UpdateDll)

$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'Spectacle.ahk'
$exe = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
$dll = Join-Path $PSScriptRoot 'VirtualDesktopAccessor\VirtualDesktopAccessor.dll'

# 1. AutoHotkey v2
if (-not (Test-Path $exe)) {
    Write-Host 'Installing AutoHotkey v2...'
    winget install --id AutoHotkey.AutoHotkey -e --accept-source-agreements --accept-package-agreements
    if (-not (Test-Path $exe)) { throw "AutoHotkey not found at $exe after install." }
}

# 2. Close any running copy gracefully (WM_CLOSE runs its OnExit, which unpins windows
#    and releases the DLL so it can be replaced).
$closer = Join-Path $env:TEMP 'close-spectacle.ahk'
'DetectHiddenWindows true
for hwnd in WinGetList("ahk_class AutoHotkey")
    if InStr(WinGetTitle(hwnd), "Spectacle.ahk") && WinGetPID(hwnd) != ProcessExist()
        WinClose hwnd' | Set-Content $closer
Start-Process $exe -ArgumentList "`"$closer`"" -Wait
Remove-Item $closer
Start-Sleep -Seconds 1

# 3. VirtualDesktopAccessor.dll (Windows 11 only; each release targets specific builds)
if ($UpdateDll -or -not (Test-Path $dll)) {
    $release = Invoke-RestMethod 'https://api.github.com/repos/Ciantic/VirtualDesktopAccessor/releases/latest'
    $asset = $release.assets | Where-Object name -eq 'VirtualDesktopAccessor.dll'
    New-Item -ItemType Directory -Force (Split-Path $dll) | Out-Null
    Invoke-WebRequest $asset.browser_download_url -OutFile $dll -UseBasicParsing
    Write-Host "Downloaded VirtualDesktopAccessor $($release.tag_name): $($release.name)"
}

# 4. Run at login
$lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Spectacle.lnk"
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$shortcut.TargetPath = $exe
$shortcut.Arguments = "`"$script`""
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Save()

# 5. Start it
Start-Process $exe -ArgumentList "`"$script`""
Write-Host "Spectacle.ahk is running and will start at login ($lnk)."

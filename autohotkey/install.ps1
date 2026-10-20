param([switch]$UpdateDll)

$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'Spectacle.ahk'
$exe = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
$dll = Join-Path $PSScriptRoot 'VirtualDesktopAccessor\VirtualDesktopAccessor.dll'

if (-not (Test-Path $exe)) {
    Write-Host 'Installing AutoHotkey v2...'
    winget install --id AutoHotkey.AutoHotkey -e --accept-source-agreements --accept-package-agreements
    if (-not (Test-Path $exe)) { throw "AutoHotkey not found at $exe after install." }
}

$closer = Join-Path $env:TEMP 'close-spectacle.ahk'
'DetectHiddenWindows true
for hwnd in WinGetList("ahk_class AutoHotkey")
    if InStr(WinGetTitle(hwnd), "Spectacle.ahk") && WinGetPID(hwnd) != ProcessExist()
        WinClose hwnd' | Set-Content $closer
Start-Process $exe -ArgumentList "`"$closer`"" -Wait
Remove-Item $closer
Start-Sleep -Seconds 1

if ($UpdateDll -or -not (Test-Path $dll)) {
    $release = Invoke-RestMethod 'https://api.github.com/repos/Ciantic/VirtualDesktopAccessor/releases/latest'
    $asset = $release.assets | Where-Object name -eq 'VirtualDesktopAccessor.dll'
    New-Item -ItemType Directory -Force (Split-Path $dll) | Out-Null
    Invoke-WebRequest $asset.browser_download_url -OutFile $dll -UseBasicParsing
    Write-Host "Downloaded VirtualDesktopAccessor $($release.tag_name): $($release.name)"
}

$lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Spectacle.lnk"
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$shortcut.TargetPath = $exe
$shortcut.Arguments = "`"$script`""
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Save()

Start-Process $exe -ArgumentList "`"$script`""
Write-Host "Spectacle.ahk is running and will start at login ($lnk)."

param([switch]$UpdateDll)

$ErrorActionPreference = 'Stop'
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Run this from an administrator PowerShell so the script can control elevated windows.' }

$script = Join-Path $PSScriptRoot 'Spectacle.ahk'
$exe = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
$dll = Join-Path $PSScriptRoot 'VirtualDesktopAccessor\VirtualDesktopAccessor.dll'
$taskName = 'Spectacle'

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

$oldShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Spectacle.lnk"
if (Test-Path $oldShortcut) { Remove-Item $oldShortcut }

$user = "$env:USERDOMAIN\$env:USERNAME"
$action = New-ScheduledTaskAction -Execute $exe -Argument "`"$script`"" -WorkingDirectory $PSScriptRoot
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

Start-ScheduledTask -TaskName $taskName
Write-Host "Spectacle.ahk is running as administrator and will start at login (Task Scheduler: $taskName)."

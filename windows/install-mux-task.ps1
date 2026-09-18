$ErrorActionPreference = "Stop"

$MuxExe = "C:\sfrp\sakuramux_moonlight_windows_amd64.exe"
$Config = "C:\sfrp\moonlight-server.json"
$StartBat = "C:\sfrp\moonlight-mux-start.bat"
$TaskName = "Moonlight MUX Server"

if (-not (Test-Path $MuxExe)) { throw "MUX binary not found: $MuxExe" }
if (-not (Test-Path $Config)) { throw "Config not found: $Config" }
if (-not (Test-Path $StartBat)) { throw "Start script not found: $StartBat" }

$action = New-ScheduledTaskAction -Execute $StartBat -WorkingDirectory "C:\sfrp"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -StartWhenAvailable

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
Write-Host "Installed: $TaskName"

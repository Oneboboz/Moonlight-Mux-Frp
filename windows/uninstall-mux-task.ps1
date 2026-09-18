$ErrorActionPreference = "Stop"
Unregister-ScheduledTask -TaskName "Moonlight MUX Server" -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "Removed: Moonlight MUX Server"

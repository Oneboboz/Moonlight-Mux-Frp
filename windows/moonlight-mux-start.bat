@echo off
cd /d C:\sfrp

:START
echo [%date% %time%] Starting Moonlight MUX Server...
C:\sfrp\sakuramux_moonlight_windows_amd64.exe -config C:\sfrp\moonlight-server.json -debug >> C:\sfrp\moonlight-mux.log 2>&1
echo [%date% %time%] MUX exited. Restarting in 5 seconds...
timeout /t 5 /nobreak >nul
goto START

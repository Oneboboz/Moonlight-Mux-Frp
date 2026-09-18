# Troubleshooting

## Windows

### Port 23456 is already in use

~~~powershell
netstat -ano | findstr ":23456"
Get-Process -Id <PID>
~~~

Normally only one MUX Server instance should listen on 23456.

### Wrong BasePort

A correct server configuration should result in BasePort=47989 and mapping hash 555e500db7eb882a72ecdf4827f9d9ac.

Do not put "port": 23456 in the server JSON.

### UTF-8 BOM

Older MUX builds may reject JSON with a BOM. Save configuration as UTF-8 without BOM.

## Android

If MUX reports lookup <host> on [::1]:53 but ping/curl resolves normally, resolve the hostname to IPv4 first and use that address for MUX.

## Connectivity test

~~~bash
curl -v --connect-timeout 5 http://127.0.0.1:47989/
~~~

HTTP 200 from Sunshine proves the MUX/FRP/Sunshine path is reachable. A Sunshine XML status_code=404 in this probe is not by itself a failure.

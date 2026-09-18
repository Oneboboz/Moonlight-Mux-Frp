# Moonlight MUX over SakuraFrp

A reusable setup for accessing a Windows PC running Sunshine from Moonlight over the Internet using SakuraFrp/FRP and sakuramux_moonlight.

## Architecture

~~~text
Moonlight (Android)
        |
        | 127.0.0.1
        v
sakuramux_moonlight Client
        |
        | Internet
        v
SakuraFrp / FRP TCP tunnel
        |
        v
sakuramux_moonlight Server :23456
        |
        v
Sunshine
~~~

The MUX layer combines the TCP/UDP ports required by Moonlight/Sunshine into a single FRP TCP tunnel.

## Port model

Moonlight/Sunshine base port remains 47989. The MUX server listens on 23456 and FRP forwards one TCP endpoint to it.

TCP: 47984, 47989, 48010  
UDP: 47998, 47999, 48000, 48002, 48010

Do not set the MUX BasePort to 23456.

## Windows server

1. Install and configure Sunshine.
2. Download sakuramux_moonlight_windows_amd64.exe from the official SakuraFrp MUX distribution.
3. Copy windows/moonlight-server.example.json to moonlight-server.json and set a private key.
4. Configure one SakuraFrp TCP tunnel to 127.0.0.1:23456.
5. Start:

~~~powershell
C:\sfrp\sakuramux_moonlight_windows_amd64.exe -config C:\sfrp\moonlight-server.json -debug
~~~

Expected:

~~~text
BasePort=47989
mapping hash: 555e500db7eb882a72ecdf4827f9d9ac
mux server listening on 0.0.0.0:23456
~~~

Run PowerShell as Administrator to install the Task Scheduler auto-start helper.

## Android / Termux client

1. Install Termux and Termux:Boot.
2. Download the ARM64 MUX binary.
3. Put it in ~/moonlight-mux/.
4. Configure the public FRP endpoint and shared key.
5. Start the MUX client.
6. Add 127.0.0.1 in Moonlight.

If the Go resolver tries [::1]:53 while normal Termux DNS works, resolve the public hostname to IPv4 first and pass the IPv4 address to MUX.

## Security

Never commit real keys, tunnel credentials, tokens, private addresses, or logs. Use the example configuration files.

## Troubleshooting

### invalid character 'ï'

The JSON was saved with a UTF-8 BOM. Save it as UTF-8 without BOM.

### Port 23456 already in use

Check:

~~~powershell
netstat -ano | findstr ":23456"
Get-Process -Id <PID>
~~~

Only one MUX server should listen on 23456.

### Wrong BasePort

The correct server configuration produces BasePort=47989. Do not add "port": 23456 to the server JSON.

### Android [::1]:53

If ping/curl resolves the hostname but MUX does not, resolve it to IPv4 before launching MUX.

## References

- SakuraFrp Moonlight discussion: https://github.com/natfrp/wiki/discussions/661
- SakuraFrp MUX 1.0.1: https://nya.globalslb.net/natfrp/client/mux/moonlight/1.0.1/
- Termux:Boot: https://github.com/termux/termux-boot
- Sunshine: https://github.com/LizardByte/Sunshine

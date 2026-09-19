# Moonlight MUX over SakuraFrp

A reusable deployment template for Moonlight + Sunshine over the Internet using SakuraFrp/FRP and the official `sakuramux_moonlight` 1.0.1 multiplexer.

> **Important:** This repository contains templates and scripts, not your private SakuraFrp credentials. Never commit a real key, tunnel token, private endpoint, or log containing credentials.

## What this solves

Moonlight/Sunshine use several fixed TCP and UDP ports. A normal single FRP port forward is therefore not enough for a reliable remote setup. The MUX creates one TCP entry point for FRP and reconstructs the Moonlight port set on the client side.

## Architecture

~~~text
Android Moonlight
       |
       | 127.0.0.1
       v
sakuramux_moonlight Client
       |
       | one TCP FRP connection
       v
SakuraFrp / FRP
       |
       | PUBLIC_HOST:PUBLIC_PORT
       v
Windows MUX Server :23456
       |
       +---- Sunshine TCP 47984
       +---- Sunshine TCP 47989
       +---- Sunshine TCP 48010
       +---- Sunshine UDP 47998
       +---- Sunshine UDP 47999
       +---- Sunshine UDP 48000
       +---- Sunshine UDP 48002
       +---- Sunshine UDP 48010
~~~

## Requirements

### Windows host

- Windows PC running Sunshine
- SakuraFrp/FRP client already working
- `sakuramux_moonlight_windows_amd64.exe`
- Administrator access for Task Scheduler auto-start

### Android client

- Android device
- Termux
- Termux:Boot for boot auto-start
- ARM64 MUX binary: `sakuramux_moonlight_linux_arm64`
- Moonlight Android

## Official downloads / references

- urlSakuraFrp Moonlight discussion #661https://github.com/natfrp/wiki/discussions/661
- urlSakuraFrp MUX 1.0.1 distributionhttps://nya.globalslb.net/natfrp/client/mux/moonlight/1.0.1/
- urlTermux:Boothttps://github.com/termux/termux-boot
- urlSunshinehttps://github.com/LizardByte/Sunshine

## 1. Windows setup

Assume this directory:

~~~text
C:\sfrp\
├── sakuramux_moonlight_windows_amd64.exe
├── moonlight-server.json
└── moonlight-mux-start.bat
~~~

### MUX server configuration

Start from:

~~~text
windows/moonlight-server.example.json
~~~

The important configuration is:

~~~json
{
    "mode": "server",
    "key": "CHANGE_ME",
    "server": "127.0.0.1:23456"
}
~~~

Use a strong private key shared only with your Android client.

**Do not add**:

~~~json
"port": 23456
~~~

For MUX 1.0.1, the Moonlight base port must remain **47989**. Port **23456** is the MUX server entry point, not the Moonlight base port.

### SakuraFrp tunnel

Create one TCP tunnel:

~~~text
Public: PUBLIC_HOST:PUBLIC_PORT
Local:  127.0.0.1:23456
Protocol: TCP
~~~

Example:

~~~text
frp.example.com:61920 -> 127.0.0.1:23456
~~~

Use your own endpoint; the example is not a required address.

### Test MUX manually

~~~powershell
cd C:\sfrp
.\sakuramux_moonlight_windows_amd64.exe -config C:\sfrp\moonlight-server.json -debug
~~~

A correct startup includes:

~~~text
BasePort=47989
mapping hash: 555e500db7eb882a72ecdf4827f9d9ac
mux server listening on 0.0.0.0:23456
~~~

The exact mapping hash is useful for troubleshooting this MUX 1.0.1 build.

### Windows auto-start

Run PowerShell **as Administrator** and use:

~~~powershell
.\install-mux-task.ps1
~~~

The helper installs a SYSTEM Task Scheduler task named:

~~~text
Moonlight MUX Server
~~~

The included BAT restarts MUX five seconds after an unexpected exit.

To remove it:

~~~powershell
.\uninstall-mux-task.ps1
~~~

### Check port ownership

~~~powershell
netstat -ano | findstr ":23456"
Get-Process -Id <PID>
~~~

Only one MUX server instance should listen on 23456.

## 2. Android / Termux setup

Create:

~~~bash
mkdir -p ~/moonlight-mux/logs
~~~

Download the official ARM64 binary into:

~~~text
~/moonlight-mux/sakuramux_moonlight_linux_arm64
~~~

Make it executable:

~~~bash
chmod +x ~/moonlight-mux/sakuramux_moonlight_linux_arm64
~~~

### Basic client

Copy:

~~~text
android/mux-client.example.sh
~~~

and replace:

~~~text
CHANGE_ME
PUBLIC_HOST:PUBLIC_PORT
~~~

Then:

~~~bash
chmod +x ~/moonlight-mux/mux-client.sh
~/moonlight-mux/mux-client.sh
~~~

Moonlight should then use:

~~~text
127.0.0.1
~~~

### Android DNS quirk

On some Android/Termux environments, this MUX build can attempt DNS through:

~~~text
[::1]:53
~~~

even when normal Termux tools can resolve the hostname successfully.

If this happens, the practical workaround is to resolve the public hostname to an IPv4 address before launching MUX and pass that IPv4 address to `-server`. The local Android MUX ports remain unchanged.

The production `mux.sh` used by this project can implement that workaround, cache the last successful IPv4 address, and provide start/stop/status handling.

## 3. Termux:Boot auto-start

Copy:

~~~text
android/termux-boot/start-moonlight-mux
~~~

to:

~~~text
~/.termux/boot/start-moonlight-mux
~~~

then:

~~~bash
chmod +x ~/.termux/boot/start-moonlight-mux
~~~

Open Termux:Boot once after installing it, then reboot Android to test.

The boot script waits for networking, acquires a wake lock when available, and starts the local MUX manager.

## 4. Testing

After MUX Client starts:

~~~bash
curl -v --connect-timeout 5 http://127.0.0.1:47989/
~~~

A successful path can return:

~~~text
HTTP/1.1 200 OK
~~~

and Sunshine may return:

~~~xml
<root status_code="404"/>
~~~

That **404 is not a failure of the transport test**. The important result is that the request reached the Sunshine HTTP service through the MUX/FRP path.

Then add:

~~~text
127.0.0.1
~~~

to Moonlight.

## 5. Multiple gaming PCs

Each Windows PC can use its own FRP public TCP port:

~~~text
PC-A: PUBLIC_HOST:61920 -> 127.0.0.1:23456
PC-B: PUBLIC_HOST:61921 -> 127.0.0.1:23456
PC-C: PUBLIC_HOST:61922 -> 127.0.0.1:23456
~~~

The MUX Server can therefore use the same local 23456 on every separate PC. The public endpoint is what distinguishes them.

On one Android device, use separate local MUX client instances / local port sets if you want several PCs available simultaneously. Do not start two clients that try to bind the same Moonlight ports.

## 6. nxapi / s3s authentication workaround

If you are using `space4y/nxapi-s3s:0.7.0`, **do not keep retrying its built-in Nintendo authentication step** if it fails with:

~~~text
Remote configuration prevents Coral authentication
~~~

The old image expects `nxapi nso auth` to print a `session_token:` line. Current nxapi no longer exposes the token that way; it stores the Nintendo Account session token in persistent storage.

The tested workaround is:

1. Authenticate with current nxapi.
2. Verify the account with `nso user`.
3. Generate the s3s configuration with `util update-s3s-token`.
4. Copy `/data/config.txt` into the old image's `/s3s/config.txt`.
5. Run the old image's `s3s.py --getseed` directly, bypassing its obsolete entrypoint.

Detailed commands and security notes are in:

~~~text
docs/NXAPI-S3S-Auth.md
~~~

**Never commit `config.txt`, session tokens, gtoken, bulletToken, JWTs, or authentication logs.**

## Security

- Do not commit real MUX keys.
- Do not commit SakuraFrp tokens.
- Do not commit private tunnel endpoints if they identify your network.
- Do not commit `*.log` files containing credentials.
- Use the example configuration files as templates.
- Prefer a long random key rather than the demonstration key used in documentation.

## Troubleshooting

### JSON: invalid character 'ï'

The file likely contains a UTF-8 BOM. Save the JSON as UTF-8 **without BOM**.

### 23456 already in use

Another MUX Server instance is running:

~~~powershell
netstat -ano | findstr ":23456"
Get-Process -Id <PID>
~~~

Do not start a second instance.

### BasePort became 23456

Remove `"port": 23456` and `"local": "127.0.0.1"` from the old configuration and use the minimal server configuration shown above.

### Android reports lookup through [::1]:53

Test normal resolution:

~~~bash
ping -c 1 PUBLIC_HOST
curl -v --connect-timeout 5 telnet://PUBLIC_HOST:PUBLIC_PORT
~~~

If those work but MUX does not, use the resolved IPv4 address for MUX.

### Moonlight cannot connect

Check in this order:

1. Sunshine is running.
2. Windows MUX is listening on 23456.
3. SakuraFrp forwards TCP to 127.0.0.1:23456.
4. Android MUX Client is running.
5. Android local ports 47984/47989/48010 and required UDP ports are available.
6. Moonlight is pointed at 127.0.0.1.

## Project status

This repository documents a setup that has been tested end-to-end with:

- Windows + Sunshine
- SakuraFrp TCP tunnel
- sakuramux_moonlight 1.0.1
- Android + Termux
- Moonlight connecting to 127.0.0.1

The scripts are intended as deployment templates and should be adapted to the local paths and FRP configuration of each machine.

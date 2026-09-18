# Android / Termux

Run `install.sh` after obtaining this repository in Termux.

~~~bash
cd android
chmod +x install.sh
./install.sh
~~~

The installer asks for the SakuraFrp public host, public TCP port, and MUX key. It downloads the official 1.0.1 ARM64 MUX binary, creates a protected `~/moonlight-mux/mux.env`, installs the manager, and installs the Termux:Boot script.

Commands:

~~~bash
~/moonlight-mux/mux.sh start
~/moonlight-mux/mux.sh stop
~/moonlight-mux/mux.sh restart
~/moonlight-mux/mux.sh status
~/moonlight-mux/mux.sh logs
~~~

Moonlight connects to `127.0.0.1`.

The manager resolves the public hostname to IPv4 before starting MUX and caches the last successful IPv4 in `~/moonlight-mux/server.ip`. This works around the observed MUX/Go resolver issue where it attempted `[::1]:53`.

For automatic startup, install Termux:Boot, open it once, then reboot Android. Depending on the Android vendor, exclude Termux and Termux:Boot from battery optimization.

Never commit `mux.env`, logs, or private tunnel credentials.

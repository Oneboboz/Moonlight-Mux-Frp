# Windows 一键部署

本目录用于在运行 Sunshine 的 Windows PC 上部署 sakuramux_moonlight Server，并设置开机自动启动。

## 目录

建议把整个项目放到：

~~~text
C:\Moonlight-Mux-Frp
~~~

同时把官方 MUX 程序放到：

~~~text
C:\sfrp\sakuramux_moonlight_windows_amd64.exe
~~~

如果你的 SakuraFrp 已经使用其他目录，不需要移动它；MUX 只需要能够连接本机的 23456 端口。

## 一、准备 Sunshine

先确认 Sunshine 正常运行。

默认需要的 Moonlight/Sunshine 端口：

~~~text
TCP 47984
TCP 47989
TCP 48010

UDP 47998
UDP 47999
UDP 48000
UDP 48002
UDP 48010
~~~

## 二、下载 MUX

从官方 SakuraFrp MUX 1.0.1 分发目录下载：

~~~text
sakuramux_moonlight_windows_amd64.exe
~~~

放到：

~~~text
C:\sfrp\
~~~

官方地址：

~~~text
https://nya.globalslb.net/natfrp/client/mux/moonlight/1.0.1/
~~~

## 三、创建 MUX 配置

复制：

~~~text
windows\moonlight-server.example.json
~~~

为：

~~~text
C:\sfrp\moonlight-server.json
~~~

内容：

~~~json
{
    "mode": "server",
    "key": "CHANGE_ME",
    "server": "127.0.0.1:23456"
}
~~~

把 `CHANGE_ME` 换成你的随机密钥。

### 非常重要

不要写：

~~~json
"port": 23456
~~~

23456 是 MUX Server 的监听入口，不是 MUX BasePort。

MUX 1.0.1 的 Moonlight BasePort 应保持 47989。

## 四、创建 SakuraFrp TCP 隧道

只需要一个 TCP 隧道：

~~~text
公网：PUBLIC_HOST:PUBLIC_PORT
本地：127.0.0.1:23456
协议：TCP
~~~

例如：

~~~text
frp.example.com:61920
        ↓
127.0.0.1:23456
~~~

不要直接把 SakuraFrp 隧道指向 47989。

## 五、第一次手动测试

打开 PowerShell：

~~~powershell
cd C:\sfrp
.\sakuramux_moonlight_windows_amd64.exe -config C:\sfrp\moonlight-server.json -debug
~~~

正常情况下应该看到：

~~~text
BasePort=47989
mux server listening on 0.0.0.0:23456
~~~

确认没有报错后按 Ctrl+C 停止。

## 六、一键安装开机启动

### 方法 A：推荐

用**管理员 PowerShell**进入项目目录：

~~~powershell
cd C:\Moonlight-Mux-Frp\windows
Set-ExecutionPolicy -Scope Process Bypass
.\install-mux-task.ps1
~~~

脚本会创建：

~~~text
Moonlight MUX Server
~~~

计划任务。

运行身份：

~~~text
SYSTEM
~~~

触发方式：

~~~text
AtStartup
~~~

权限：

~~~text
Highest
~~~

MUX 意外退出后，BAT 启动器会等待 5 秒并自动重新启动。

## 七、检查计划任务

管理员 PowerShell：

~~~powershell
Get-ScheduledTask -TaskName "Moonlight MUX Server" |
  Select-Object TaskName,State
~~~

应该看到：

~~~text
TaskName                State
--------                -----
Moonlight MUX Server    Running
~~~

也可以：

~~~powershell
Get-Process sakuramux_moonlight_windows_amd64 -ErrorAction SilentlyContinue
~~~

检查 23456：

~~~powershell
netstat -ano | findstr ":23456"
~~~

## 八、重启测试

这是最重要的一步。

重启 Windows：

~~~powershell
shutdown /r /t 0
~~~

重新进入系统后检查：

~~~powershell
Get-Process sakuramux_moonlight_windows_amd64 -ErrorAction SilentlyContinue
netstat -ano | findstr ":23456"
~~~

然后确认 SakuraFrp 隧道也已经启动。

## 九、Android 端

Android 端可以直接使用仓库根目录的：

~~~text
install-all.sh
~~~

或者进入：

~~~text
android\
~~~

运行：

~~~bash
./install.sh
~~~

安装完成后：

~~~bash
~/moonlight-mux/mux.sh status
~~~

启动：

~~~bash
~/moonlight-mux/mux.sh start
~~~

Moonlight 添加：

~~~text
127.0.0.1
~~~

## 十、完整启动链

Windows：

~~~text
Windows 开机
   ↓
Sunshine
   ↓
SakuraFrp
   ↓
TCP 公网端口
   ↓
127.0.0.1:23456
   ↓
MUX Server
~~~

Android：

~~~text
Android 开机
   ↓
Termux:Boot
   ↓
mux.sh
   ↓
MUX Client
   ↓
127.0.0.1
   ↓
Moonlight
~~~

## 十一、Windows 常见问题

### 23456 已被占用

~~~powershell
netstat -ano | findstr ":23456"
Get-Process -Id <PID>
~~~

通常是已经运行了一个 MUX Server。

不要启动第二个。

### JSON 报 invalid character 'ï'

JSON 使用了 UTF-8 BOM。

请保存成 UTF-8 **无 BOM**。

### MUX 显示 BasePort=23456

配置文件里错误加入了：

~~~json
"port": 23456
~~~

删除它。

### 计划任务拒绝访问

PowerShell 没有使用管理员权限。

重新打开：

~~~text
Windows PowerShell → 右键 → 以管理员身份运行
~~~

### Windows 重启后没有 MUX

检查：

~~~powershell
Get-ScheduledTask -TaskName "Moonlight MUX Server"
Get-ScheduledTaskInfo -TaskName "Moonlight MUX Server"
~~~

然后查看：

~~~text
C:\sfrp\moonlight-mux.log
~~~

## 十二、卸载

管理员 PowerShell：

~~~powershell
cd C:\Moonlight-Mux-Frp\windows
.\uninstall-mux-task.ps1
~~~

这只删除自动启动任务，不会删除 Sunshine、SakuraFrp 或 MUX 程序。

## 安全注意

不要把以下内容提交到 GitHub：

- 真实 MUX Key
- SakuraFrp Token
- 私人公网地址
- 运行日志
- 包含认证信息的配置文件

仓库提供的 `moonlight-server.example.json` 只用于模板。

# Debian 13 安装与基础配置指南

> 适用场景：家用服务器、小主机、Docker 宿主机。示例默认使用 **Debian 13 (Trixie)**、有线网卡、静态 IPv4。
>
> 文中的 IP、网关、DNS、网卡名均为示例，实际操作时请替换成自己的值。

---

## 1. 安装前准备

### 1.1 下载 Debian 13 镜像

建议使用 Debian 13 的 **amd64 netinst** 镜像。

制作启动 U 盘可使用：

- Windows：Rufus、Ventoy
- macOS：balenaEtcher、Ventoy
- Linux：Ventoy 或 `dd`

服务器通常不需要桌面环境，安装纯命令行系统即可。

### 1.2 BIOS / UEFI 建议

进入 BIOS 后建议确认：

- 使用 UEFI 启动（老机器不支持也可以使用 Legacy）
- SATA 模式使用 AHCI
- 如需要断电自动恢复，开启 **Restore on AC Power Loss / Power On after Power Failure**
- 如果机器长期作为服务器，可按需开启 Wake-on-LAN
- 将安装 U 盘设置为临时第一启动项

---

# 2. 安装 Debian 13

从 U 盘启动后，推荐选择：

```text
Install
```

或者：

```text
Graphical install
```

两者安装出来的系统没有本质区别。

## 2.1 语言与地区

可以按照个人习惯选择。

服务器建议：

```text
Language: English
Location: other / Asia / China
Locale: en_US.UTF-8
```

使用英文系统的好处是遇到报错时更方便搜索。

时区后续设置为：

```text
Asia/Shanghai
```

## 2.2 网络配置

安装阶段如果 DHCP 可以正常获取地址，可以暂时直接使用 DHCP。

系统安装完成后再配置静态 IP，通常更加方便。

Hostname 可以按照机器用途命名，例如：

```text
debian

docker-208

backup-208
```

Domain name 没有特殊需求可以留空。

## 2.3 用户和密码

可以设置 root 密码，也可以让普通用户通过 sudo 管理系统。

家用服务器如果习惯直接使用 root 管理，可以设置 root 密码。

同时建议创建一个普通用户作为日常 SSH 登录账户。

## 2.4 磁盘分区

如果整块硬盘只用于 Debian，推荐：

```text
Guided - use entire disk
```

分区方式选择：

```text
All files in one partition
```

对于 Docker 宿主机，这种方式最简单，也方便管理磁盘空间。

确认后选择：

```text
Finish partitioning and write changes to disk
```

## 2.5 软件选择

到 **Software selection** 页面时，服务器建议只保留：

```text
SSH server
standard system utilities
```

取消：

```text
Debian desktop environment
GNOME
Xfce
KDE Plasma
...
```

即安装纯命令行 Debian。

## 2.6 GRUB

正常安装 GRUB 到系统磁盘即可。

安装完成后拔掉 U 盘并重启。

---

# 3. 第一次进入系统

登录后先确认系统版本：

```bash
cat /etc/os-release
```

确认主机名：

```bash
hostnamectl
```

查看 IP：

```bash
ip addr
```

查看默认路由：

```bash
ip route
```

---

# 4. 修改主机名

例如将机器命名为：

```text
docker-208
```

执行：

```bash
hostnamectl set-hostname docker-208
```

然后编辑：

```bash
nano /etc/hosts
```

建议包含：

```text
127.0.0.1       localhost
127.0.1.1       docker-208
```

检查：

```bash
hostnamectl
```

---

# 5. 配置时区

查看当前时区：

```bash
timedatectl
```

设置中国时区：

```bash
timedatectl set-timezone Asia/Shanghai
```

再次确认：

```bash
timedatectl
```

---

# 6. 更新系统

先更新软件索引：

```bash
apt update
```

升级已安装的软件包：

```bash
apt full-upgrade -y
```

安装常用工具：

```bash
apt install -y \
  sudo \
  curl \
  wget \
  vim \
  nano \
  git \
  htop \
  unzip \
  zip \
  tar \
  rsync \
  ca-certificates \
  gnupg \
  lsb-release \
  openssh-server \
  net-tools \
  dnsutils \
  iputils-ping \
  traceroute \
  ncdu \
  smartmontools
```

---

# 7. 配置静态 IP、网关和 DNS

Debian 的网络配置方式取决于安装方式和当前网络管理组件。

服务器环境推荐先检查：

```bash
ls /etc/network/interfaces
systemctl is-active NetworkManager
systemctl is-active systemd-networkd
```

纯命令行 Debian 通常可以直接使用 `/etc/network/interfaces`。

## 7.1 查找网卡名称

执行：

```bash
ip link
```

常见网卡名例如：

```text
enp1s0
ens18
eth0
```

假设本机网卡为：

```text
enp1s0
```

计划配置：

```text
IP:      192.168.16.208
掩码:    255.255.255.0 (/24)
网关:    192.168.16.1
DNS 1:   192.168.16.1
DNS 2:   223.5.5.5
```

## 7.2 使用 /etc/network/interfaces 配置

编辑：

```bash
nano /etc/network/interfaces
```

配置示例：

```text
auto lo
iface lo inet loopback

auto enp1s0
iface enp1s0 inet static
    address 192.168.16.208/24
    gateway 192.168.16.1
    dns-nameservers 192.168.16.1 223.5.5.5
```

保存后重启网络：

```bash
systemctl restart networking
```

先看看有没有 resolvconf：

dpkg -l | grep resolvconf

如果没有输出，安装：

apt update
apt install resolvconf

然后启用：

systemctl enable --now resolvconf

重新应用网卡配置，最稳妥其实直接重启：

reboot

起来后检查：

cat /etc/resolv.conf

> **注意：** 如果当前是通过 SSH 修改远程机器的 IP/网关，重启网络后 SSH 很可能立即断开。最好在机器本地操作，或者确保新 IP 可以访问。

如果网络服务重启异常，直接重启机器：

```bash
reboot
```

## 7.3 检查 IP

```bash
ip addr show enp1s0
```

## 7.4 检查默认网关

```bash
ip route
```

正常应该看到类似：

```text
default via 192.168.16.1 dev enp1s0
192.168.16.0/24 dev enp1s0 proto kernel scope link src 192.168.16.208
```

## 7.5 检查 DNS

```bash
cat /etc/resolv.conf
```

测试域名解析：

```bash
getent hosts deb.debian.org
```

或者：

```bash
nslookup deb.debian.org
```

## 7.6 网络连通性测试

先测试网关：

```bash
ping -c 4 192.168.16.1
```

再测试公网 IP：

```bash
ping -c 4 1.1.1.1
```

最后测试 DNS：

```bash
ping -c 4 deb.debian.org
```

判断方法：

- 网关不通：检查 IP、网线、VLAN、网卡配置
- 网关通但 `1.1.1.1` 不通：检查网关/路由
- `1.1.1.1` 通但域名不通：重点检查 DNS

---

# 8. 临时修改 IP / 网关（排障用）

以下命令重启后会失效，只建议用于排障。

添加 IP：

```bash
ip addr add 192.168.16.208/24 dev enp1s0
```

删除 IP：

```bash
ip addr del 192.168.16.208/24 dev enp1s0
```

修改默认网关：

```bash
ip route replace default via 192.168.16.1 dev enp1s0
```

查看路由：

```bash
ip route
```

---

# 9. SSH 配置

确认 SSH 服务：

```bash
systemctl status ssh
```

如果没有启动：

```bash
systemctl enable --now ssh
```

查看 SSH 监听端口：

```bash
ss -lntp | grep ssh
```

默认端口为：

```text
22
```

## 9.1 是否允许 root SSH 登录

编辑：

```bash
nano /etc/ssh/sshd_config
```

如果确实需要 root 使用密码直接 SSH，可以设置：

```text
PermitRootLogin yes
PasswordAuthentication yes
```

然后：

```bash
systemctl restart ssh
```

> 从安全角度，更推荐使用普通用户 + sudo，并使用 SSH Key 登录，而不是长期开放 root 密码登录。

---

# 10. 配置普通用户 sudo

假设用户名为：

```text
iapyang
```

安装 sudo：

```bash
apt install -y sudo
```

加入 sudo 组：

```bash
usermod -aG sudo iapyang
```

重新登录后测试：

```bash
sudo whoami
```

应该输出：

```text
root
```

---

# 11. 安装 Docker

推荐使用 Docker 官方 APT 仓库，而不是直接安装 Debian 仓库中的旧版 `docker.io`。

## 11.1 删除可能存在的冲突软件包

```bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  apt remove -y "$pkg" 2>/dev/null || true
done
```

## 11.2 安装依赖

```bash
apt update
apt install -y ca-certificates curl
```

## 11.3 添加 Docker 官方 GPG Key

```bash
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
```

## 11.4 添加 Docker 软件源

```bash
cat > /etc/apt/sources.list.d/docker.sources <<EOF2
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF2
```

更新：

```bash
apt update
```

## 11.5 安装 Docker Engine 和 Compose

```bash
apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
```

## 11.6 启动 Docker

```bash
systemctl enable --now docker
```

查看状态：

```bash
systemctl status docker
```

## 11.7 查看版本

```bash
docker version
```

查看 Compose：

```bash
docker compose version
```

注意新版使用：

```bash
docker compose
```

而不是旧版：

```bash
docker-compose
```

## 11.8 测试 Docker

```bash
docker run --rm hello-world
```

能正常输出欢迎信息即说明 Docker 工作正常。

---

# 12. 允许普通用户执行 Docker

如果希望普通用户不加 sudo 就能执行 Docker：

```bash
usermod -aG docker iapyang
```

然后退出 SSH 并重新登录。

检查：

```bash
groups
```

确认包含：

```text
docker
```

测试：

```bash
docker ps
```

> 注意：`docker` 组实际上具有接近 root 的系统权限，只应加入可信用户。

---

# 13. 建立 Docker 数据目录

如果习惯将所有 Docker Compose 和持久化数据集中放在 `/opt/docker`：

```bash
mkdir -p /opt/docker
```

例如：

```text
/opt/docker/
├── ql/
│   ├── compose.yaml
│   └── data/
├── metube/
│   ├── compose.yaml
│   └── downloads/
├── alist/
│   ├── compose.yaml
│   └── data/
└── rustdesk/
    ├── compose.yaml
    └── data/
```

这种结构的优点是：

- Docker 配置集中
- 持久化目录清晰
- 方便统一备份 `/opt/docker`
- 重装系统后恢复更加简单

---

# 14. Docker Compose 常用命令

进入包含 `compose.yaml` 的目录后：

启动：

```bash
docker compose up -d
```

查看容器：

```bash
docker compose ps
```

查看日志：

```bash
docker compose logs -f
```

停止并删除容器：

```bash
docker compose down
```

拉取新镜像：

```bash
docker compose pull
```

升级并重新创建容器：

```bash
docker compose pull
docker compose up -d
```

清理没有被使用的旧镜像：

```bash
docker image prune -f
```

---

# 15. Docker 日志限制

长期运行 Docker 时，建议限制容器默认日志大小，防止日志无限增长占满磁盘。

创建或编辑：

```bash
nano /etc/docker/daemon.json
```

例如：

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
```

重启 Docker：

```bash
systemctl restart docker
```

> 该配置主要影响之后新建的容器。已有容器建议重新创建后再确认日志配置。

检查某个容器的日志配置：

```bash
docker inspect <容器名> --format '{{json .HostConfig.LogConfig}}'
```

---

# 16. 磁盘检查

查看磁盘：

```bash
lsblk
```

查看文件系统空间：

```bash
df -h
```

查看目录占用：

```bash
du -xhd1 /opt | sort -h
```

使用 ncdu：

```bash
ncdu /
```

查看 SATA / SSD SMART：

```bash
smartctl -a /dev/sda
```

如果 SMART 未开启：

```bash
smartctl -s on /dev/sda
```

---

# 17. 检查系统错误

查看本次启动中的严重错误：

```bash
journalctl -p err -b
```

查看内核错误：

```bash
dmesg -T | grep -Ei 'error|fail|i/o|ata|ext4|nvme'
```

尤其出现：

```text
Input/output error
I/O error
EXT4-fs error
Buffer I/O error
ata error
```

时，应优先检查硬盘、SATA 线、电源以及 SMART 信息。

---

# 18. 设置开机自动启动

Docker：

```bash
systemctl enable docker
```

SSH：

```bash
systemctl enable ssh
```

查看：

```bash
systemctl is-enabled docker
systemctl is-enabled ssh
```

Docker Compose 中长期服务建议使用：

```yaml
restart: unless-stopped
```

例如：

```yaml
services:
  app:
    image: nginx:latest
    restart: unless-stopped
```

这样机器重启后容器会自动恢复运行。

---

# 19. 系统时间同步

检查：

```bash
timedatectl
```

开启 NTP：

```bash
timedatectl set-ntp true
```

再次确认：

```bash
timedatectl
```

重点确认：

```text
System clock synchronized: yes
NTP service: active
```

---

# 20. 修改 APT 软件源（可选）

如果 Debian 官方源访问速度正常，没有必要修改。

Debian 13 推荐使用 deb822 格式的软件源文件，例如：

```bash
cat /etc/apt/sources.list.d/debian.sources
```

修改源之前建议备份：

```bash
cp /etc/apt/sources.list.d/debian.sources \
   /etc/apt/sources.list.d/debian.sources.bak
```

修改后执行：

```bash
apt update
```

确认没有报错再继续使用。

---

# 21. 防火墙（按需）

家庭内网 Docker 主机如果本身处于路由器/NAT 后，可以根据实际环境决定是否启用主机防火墙。

如果需要简单管理，可以安装 UFW：

```bash
apt install -y ufw
```

在启用之前一定先允许 SSH：

```bash
ufw allow 22/tcp
```

然后：

```bash
ufw enable
```

查看：

```bash
ufw status verbose
```

> Docker 与 UFW 的转发/端口规则存在额外注意事项。Docker 主机不要在不了解规则关系时直接套用复杂 UFW 策略。

---

# 22. 安装完成后的检查清单

建议每台新 Debian 服务器装完后依次确认：

```text
[ ] Debian 版本正确
[ ] Hostname 已修改
[ ] 时区为 Asia/Shanghai
[ ] 系统已 apt update / full-upgrade
[ ] 静态 IP 正确
[ ] 默认网关正确
[ ] DNS 解析正常
[ ] SSH 可以正常登录
[ ] 普通管理用户已创建
[ ] sudo 正常
[ ] Docker 已安装
[ ] Docker Compose 已安装
[ ] Docker 设置开机启动
[ ] Docker 日志大小已限制
[ ] /opt/docker 目录已创建
[ ] NTP 时间同步正常
[ ] 硬盘 SMART 正常
[ ] BIOS 已开启断电恢复自动开机（如需要）
[ ] 备份方案已配置
```

---

# 23. 常用排障命令速查

## 系统

```bash
hostnamectl
timedatectl
uptime
free -h
lsblk
df -h
```

## 网络

```bash
ip addr
ip route
ip link
cat /etc/resolv.conf
ping -c 4 192.168.16.1
ping -c 4 1.1.1.1
getent hosts deb.debian.org
ss -lntup
```

## 服务

```bash
systemctl --failed
systemctl status ssh
systemctl status docker
journalctl -p err -b
```

## Docker

```bash
docker ps -a
docker images
docker stats
docker system df
docker compose ps
docker compose logs -f
```

## 磁盘

```bash
df -h
du -xhd1 /opt | sort -h
smartctl -a /dev/sda
dmesg -T | grep -Ei 'error|fail|i/o|ata|ext4|nvme'
```

---

# 24. 推荐的服务器初始化顺序

以后新装一台 Debian 13 Docker 主机，可以按照下面的顺序执行：

```text
安装 Debian 13
    ↓
修改 hostname
    ↓
设置 Asia/Shanghai 时区
    ↓
配置静态 IP / 网关 / DNS
    ↓
测试网络
    ↓
apt update + full-upgrade
    ↓
安装常用工具
    ↓
配置 SSH / sudo
    ↓
安装 Docker 官方版本
    ↓
配置 Docker 日志限制
    ↓
创建 /opt/docker
    ↓
部署 Docker Compose 服务
    ↓
配置备份
    ↓
检查 SMART / journal / Docker
```

---

# 25. 一台机器装完后的最终验证

执行：

```bash
hostnamectl

timedatectl

ip addr
ip route

ping -c 2 1.1.1.1
getent hosts deb.debian.org

systemctl is-active ssh
systemctl is-active docker

docker version
docker compose version

df -h

systemctl --failed
```

如果以上项目全部正常，这台 Debian 13 Docker 宿主机的基础环境基本就配置完成了。

---

## 备注：建议纳入后续自动化的内容

如果以后要批量安装多台 Debian，可以把安装后的固定步骤做成 bootstrap 脚本，例如自动完成：

- 安装常用软件
- 设置时区
- 安装 Docker
- 创建 `/opt/docker`
- 配置 Docker `daemon.json`
- 创建备份目录
- 配置统一的备份/管理脚本

而 **IP、网关、DNS、hostname** 这类每台机器不同的参数，建议通过脚本参数或配置文件传入，不要硬编码在公共脚本中。

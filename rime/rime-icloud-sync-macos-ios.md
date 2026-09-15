# Rime（鼠须管 + 仓输入法）通过 iCloud 同步用户词库

这套方案适合：

- macOS 使用 **鼠须管（Squirrel）**
- iPhone / iPad 使用 **仓输入法（Hamster）**
- 最在意的是 Rime 自动学习出来的 `userdb`（词频、输入习惯）
- 希望通过 iCloud 在多设备之间同步
- Mac 端希望定时自动执行 Rime 用户数据同步

---

## 一、同步思路

不要直接把正在使用的 `*.userdb` 数据库放进 iCloud 实时同步。

推荐使用 Rime 自带的 **「同步用户数据」**：

```text
Mac 本地 userdb
      ↕
   iCloud sync/
      ↕
iPhone / iPad 本地 userdb
```

每台设备都有自己的本地 `userdb`。

`sync/` 是 Rime 用来交换、合并用户学习数据的中间目录。

### 建议备份的数据

最重要：

```text
sync/
```

建议顺手备份：

```text
default.custom.yaml
squirrel.custom.yaml
installation.yaml
```

通常不需要备份：

```text
build/
user.yaml
```

如果已经长期使用 `sync/` 作为恢复手段，`luna_pinyin.userdb/` 可以不作为主要备份对象。

---

# 二、Mac：配置 iCloud 同步目录

鼠须管用户目录默认是：

```bash
~/Library/Rime
```

iCloud Drive 在 macOS 上的实际路径通常是：

```bash
~/Library/Mobile Documents/com~apple~CloudDocs
```

这里使用：

```text
iCloud Drive/Rime/Sync
```

作为同步目录。

先创建目录：

```bash
mkdir -p "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Rime/Sync"
```

---

## 修改 `installation.yaml`

编辑：

```bash
nano ~/Library/Rime/installation.yaml
```

设置：

```yaml
installation_id: "mac-imac"
sync_dir: "/Users/你的用户名/Library/Mobile Documents/com~apple~CloudDocs/Rime/Sync"
```

例如用户名是 `iapyang`：

```yaml
installation_id: "mac-imac"
sync_dir: "/Users/iapyang/Library/Mobile Documents/com~apple~CloudDocs/Rime/Sync"
```

注意：

- 建议使用绝对路径
- 不要在 YAML 里使用 `~`
- 不同设备的 `installation_id` 应该不同
- Mac、iPhone、iPad 不要共用同一个 `installation_id`

---

# 三、Mac：手动同步测试

鼠须管可以直接通过命令行执行用户数据同步：

```bash
"/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel" --sync
```

执行后检查：

```text
iCloud Drive/Rime/Sync/
```

正常情况下会出现与设备 `installation_id` 对应的同步数据。

如果刚修改过 Rime 配置，也可以先重新部署：

```bash
"/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel" --reload
```

再同步：

```bash
"/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel" --sync
```

---

# 四、iPhone / iPad：仓输入法

仓输入法同样使用 Rime。

基本思路：

1. 仓输入法使用自己的本地 `userdb`
2. 将 Rime 同步目录指向同一个 iCloud 同步位置
3. 在仓输入法中执行 **RIME 同步 / 同步用户数据**
4. 仓会把本机学习数据写入同步目录，同时合并其他设备产生的同步数据

需要注意：

> iCloud 文件同步本身是自动的，但 Rime 的 `userdb ↔ sync/` 合并不是实时发生的。

所以两端都需要适时执行一次 Rime 自己的同步操作。

例如：

```text
Mac 输入新词
    ↓
Mac 执行 Rime 同步
    ↓
iCloud 上传 sync 数据
    ↓
iPhone 执行 RIME 同步
    ↓
Mac 的学习数据合并到 iPhone
```

反过来也一样。

---

# 五、Mac：使用 launchd 每天自动同步

这里不经过「快捷指令」，直接让 macOS 的 `launchd` 调用鼠须管。

本例设置为：

```text
每天 23:00 自动执行一次 Rime 用户数据同步
```

不会在登录时执行。

---

## 1. 创建 LaunchAgent

确保目录存在：

```bash
mkdir -p ~/Library/LaunchAgents
```

创建：

```bash
nano ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
```

写入：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.iapyang.rime-sync</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel</string>
        <string>--sync</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>23</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>/tmp/rime-sync.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/rime-sync.err</string>
</dict>
</plist>
```

---

## 2. 检查 plist

```bash
plutil -lint ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
```

正常应显示：

```text
.../com.iapyang.rime-sync.plist: OK
```

---

## 3. 检查文件权限

```bash
ls -l ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
```

建议是当前用户持有：

```text
-rw-r--r-- ... iapyang staff ... com.iapyang.rime-sync.plist
```

如果权限不正确：

```bash
sudo chown iapyang:staff ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
chmod 644 ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
```

将 `iapyang` 替换为自己的 macOS 用户名。

鼠须管可执行文件通常是：

```bash
ls -l "/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel"
```

类似：

```text
-rwxr-xr-x  root  wheel  ... Squirrel
```

这是正常的，普通用户具有执行权限。

---

## 4. 加载 LaunchAgent

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
```

检查是否成功加载：

```bash
launchctl print gui/$(id -u)/com.iapyang.rime-sync
```

---

# 六、手动触发 LaunchAgent

如果想立即测试一次完整的 launchd 流程：

```bash
launchctl kickstart -k gui/$(id -u)/com.iapyang.rime-sync
```

查看标准输出：

```bash
cat /tmp/rime-sync.log
```

查看错误：

```bash
cat /tmp/rime-sync.err
```

如果只是想绕过 launchd，直接手动同步：

```bash
"/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel" --sync
```

---

# 七、修改定时时间

例如每天凌晨 `02:30`：

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>2</integer>
    <key>Minute</key>
    <integer>30</integer>
</dict>
```

修改 plist 后重新加载：

```bash
launchctl bootout gui/$(id -u)/com.iapyang.rime-sync 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
```

---

# 八、卸载自动同步

临时卸载：

```bash
launchctl bootout gui/$(id -u)/com.iapyang.rime-sync
```

如果以后完全不用：

```bash
rm ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
```

---

# 九、常见问题

## `Bootstrap failed: 5: Input/output error`

先检查 plist：

```bash
plutil -lint ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
```

然后检查 owner 和权限：

```bash
ls -lOe ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
```

必要时修复：

```bash
sudo chown "$(whoami)":staff ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
chmod 644 ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
```

清理旧任务：

```bash
launchctl bootout gui/$(id -u)/com.iapyang.rime-sync 2>/dev/null
```

再重新加载：

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.iapyang.rime-sync.plist
```

不要因为错误提示就直接把用户级 LaunchAgent 改成 `sudo launchctl bootstrap`。

---

# 十、最终结构

推荐的 iCloud 目录：

```text
iCloud Drive/
└── Rime/
    ├── Sync/                       # 核心：Rime 用户数据同步
    └── Backup/
        ├── default.custom.yaml    # 可选：通用 Rime 配置
        ├── squirrel.custom.yaml   # 可选：macOS 鼠须管配置
        └── installation.yaml      # 可选：设备 ID / sync_dir 配置
```

核心原则：

> **userdb 留在本地，sync 放到 iCloud。**

这样既避免直接云同步数据库文件带来的风险，又能利用 Rime 自带的同步/合并机制在 Mac、iPhone、iPad 之间共享长期积累的用户词频和输入习惯。

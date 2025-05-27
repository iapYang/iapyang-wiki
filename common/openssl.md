# OpenSSL
## 压缩
```
openssl enc -aes-256-cbc -pbkdf2 -salt -in backup.tar.gz -out backup.tar.gz.enc -k your-password
```

## 解压缩
```
openssl enc -d -aes-256-cbc -pbkdf2 -in backup.tar.gz.enc -out backup.tar.gz -k your-password
```
## Macos解压缩
macOS 自带的 openssl 版本是 LibreSSL 而不是 OpenSSL，而 LibreSSL 的 enc 命令 并不支持 -pbkdf2 参数

#### 用 Homebrew 安装真正的 OpenSSL
```
brew install openssl
```
安装后，OpenSSL 会被放在 /opt/homebrew/opt/openssl@3/bin/openssl（M1/M2/M3 Mac）或 /usr/local/opt/openssl@3/bin/openssl（Intel Mac）。

#### 使用全路径调用官方 OpenSSL 解密
```
/opt/homebrew/opt/openssl@3/bin/openssl enc -d -aes-256-cbc -pbkdf2 \
  -in yourfile.enc -out yourfile.tar.gz -pass pass:yourpassword
```
> 如果你是 Intel Mac，就用：
```
/usr/local/opt/openssl@3/bin/openssl ...
```
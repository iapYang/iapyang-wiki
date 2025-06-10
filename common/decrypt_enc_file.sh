#!/bin/bash

# 解密脚本：sh decrypt_enc_file.sh xxxx.tar.gz.enc my-password
# curl -sSL https://raw.githubusercontent.com/iapYang/iapyang-wiki/refs/heads/main/common/decrypt_enc_file.sh | bash -s backup.tar.gz.enc my-password

# 参数检查
if [ $# -ne 2 ]; then
  echo "用法: sh $0 <文件名.tar.gz.enc> <密码>"
  exit 1
fi

ENC_FILE="$1"
PASSWORD="$2"

# 校验文件是否存在
if [ ! -f "$ENC_FILE" ]; then
  echo "错误：文件 $ENC_FILE 不存在"
  exit 1
fi

# 输出文件名
OUT_FILE="${ENC_FILE%.enc}"

# 系统判断
OS_TYPE="$(uname)"
OPENSSL_CMD=""

if [ "$OS_TYPE" = "Linux" ]; then
  # Linux 使用系统默认的 openssl
  OPENSSL_CMD="openssl"
elif [ "$OS_TYPE" = "Darwin" ]; then
  # macOS - 判断是 Apple Silicon 还是 Intel
  if [ -x "/opt/homebrew/opt/openssl@3/bin/openssl" ]; then
    OPENSSL_CMD="/opt/homebrew/opt/openssl@3/bin/openssl"
  elif [ -x "/usr/local/opt/openssl@3/bin/openssl" ]; then
    OPENSSL_CMD="/usr/local/opt/openssl@3/bin/openssl"
  else
    echo "错误：未找到可用的 openssl 安装路径，请确认已安装 openssl@3"
    exit 1
  fi
else
  echo "错误：不支持的系统类型: $OS_TYPE"
  exit 1
fi

# 执行解密
echo "使用命令: $OPENSSL_CMD 解密 $ENC_FILE -> $OUT_FILE"
$OPENSSL_CMD enc -d -aes-256-cbc -pbkdf2 -in "$ENC_FILE" -out "$OUT_FILE" -pass pass:"$PASSWORD"

# 检查解密是否成功
if [ $? -eq 0 ]; then
  echo "解密成功，生成文件: $OUT_FILE"
else
  echo "解密失败，请检查密码或文件格式"
  exit 1
fi

#!/bin/bash
#
# 创建受限的 SSH 跳板用户
# 用户只能使用 SSH 命令，无法访问 shell
#

set -e

if [ -z "$1" ]; then
    echo "用法：create-jumpuser.sh <用户名> [密码]"
    echo "示例：create-jumpuser.sh jumpuser"
    echo "      create-jumpuser.sh jumpuser SecurePass123"
    exit 1
fi

USERNAME=$1
PASSWORD=${2:-}

echo "=== 创建受限 SSH 跳板用户：$USERNAME ==="

# 创建用户，使用 jumpshell 作为登录 shell
useradd -m -s /jumpshell $USERNAME

# 设置密码（如果提供）
if [ -n "$PASSWORD" ]; then
    echo "$USERNAME:$PASSWORD" | chpasswd
    echo "✓ 密码已设置"
else
    echo "⚠ 未设置密码，请使用 SSH 密钥认证"
fi

# 创建 SSH 目录
mkdir -p /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh

# 设置权限
chown $USERNAME:$USERNAME /home/$USERNAME
chmod 755 /home/$USERNAME

echo ""
echo "用户创建成功！"
echo ""
echo "用户信息:"
echo "  用户名：$USERNAME"
if [ -n "$PASSWORD" ]; then
    echo "  密码：$PASSWORD"
fi
echo "  Shell: /jumpshell (受限)"
echo "  权限：只能执行 ssh 命令"
echo ""
echo "SSH 连接示例:"
echo "  ssh $USERNAME@<跳板机 IP>"
echo ""
echo "连接后只能执行 SSH 命令:"
echo "  ssh user@target-server"
echo ""

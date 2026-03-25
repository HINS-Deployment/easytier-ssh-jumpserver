#!/bin/bash
#
# 创建受限的 SSH 跳板用户
# 用户只能使用 SSH 命令和查看系统状态（只读）
# 支持密钥和密码共存
#

set -e

if [ -z "$1" ]; then
    echo "用法：create-jumpuser.sh <用户名> [密码]"
    echo "示例：create-jumpuser.sh ssh"
    echo "      create-jumpuser.sh ssh YourPassword123"
    echo ""
    echo "说明:"
    echo "  - 不提供密码：只使用 SSH 密钥认证"
    echo "  - 提供密码：同时支持密钥和密码认证"
    exit 1
fi

USERNAME=$1
PASSWORD=${2:-}

echo "=== 创建受限 SSH 跳板用户：$USERNAME ==="

# 检查用户是否已存在
if id "$USERNAME" &>/dev/null; then
    echo "⚠ 用户 '$USERNAME' 已存在，将更新配置"
    
    # 如果提供了密码，更新密码
    if [ -n "$PASSWORD" ]; then
        echo "$USERNAME:$PASSWORD" | chpasswd
        echo "✓ 密码已更新"
    fi
else
    # 创建用户，使用 jumpshell 作为登录 shell
    useradd -m -s /jumpshell $USERNAME
    
    # 设置密码（如果提供）
    if [ -n "$PASSWORD" ]; then
        echo "$USERNAME:$PASSWORD" | chpasswd
        echo "✓ 密码已设置（支持密钥 + 密码共存）"
    else
        echo "⚠ 未设置密码，请使用 SSH 密钥认证"
    fi
fi

# 创建 SSH 目录
mkdir -p /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh

# 如果提供了公钥文件，复制它
if [ -f "/tmp/authorized_keys_$USERNAME" ]; then
    cp "/tmp/authorized_keys_$USERNAME" /home/$USERNAME/.ssh/authorized_keys
    chmod 600 /home/$USERNAME/.ssh/authorized_keys
    echo "✓ SSH 公钥已配置"
elif [ -f "/home/$USERNAME/.ssh/authorized_keys" ]; then
    echo "✓ SSH 公钥已存在"
else
    echo "ℹ 未配置 SSH 公钥"
fi

# 设置权限
chown -R $USERNAME:$USERNAME /home/$USERNAME
chmod 755 /home/$USERNAME

echo ""
echo "✅ 用户创建成功！"
echo ""
echo "用户信息:"
echo "  用户名：$USERNAME"
if [ -n "$PASSWORD" ]; then
    echo "  密码：$PASSWORD"
    echo "  认证方式：SSH 密钥 或 密码"
else
    echo "  认证方式：SSH 密钥（推荐）"
fi
echo "  Shell: /jumpshell (受限)"
echo "  权限：SSH 命令 + 系统状态查看（只读）"
echo ""
echo "可用命令示例:"
echo "  SSH 连接：ssh user@target-server"
echo "  查看状态：top, ps, free, df, uptime, netstat 等"
echo ""
echo "SSH 连接示例:"
echo "  ssh $USERNAME@<跳板机 IP>"
echo ""

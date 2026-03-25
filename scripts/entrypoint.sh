#!/bin/bash

set -e

# 第一条日志显示 EasyTier 版本
echo "========================================="
echo "EasyTier SSH Jumpserver"
if [ -f /etc/easytier_version ]; then
    source /etc/easytier_version
    echo "Image EasyTier Version: $EASYTIER_VERSION"
fi
VERSION_OUTPUT=$(easytier-core --version 2>&1 || echo "Unknown")
echo "EasyTier Core Version: $VERSION_OUTPUT"
echo "========================================="
echo ""
echo "=== EasyTier SSH Jumpserver Starting ==="
echo "Restricted Mode: Enabled (SSH user only)"
echo "This instance can be managed by external EasyTier Web Console"

export SSH_USER=${SSH_USER:-ssh}
export SSH_PASSWORD=${SSH_PASSWORD:-}
export SSH_JUMPShell=${SSH_JUMPShell:-true}
export EASYTIER_NETWORK_NAME=${EASYTIER_NETWORK_NAME:-}
export EASYTIER_NETWORK_SECRET=${EASYTIER_NETWORK_SECRET:-}
export EASYTIER_SERVERS=${EASYTIER_SERVERS:-}
export ET_CONFIG_SERVER=${ET_CONFIG_SERVER:-}
export ET_MACHINE_ID=${ET_MACHINE_ID:-}

# 创建配置目录
mkdir -p /root/.easytier
mkdir -p /root/.ssh

# 初始化 SSH
init_ssh() {
    echo "=== Initializing SSH ==="
    /usr/local/bin/init-ssh.sh
    
    # 如果 SSH_USER 是 ssh，确保受限用户存在
    if [ "$SSH_USER" = "ssh" ]; then
        echo "=== Creating default restricted user: ssh ==="
        if id "ssh" &>/dev/null; then
            echo "User 'ssh' already exists"
        else
            # 创建受限用户（无密码，只用密钥认证）
            /usr/local/bin/create-jumpuser.sh ssh || echo "User creation failed, may already exist"
        fi
        
        # 确保 authorized_keys 权限正确
        if [ -f /home/ssh/.ssh/authorized_keys ]; then
            chmod 600 /home/ssh/.ssh/authorized_keys
            chown ssh:ssh /home/ssh/.ssh/authorized_keys
        fi
    fi
}

# 启动 EasyTier Core
start_easytier() {
    echo "=== Starting EasyTier Core ==="
    
    # 优先使用配置服务器方式
    if [ -n "$ET_CONFIG_SERVER" ]; then
        EASYTIER_CMD="easytier-core -d -w $ET_CONFIG_SERVER"
        
        # 如果指定了机器 ID，添加到命令中
        if [ -n "$ET_MACHINE_ID" ]; then
            EASYTIER_CMD="$EASYTIER_CMD --machine-id $ET_MACHINE_ID"
            echo "Machine ID: $ET_MACHINE_ID"
        fi
        
        echo "Using config server: $ET_CONFIG_SERVER"
        echo "EasyTier command: $EASYTIER_CMD"
        $EASYTIER_CMD &
        sleep 5
    elif [ -n "$EASYTIER_NETWORK_NAME" ] && [ -n "$EASYTIER_NETWORK_SECRET" ]; then
        EASYTIER_CMD="easytier-core -d --network-name $EASYTIER_NETWORK_NAME --network-secret $EASYTIER_NETWORK_SECRET"
        
        if [ -n "$EASYTIER_SERVERS" ]; then
            IFS=',' read -ra SERVER_ARRAY <<< "$EASYTIER_SERVERS"
            for server in "${SERVER_ARRAY[@]}"; do
                EASYTIER_CMD="$EASYTIER_CMD -p $server"
            done
        fi
        
        echo "EasyTier command: $EASYTIER_CMD"
        $EASYTIER_CMD &
        sleep 5
    else
        echo "Info: No EasyTier config provided"
        echo "Please set ET_CONFIG_SERVER or EASYTIER_* environment variables"
    fi
}

# 启动 SSH 服务
start_sshd() {
    echo "=== Starting SSHD ==="
    /usr/sbin/sshd -D &
}

# 清理函数
cleanup() {
    echo "=== Cleaning up ==="
    pkill -P $$ 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# 启动顺序
init_ssh
start_easytier
start_sshd

echo ""
echo "=== EasyTier SSH Jumpserver Ready ==="
echo "SSH User: $SSH_USER"
echo "SSH Port: $SSH_PORT"
if [ -n "$ET_CONFIG_SERVER" ]; then
    echo "Config Server: $ET_CONFIG_SERVER"
    echo "Managed by EasyTier Web Console"
fi
echo ""
echo "You can now:"
echo "  1. SSH to this server: ssh $SSH_USER@<virtual-ip>"
if [ -n "$ET_CONFIG_SERVER" ]; then
    echo "  2. Configure via Web Console: $ET_CONFIG_SERVER"
fi
echo ""

wait

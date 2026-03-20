# EasyTier SSH Jumpserver 使用示例

## 场景 1: 家庭实验室远程访问

### 拓扑结构
```
互联网
  │
  ├─ 云服务器 (公网 IP)
  │   └─ EasyTier 共享节点
  │
  ├─ 家庭服务器 (无公网 IP)
  │   └─ easytier-ssh-jumpserver
  │      └─ 内网服务 (192.168.1.x)
  │
  └─ 你的笔记本电脑
      └─ easytier-ssh-jumpserver
```

### 部署步骤

**1. 家庭服务器配置**

```bash
# 创建配置目录
mkdir -p /opt/easytier-ssh
cd /opt/easytier-ssh

# 下载项目
git clone https://github.com/your-username/easytier-ssh-jumpserver.git
cd easytier-ssh-jumpserver

# 创建环境变量文件
cat > .env << EOF
SSH_USER=root
SSH_PASSWORD=HomeLab@2024Secure
EASYTIER_NETWORK_NAME=homelab-network
EASYTIER_NETWORK_SECRET=homelab-secret-key-2024
EASYTIER_SERVERS=tcp://your-cloud-server-ip:11010
TZ=Asia/Shanghai
EOF

# 部署
chmod +x deploy.sh
./deploy.sh deploy
```

**2. 笔记本电脑配置**

```bash
# 安装 EasyTier 客户端
docker run -d --privileged --network host \
  -e EASYTIER_NETWORK_NAME=homelab-network \
  -e EASYTIER_NETWORK_SECRET=homelab-secret-key-2024 \
  easytier/easytier:latest
```

**3. 访问家庭服务器**

```bash
# 查看虚拟 IP
docker exec easytier-ssh easytier-cli node

# SSH 连接
ssh root@10.144.144.x

# 访问内网服务
ssh -L 8080:192.168.1.100:80 root@10.144.144.x
# 然后访问 http://localhost:8080
```

## 场景 2: 多区域服务器统一管理

### 拓扑结构
```
                    EasyTier 虚拟网络
                    10.144.144.0/24
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
  北京节点            上海节点          深圳节点
  10.144.144.2        10.144.144.3      10.144.144.4
  (跳板机)            (应用服务器)      (数据库)
```

### 部署步骤

**1. 所有节点统一配置**

```bash
# 在所有服务器上执行
cat > .env << EOF
SSH_USER=admin
SSH_PASSWORD=MultiRegion@2024
EASYTIER_NETWORK_NAME=production-cluster
EASYTIER_NETWORK_SECRET=production-secret-2024
TZ=Asia/Shanghai
EOF

./deploy.sh deploy
```

**2. 配置 SSH 密钥认证（推荐）**

```bash
# 在管理机上生成密钥
ssh-keygen -t ed25519 -f ~/.ssh/easytier_jumpserver

# 复制公钥到所有节点
for node in beijing shanghai shenzhen; do
  mkdir -p ./ssh_keys_$node
  cp ~/.ssh/easytier_jumpserver.pub ./ssh_keys_$node/authorized_keys
done

# 修改 docker-compose.yml 添加 volumes 映射
```

**3. 创建 SSH 配置文件**

```bash
# ~/.ssh/config_eastchina
Host bj-jump
    HostName 10.144.144.2
    User admin
    IdentityFile ~/.ssh/easytier_jumpserver

Host sh-app
    HostName 10.144.144.3
    User admin
    IdentityFile ~/.ssh/easytier_jumpserver
    ProxyJump bj-jump

Host sz-db
    HostName 10.144.144.4
    User admin
    IdentityFile ~/.ssh/easytier_jumpserver
    ProxyJump bj-jump
```

**4. 连接服务器**

```bash
# 直接连接跳板机
ssh -F ~/.ssh/config_eastchina bj-jump

# 通过跳板机连接应用服务器
ssh -F ~/.ssh/config_eastchina sh-app

# 通过跳板机连接数据库
ssh -F ~/.ssh/config_eastchina sz-db
```

## 场景 3: 临时运维通道

### 背景
公司内网服务器需要临时开放给外部运维人员访问，但不想暴露公网 IP。

### 部署步骤

**1. 快速部署临时跳板机**

```bash
# 在内网服务器上
docker run -d --privileged --network host \
  -e SSH_USER=ops \
  -e SSH_PASSWORD=TempOps@2024Expire \
  -e EASYTIER_NETWORK_NAME=ops-temp-access \
  -e EASYTIER_NETWORK_SECRET=ops-temp-secret \
  easytier-ssh-jumpserver:latest
```

**2. 运维人员配置**

```bash
# 运维人员安装 EasyTier
docker run -d --privileged --network host \
  -e EASYTIER_NETWORK_NAME=ops-temp-access \
  -e EASYTIER_NETWORK_SECRET=ops-temp-secret \
  easytier/easytier:latest
```

**3. 验证连接**

```bash
# 获取跳板机虚拟 IP
# 假设是 10.144.144.5

# SSH 连接
ssh ops@10.144.144.5

# 执行运维命令
ssh ops@10.144.144.5 "sudo systemctl restart nginx"
```

**4. 任务完成后清理**

```bash
# 内网服务器
docker stop easytier-ssh
docker rm easytier-ssh
```

## 场景 4: Kubernetes 集群管理节点

### 拓扑结构
```
管理端
   │
   └─ EasyTier SSH Jumpserver
       │
       └─ K8s 集群 (内网)
           ├─ Master: 192.168.10.10
           ├─ Node1: 192.168.10.11
           ├─ Node2: 192.168.10.12
           └─ Node3: 192.168.10.13
```

### 部署步骤

**1. 在 K8s Master 上部署跳板机**

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  easytier-ssh:
    image: easytier-ssh-jumpserver:latest
    hostname: k8s-jumpserver
    container_name: easytier-ssh
    restart: unless-stopped
    network_mode: host
    privileged: true
    cap_add:
      - NET_ADMIN
      - NET_RAW
      - SYS_ADMIN
    environment:
      - TZ=Asia/Shanghai
      - SSH_USER=k8s-admin
      - SSH_PASSWORD=K8sAdmin@2024Secure!
      - EASYTIER_NETWORK_NAME=k8s-management
      - EASYTIER_NETWORK_SECRET=k8s-management-secret
    devices:
      - /dev/net/tun:/dev/net/tun
    volumes:
      - /etc/easytier-ssh:/root
      - /etc/machine-id:/etc/machine-id:ro
      - ./ssh_keys:/root/.ssh:rw
      - ~/.kube:/root/.kube:ro
EOF

docker-compose up -d
```

**2. 配置 kubectl 访问**

```bash
# 复制 kubeconfig 到容器
docker exec easytier-ssh mkdir -p /root/.kube
docker cp ~/.kube/config easytier-ssh:/root/.kube/config

# 验证可以访问集群
docker exec easytier-ssh kubectl get nodes
```

**3. 管理端连接**

```bash
# 管理端运行 EasyTier
docker run -d --privileged --network host \
  -e EASYTIER_NETWORK_NAME=k8s-management \
  -e EASYTIER_NETWORK_SECRET=k8s-management-secret \
  easytier/easytier:latest

# SSH 连接到跳板机
ssh k8s-admin@10.144.144.x

# 在跳板机上执行 kubectl 命令
kubectl get pods -A
kubectl apply -f deployment.yaml
```

## 场景 5: 数据库安全访问通道

### 背景
需要安全地访问云数据库，但不想公开数据库端口。

### 部署步骤

**1. 在数据库同网络内部署跳板机**

```bash
docker run -d --privileged --network host \
  -e SSH_USER=dba \
  -e SSH_PASSWORD=DBA@Secure2024 \
  -e EASYTIER_NETWORK_NAME=db-access-network \
  -e EASYTIER_NETWORK_SECRET=db-access-secret \
  easytier-ssh-jumpserver:latest
```

**2. DBA 工作站配置**

```bash
# 安装 EasyTier 客户端
docker run -d --privileged --network host \
  -e EASYTIER_NETWORK_NAME=db-access-network \
  -e EASYTIER_NETWORK_SECRET=db-access-secret \
  easytier/easytier:latest
```

**3. 建立 SSH 隧道**

```bash
# MySQL 示例
ssh -L 3306:rm-xxxx.mysql.rds.aliyuncs.com:3306 \
    dba@10.144.144.x -N

# PostgreSQL 示例
ssh -L 5432:pg-xxxx.postgresql.rds.aliyuncs.com:5432 \
    dba@10.144.144.x -N

# Redis 示例
ssh -L 6379:redis-xxxx.redis.rds.aliyuncs.com:6379 \
    dba@10.144.144.x -N
```

**4. 本地连接数据库**

```bash
# MySQL
mysql -h 127.0.0.1 -P 3306 -u root -p

# PostgreSQL
psql -h 127.0.0.1 -U postgres

# Redis
redis-cli -h 127.0.0.1
```

## 安全加固建议

### 1. 使用 SSH 密钥代替密码

```bash
# 生成密钥
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/easytier_jumpserver

# 创建 authorized_keys
mkdir -p ./ssh_keys
cp ~/.ssh/easytier_jumpserver.pub ./ssh_keys/authorized_keys

# 修改 docker-compose.yml，添加 volumes 映射
# 移除 SSH_PASSWORD 环境变量
```

### 2. 限制 SSH 用户权限

```bash
# 创建专用用户而不是使用 root
docker exec easytier-ssh adduser -D -s /bin/bash opsuser
docker exec easytier-ssh echo "opsuser:SecurePass123" | chpasswd

# 限制只能使用 SFTP
docker exec easytier-ssh bash -c 'echo "Match User sftpuser\nForceCommand internal-sftp" >> /etc/ssh/sshd_config'
```

### 3. 配置 SSH 失败锁定

```bash
# 安装 fail2ban
docker exec easytier-ssh apk add --no-cache fail2ban

# 配置 fail2ban
cat > fail2ban-jail.conf << EOF
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
```

### 4. 定期更新密码

```bash
# 修改密码脚本
cat > rotate-password.sh << 'EOF'
#!/bin/bash
NEW_PASSWORD=$(openssl rand -base64 16)
docker exec easytier-ssh bash -c "echo \"root:$NEW_PASSWORD\" | chpasswd"
echo "New password: $NEW_PASSWORD"
# 将新密码保存到安全的地方
EOF

chmod +x rotate-password.sh
```

## 监控和日志

### 查看连接日志

```bash
# 实时查看 SSH 连接日志
docker logs -f easytier-ssh | grep sshd

# 查看成功登录
docker exec easytier-ssh grep "Accepted" /var/log/auth.log

# 查看失败尝试
docker exec easytier-ssh grep "Failed" /var/log/auth.log
```

### 监控 EasyTier 状态

```bash
# 创建监控脚本
cat > monitor.sh << 'EOF'
#!/bin/bash
while true; do
  echo "=== $(date) ==="
  docker exec easytier-ssh easytier-cli node
  docker exec easytier-ssh easytier-cli peer
  sleep 60
done
EOF

chmod +x monitor.sh
./monitor.sh
```

## 性能优化

### 1. 启用 SSH 连接复用

```bash
# ~/.ssh/config
Host easytier-*
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
    ServerAliveInterval 30
    ServerAliveCountMax 3
```

### 2. 优化 SSH 加密算法

```bash
# 使用更快的加密算法
cat > sshd_config_custom << EOF
Ciphers chacha20-poly1305@openssh.com,aes-256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256@libssh.org
EOF
```

这些示例涵盖了大多数常见的使用场景。根据你的具体需求，可以选择合适的场景进行部署和配置。

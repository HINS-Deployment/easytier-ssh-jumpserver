# EasyTier SSH Jumpserver

基于 EasyTier 的 SSH 跳板机镜像，通过 EasyTier 组建虚拟网络，实现安全的 SSH 访问。

## 功能特性

- 🔒 **安全组网**: 基于 EasyTier 去中心化虚拟网络
- 🚀 **快速部署**: Docker 一键启动
- 🔑 **多种认证**: 支持密码和 SSH 公钥认证
- 🌐 **跨平台**: 支持 Linux/ARM/x86 等多种架构
- 🖥️ **Web 控制台支持**: 可被外部 EasyTier Web Console 管理
- 🔄 **自动更新**: 支持 watchtower 自动更新
- 📝 **配置监控**: 自动检测配置文件变化并重启
- 🛡️ **安全配置**: 最小权限原则，独立网络隔离

## 快速开始

### 1. 使用预构建镜像（推荐）

```bash
# 直接拉取预构建镜像
docker pull ghcr.io/wuhins/easytier-ssh-jumpserver:latest

# 国内加速（可选）
docker pull docker.gh-proxy.org/ghcr.io/wuhins/easytier-ssh-jumpserver:latest
```

### 2. 使用 Docker Compose 运行（推荐）

```bash
# 克隆仓库
git clone https://github.com/WUHINS/easytier-ssh-jumpserver.git
cd easytier-ssh-jumpserver

# 准备 SSH 密钥（推荐）
mkdir -p ssh_keys
cp ~/.ssh/id_ed25519.pub ssh_keys/authorized_keys
chmod 600 ssh_keys/authorized_keys

# 编辑 docker-compose.yml 配置环境变量

# 启动容器
docker compose up -d

# 查看日志
docker compose logs -f
```

### 3. 使用 Docker 运行

```bash
docker run -d \
  --name easytier-ssh \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --device /dev/net/tun:/dev/net/tun \
  --network etssh-network \
  -e SSH_USER=root \
  -e SSH_PASSWORD=YourSecurePassword123 \
  -e ET_CONFIG_SERVER=ws://api.easytier.hinswu.top:0/HINS \
  -e ET_MACHINE_ID=HINS-UZ801-SSH01 \
  -v $(pwd)/ssh_keys:/root/.ssh:rw \
  ghcr.io/wuhins/easytier-ssh-jumpserver:latest
```

### 4. 自行构建镜像（可选）

```bash
# 从源码构建
git clone https://github.com/WUHINS/easytier-ssh-jumpserver.git
cd easytier-ssh-jumpserver

# 使用 build.sh 脚本构建
./build.sh build

# 或使用 docker compose 构建
docker compose build
```

## 🖥️ 通过 ET_CONFIG_SERVER 连接到 Web Console

本镜像支持通过 **`ET_CONFIG_SERVER`** 环境变量连接到 EasyTier Web Console，实现集中化管理。

### 架构说明

```
┌─────────────────────────────────────┐
│   EasyTier Web Console              │
│   (api.easytier.hinswu.top)         │
│   运行在：ws://server:port/path     │
└─────────────┬───────────────────────┘
              │
              │ WebSocket 连接
              │ ET_CONFIG_SERVER
              │
              ▼
┌─────────────────────────────────────┐
│   SSH Jumpserver Container          │
│   - easytier-core -w $ET_CONFIG_…   │
│   - sshd                            │
│   - 从 Web Console 获取配置          │
└─────────────────────────────────────┘
```

### 配置方式

#### 方式 1: 使用 ET_CONFIG_SERVER（推荐）

```yaml
services:
  easytier-ssh:
    image: ghcr.io/wuhins/easytier-ssh-jumpserver:latest
    environment:
      - ET_CONFIG_SERVER=ws://api.easytier.hinswu.top:0/HINS
      - ET_MACHINE_ID=HINS-UZ801-SSH01  # 可选：指定机器 ID
```

这样 SSH Jumpserver 会自动连接到指定的 Web Console 并获取配置。

#### 方式 2: 直接通过环境变量配置

```yaml
services:
  easytier-ssh:
    image: ghcr.io/wuhins/easytier-ssh-jumpserver:latest
    environment:
      - EASYTIER_NETWORK_NAME=myjumpserver
      - EASYTIER_NETWORK_SECRET=myjumpserver
      - EASYTIER_SERVERS=tcp://your-public-ip:11010
```

这种方式不通过 Web Console，直接配置网络参数。

### ET_CONFIG_SERVER 格式

```bash
# 完整 URL 格式
ET_CONFIG_SERVER=ws://server:port/path
ET_CONFIG_SERVER=wss://server:port/path  # 加密连接
ET_CONFIG_SERVER=udp://server:port/path
ET_CONFIG_SERVER=tcp://server:port/path

# 示例
ET_CONFIG_SERVER=ws://api.easytier.hinswu.top:0/HINS
ET_CONFIG_SERVER=ws://192.168.1.100:22020/mynode
```

### 使用步骤

1. **设置 ET_CONFIG_SERVER 环境变量**
   ```yaml
   environment:
     - ET_CONFIG_SERVER=ws://api.easytier.hinswu.top:0/HINS
   ```

2. **启动容器**
   ```bash
   docker compose up -d
   ```

3. **在 Web Console 中配置**
   - 登录 Web Console
   - 添加设备
   - 配置网络参数
   - 下发配置

4. **验证连接**
   ```bash
   docker logs easytier-ssh | grep "config server"
   ```

### 环境变量说明

| 变量名 | 说明 | 示例 | 必填 |
|--------|------|------|------|
| `ET_CONFIG_SERVER` | Web Console 地址 | `ws://api.easytier.hinswu.top:0/HINS` | 推荐 |
| `ET_MACHINE_ID` | 机器 ID（用于标识设备） | `HINS-UZ801-SSH01` | 推荐 |
| `EASYTIER_NETWORK_NAME` | 网络名称（方式 2） | `mynetwork` | 方式 2 必填 |
| `EASYTIER_NETWORK_SECRET` | 网络密钥（方式 2） | `mysecret` | 方式 2 必填 |
| `EASYTIER_SERVERS` | 服务器地址（方式 2） | `tcp://server:11010` | 方式 2 推荐 |

## 环境变量说明

### SSH 配置

| 变量名 | 说明 | 默认值 | 必填 |
|--------|------|--------|------|
| `SSH_USER` | SSH 登录用户名 | root | 否 |
| `SSH_PASSWORD` | SSH 登录密码 | 无 | 推荐（或使用密钥） |

### EasyTier 配置

| 变量名 | 说明 | 默认值 | 必填 |
|--------|------|--------|------|
| `EASYTIER_NETWORK_NAME` | EasyTier 网络名称 | 无 | 是（方式 2） |
| `EASYTIER_NETWORK_SECRET` | EasyTier 网络密钥 | 无 | 是（方式 2） |
| `EASYTIER_SERVERS` | EasyTier 服务器地址（逗号分隔） | 无 | 推荐（方式 2） |

### 其他配置

| 变量名 | 说明 | 默认值 | 必填 |
|--------|------|--------|------|
| `TZ` | 时区 | Asia/Shanghai | 否 |

## SSH 公钥认证（推荐）

**强烈推荐使用 SSH 公钥认证而非密码认证，更安全！**

### 步骤 1：生成 SSH 密钥对

```bash
ssh-keygen -t ed25519 -C "easytier-ssh-jumpserver"
# 或使用 RSA 4096
ssh-keygen -t rsa -b 4096 -C "easytier-ssh-jumpserver"
```

### 步骤 2：配置公钥

```bash
mkdir -p ssh_keys
cp ~/.ssh/id_ed25519.pub ssh_keys/authorized_keys
chmod 600 ssh_keys/authorized_keys
```

### 步骤 3：在 docker-compose.yml 中挂载

```yaml
volumes:
  - ./ssh_keys:/root/.ssh:rw
```

### 步骤 4：不设置密码（可选）

```yaml
environment:
  - SSH_USER=root
  # 不设置 SSH_PASSWORD，只使用密钥认证
```

## 使用场景

### 场景 1：远程服务器管理

在没有公网 IP 的服务器上部署，通过 EasyTier 虚拟网络 SSH 访问：

```bash
# 服务器 A
docker run -d \
  --name easytier-ssh \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --device /dev/net/tun:/dev/net/tun \
  -e EASYTIER_NETWORK_NAME=mynet \
  -e EASYTIER_NETWORK_SECRET=mynet \
  -e SSH_PASSWORD=secure123 \
  ghcr.io/wuhins/easytier-ssh-jumpserver:latest
```

```bash
# 本地电脑（同一虚拟网络）
ssh root@<服务器 A 的虚拟 IP>
```

### 场景 2：多节点跳板

```bash
# 节点 A（主跳板机）
docker run -d \
  --name easytier-ssh-a \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --device /dev/net/tun:/dev/net/tun \
  -e EASYTIER_NETWORK_NAME=jumpnet \
  -e EASYTIER_NETWORK_SECRET=jumpnet \
  -e SSH_PASSWORD=secure123 \
  ghcr.io/wuhins/easytier-ssh-jumpserver:latest

# 节点 B（内网服务器）
docker run -d \
  --name easytier-ssh-b \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --device /dev/net/tun:/dev/net/tun \
  -e EASYTIER_NETWORK_NAME=jumpnet \
  -e EASYTIER_NETWORK_SECRET=jumpnet \
  -e SSH_PASSWORD=secure123 \
  ghcr.io/wuhins/easytier-ssh-jumpserver:latest
```

### 场景 3：使用共享节点

```bash
docker run -d \
  --name easytier-ssh \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --device /dev/net/tun:/dev/net/tun \
  -e EASYTIER_NETWORK_NAME=myjumpserver \
  -e EASYTIER_NETWORK_SECRET=myjumpserver \
  -e EASYTIER_SERVERS=tcp://shared-node-ip:11010 \
  -e SSH_PASSWORD=secure123 \
  ghcr.io/wuhins/easytier-ssh-jumpserver:latest
```

## 查看运行状态

```bash
# 查看容器日志
docker logs easytier-ssh

# 查看 EasyTier 节点信息
docker exec easytier-ssh easytier-cli node

# 查看 EasyTier 对等节点
docker exec easytier-ssh easytier-cli peer

# 查看路由信息
docker exec easytier-ssh easytier-cli route

# 查看 SSH 服务状态
docker exec easytier-ssh ps aux | grep sshd
```

## 安全建议

### 🔒 强烈推荐

1. **使用 SSH 公钥认证**: 比密码认证更安全，防止暴力破解
2. **使用独立网络**: 不要使用 `host` 网络模式
3. **最小权限原则**: 只添加必要的 `cap_add`，不使用 `privileged`
4. **强密码策略**: 如果必须使用密码，至少 16 位复杂密码
5. **定期更新镜像**: 保持最新的安全补丁

### ⚠️ 避免使用

```yaml
# ❌ 不要使用 host 网络
network_mode: host

# ❌ 不要使用特权模式
privileged: true

# ❌ 不要添加不必要的权限
cap_add:
  - SYS_ADMIN  # 不需要
```

### ✅ 推荐配置

```yaml
# ✅ 使用独立网络
networks:
  - etssh-network

# ✅ 只添加必要权限
cap_add:
  - NET_ADMIN
  - NET_RAW

# ✅ 使用 SSH 密钥认证
volumes:
  - ./ssh_keys:/root/.ssh:rw
```

详细的安全配置指南请参考 [SECURITY.md](SECURITY.md)

## 故障排查

### 无法 SSH 连接

1. 检查容器是否正常运行：
   ```bash
   docker ps | grep easytier-ssh
   ```

2. 检查 SSH 服务状态：
   ```bash
   docker exec easytier-ssh ps aux | grep sshd
   ```

3. 查看容器日志：
   ```bash
   docker logs easytier-ssh
   ```

4. 检查防火墙规则：
   ```bash
   docker exec easytier-ssh iptables -L -n
   ```

### EasyTier 无法连接

1. 检查网络名称和密钥是否正确
2. 检查服务器地址是否可达
3. 查看 EasyTier 状态：
   ```bash
   docker exec easytier-ssh easytier-cli peer
   ```

4. 检查 TUN 设备是否可用：
   ```bash
   docker exec easytier-ssh ls -la /dev/net/tun
   ```

### 容器启动失败

1. 查看详细日志：
   ```bash
   docker compose logs
   ```

2. 检查权限配置：
   ```bash
   docker inspect easytier-ssh | grep -A 10 CapAdd
   ```

3. 检查设备映射：
   ```bash
   docker inspect easytier-ssh | grep -A 10 Devices
   ```

## 技术栈

- **基础镜像**: Alpine Linux
- **SSH 服务**: OpenSSH Server + OpenSSH Client
- **虚拟网络**: EasyTier
- **初始化器**: tini
- **Shell**: Bash

## 端口说明

| 端口 | 协议 | 用途 |
|------|------|------|
| 22 | TCP | SSH 服务 |
| 11010 | TCP/UDP | EasyTier 主端口 |
| 11011 | TCP/UDP | EasyTier WebSocket/WireGuard |
| 11012 | TCP | EasyTier WebSocket SSL |

## 镜像架构

```
easytier-ssh-jumpserver
├── easytier-core      # EasyTier 核心程序
├── easytier-cli       # EasyTier 命令行工具
├── sshd               # SSH 服务端
├── ssh                # SSH 客户端
├── entrypoint.sh      # 启动脚本
└── init-ssh.sh        # SSH 初始化脚本
```

## License

LGPL-3.0

## 相关项目

- [EasyTier](https://github.com/EasyTier/EasyTier)
- [OpenSSH](https://www.openssh.com/)

## 链接

- [GitHub 仓库](https://github.com/WUHINS/easytier-ssh-jumpserver)
- [安全配置指南](SECURITY.md)
- [GitHub Container Registry](https://github.com/WUHINS/easytier-ssh-jumpserver/pkgs/container/easytier-ssh-jumpserver)

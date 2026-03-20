# EasyTier SSH 跳板机 - 安全配置指南

## 🔒 安全最佳实践

### 1. 网络安全

#### ✅ 推荐：使用独立网络
```yaml
networks:
  - etssh-network

networks:
  etssh-network:
    driver: bridge
```

**优点**：
- 容器隔离在独立网络中
- 不暴露到宿主机网络
- 只能通过 EasyTier 虚拟 IP 访问

#### ❌ 不推荐：使用 host 网络
```yaml
network_mode: host  # 危险！不要使用
```

**风险**：
- 容器可以直接访问宿主机所有网络接口
- 增加容器逃逸风险
- 违反最小权限原则

---

### 2. 权限配置

#### ✅ 推荐：最小权限
```yaml
cap_add:
  - NET_ADMIN      # 网络管理（必需）
  - NET_RAW        # 原始网络包（必需）

devices:
  - /dev/net/tun:/dev/net/tun
```

**说明**：
- 移除了 `privileged: true`（特权模式）
- 移除了 `SYS_ADMIN`（系统管理权限）
- 只保留 EasyTier 必需的权限

#### ❌ 不推荐：过度权限
```yaml
privileged: true    # 危险！容器拥有宿主机所有权限
cap_add:
  - SYS_ADMIN       # 不需要
```

---

### 3. SSH 认证安全

#### ✅ 推荐：使用 SSH 密钥认证

**步骤 1：生成 SSH 密钥对**
```bash
ssh-keygen -t ed25519 -C "easytier-ssh-jumpserver"
# 或使用 RSA 4096
ssh-keygen -t rsa -b 4096 -C "easytier-ssh-jumpserver"
```

**步骤 2：配置 docker-compose.yml**
```yaml
volumes:
  - ./ssh_keys:/root/.ssh:rw
```

**步骤 3：复制公钥到 ssh_keys 目录**
```bash
mkdir -p ssh_keys
cp ~/.ssh/id_ed25519.pub ssh_keys/authorized_keys
chmod 600 ssh_keys/authorized_keys
```

**步骤 4：禁用密码认证（可选但推荐）**
在 docker-compose.yml 中不设置 `SSH_PASSWORD`

**优点**：
- 比密码认证更安全
- 防止暴力破解
- 便于自动化管理

#### ⚠️ 如果必须使用密码认证

```yaml
environment:
  - SSH_PASSWORD=YourSecurePassword123  # 使用强密码！
```

**密码要求**：
- ✅ 至少 16 个字符
- ✅ 包含大小写字母、数字、特殊字符
- ✅ 不要使用常见单词
- ✅ 定期更换

**示例强密码**：
```
Kj8#mP2$vL9@nQ4!xR7
```

---

### 4. 数据持久化

#### ✅ 推荐：持久化关键数据

```yaml
volumes:
  # SSH 密钥配置
  - ./ssh_keys:/root/.ssh:rw
  
  # EasyTier 配置（可选）
  - ./easytier_config:/root/.easytier:rw
  
  # 日志（可选）
  - ./logs:/var/log:rw
```

**说明**：
- SSH 密钥持久化：容器重启后仍可访问
- EasyTier 配置持久化：保存网络配置
- 日志持久化：便于审计和故障排查

---

### 5. 镜像安全

#### ✅ 推荐：使用官方预构建镜像

```yaml
image: ghcr.io/wuhins/easytier-ssh-jumpserver:latest
```

**优点**：
- 经过 GitHub Actions 自动构建和测试
- 版本可追溯
- 定期更新安全补丁

#### ⚠️ 国内加速（可选）

```yaml
image: docker.gh-proxy.org/ghcr.io/wuhins/easytier-ssh-jumpserver:latest
```

**说明**：
- 使用 GitHub 代理加速下载
- 镜像内容与官方一致

---

## 📋 完整的安全配置示例

### docker-compose.yml（生产环境推荐）

```yaml
services:
  easytier-ssh:
    image: ghcr.io/wuhins/easytier-ssh-jumpserver:latest
    
    hostname: easytier-ssh
    container_name: easytier-ssh
    restart: unless-stopped
    
    # 独立网络（安全）
    networks:
      - etssh-network
    
    # 最小权限
    cap_add:
      - NET_ADMIN
      - NET_RAW
    
    environment:
      - TZ=Asia/Shanghai
      - SSH_USER=root
      # 不使用密码，只用密钥认证
      # - SSH_PASSWORD=
      
      # 连接到 Web Console
      - ET_CONFIG_SERVER=ws://api.easytier.hinswu.top:0/HINS
      - ET_MACHINE_ID=HINS-UZ801-SSH01
    
    # TUN 设备（必需）
    devices:
      - /dev/net/tun:/dev/net/tun
    
    # 持久化配置
    volumes:
      - ./ssh_keys:/root/.ssh:rw
      - ./easytier_config:/root/.easytier:rw
      - ./logs:/var/log:rw

networks:
  etssh-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
```

---

## 🚀 快速部署（安全配置）

### 1. 准备 SSH 密钥

```bash
# 创建目录
mkdir -p easytier-ssh-jumpserver/ssh_keys

# 生成密钥对
ssh-keygen -t ed25519 -f easytier-ssh-jumpserver/ssh_keys/id_ed25519 \
  -C "easytier-ssh-jumpserver"

# 设置权限
chmod 600 easytier-ssh-jumpserver/ssh_keys/id_ed25519
chmod 644 easytier-ssh-jumpserver/ssh_keys/id_ed25519.pub

# 复制公钥为 authorized_keys
cp easytier-ssh-jumpserver/ssh_keys/id_ed25519.pub \
   easytier-ssh-jumpserver/ssh_keys/authorized_keys
```

### 2. 创建 docker-compose.yml

```bash
cd easytier-ssh-jumpserver
# 使用上面的安全配置示例创建 docker-compose.yml
```

### 3. 启动容器

```bash
docker compose up -d
```

### 4. 验证连接

```bash
# 查看容器日志
docker compose logs -f

# 通过 EasyTier 虚拟 IP 连接
ssh -i ssh_keys/id_ed25519 root@<virtual-ip>
```

---

## 🔍 安全检查清单

- [ ] 不使用 `host` 网络模式
- [ ] 不使用 `privileged: true`
- [ ] 只添加必要的 `cap_add`
- [ ] 使用 SSH 密钥认证（而非密码）
- [ ] 如果必须用密码，使用强密码
- [ ] 持久化 SSH 密钥配置
- [ ] 使用官方预构建镜像
- [ ] 定期更新镜像版本
- [ ] 限制 `ports` 暴露（如果不需要，不要暴露）
- [ ] 启用日志持久化便于审计

---

## ⚠️ 常见安全错误

### 错误 1：使用 host 网络
```yaml
network_mode: host  # ❌ 错误
```

**修复**：
```yaml
networks:
  - etssh-network   # ✅ 正确
```

### 错误 2：使用特权模式
```yaml
privileged: true    # ❌ 错误
```

**修复**：
```yaml
cap_add:
  - NET_ADMIN       # ✅ 正确（只保留必需权限）
  - NET_RAW
```

### 错误 3：使用弱密码
```yaml
SSH_PASSWORD=123456  # ❌ 错误
```

**修复**：
```yaml
# 方案 1：使用强密码
SSH_PASSWORD=Kj8#mP2$vL9@nQ4!xR7  # ✅ 正确

# 方案 2：只用密钥认证（推荐）
# 不设置 SSH_PASSWORD  # ✅ 最安全
```

---

## 📚 参考资料

- [Docker 安全最佳实践](https://docs.docker.com/engine/security/)
- [Linux Capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [SSH 密钥认证配置](https://www.ssh.com/academy/ssh/public-key-authentication)
- [EasyTier 官方文档](https://easytier.cn/)

---

**最后更新**: 2026-03-21  
**版本**: v2.4.5

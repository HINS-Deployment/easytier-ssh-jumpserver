# 版本管理

## Docker 镜像版本策略

EasyTier SSH Jumpserver 的 Docker 镜像版本与 EasyTier Core 保持完全一致。

### 镜像标签规则

构建镜像时会生成两个标签：

```bash
# 1. latest 标签（始终指向最新版本）
easytier-ssh-jumpserver:latest

# 2. 版本号标签（与 EasyTier Core 版本一致）
easytier-ssh-jumpserver:v2.5.0
```

### 版本对应关系

| EasyTier Core | SSH Jumpserver | 说明 |
|---------------|----------------|------|
| v2.5.0 | v2.5.0 | 完全对应 |
| v2.4.0 | v2.4.0 | 完全对应 |
| latest | latest | 都是最新版本 |

## 查看版本信息

### 1. 启动日志查看

容器启动时，第一条日志会显示版本信息：

```bash
docker logs easytier-ssh

# 输出示例：
=========================================
EasyTier SSH Jumpserver
Image EasyTier Version: v2.5.0
EasyTier Core Version: easytier-core 2.5.0
=========================================
```

### 2. 容器内查看

```bash
# 查看 EasyTier Core 版本
docker exec easytier-ssh easytier-core --version

# 查看镜像版本文件
docker exec easytier-ssh cat /etc/easytier_version

# 输出示例：
EASYTIER_VERSION=v2.5.0
```

### 3. Docker 命令查看

```bash
# 查看镜像标签
docker images easytier-ssh-jumpserver

# 输出示例：
REPOSITORY                    TAG       IMAGE ID       CREATED         SIZE
easytier-ssh-jumpserver       v2.5.0    abc123456      2 hours ago     50MB
easytier-ssh-jumpserver       latest    abc123456      2 hours ago     50MB
```

## 构建镜像

### 自动版本构建

使用 `build.sh` 脚本会自动获取 EasyTier 最新版本号：

```bash
./build.sh build

# 输出示例：
=== EasyTier SSH Jumpserver Build Script ===
Downloading EasyTier binaries...
Latest EasyTier version: v2.5.0
Building Docker image...
Building image with EasyTier version: v2.5.0
Docker image built successfully!
Image tags:
  - easytier-ssh-jumpserver:latest
  - easytier-ssh-jumpserver:v2.5.0
```

### 指定版本构建

```bash
# 构建特定版本
./build.sh build v2.4.0

# 多平台构建并推送
./build.sh multiarch v2.5.0
```

## 使用特定版本

### docker-compose.yml

```yaml
services:
  easytier-ssh:
    image: easytier-ssh-jumpserver:v2.5.0  # 指定版本
    # image: easytier-ssh-jumpserver:latest  # 使用最新版
```

### Docker 命令

```bash
# 运行特定版本
docker run -d \
  --name easytier-ssh \
  easytier-ssh-jumpserver:v2.5.0

# 运行最新版
docker run -d \
  --name easytier-ssh \
  easytier-ssh-jumpserver:latest
```

## 版本升级

### 升级到最新版本

```bash
# 拉取最新镜像
docker pull easytier-ssh-jumpserver:latest

# 停止旧容器
docker stop easytier-ssh
docker rm easytier-ssh

# 启动新容器
docker-compose up -d
```

### 回退到特定版本

```bash
# 停止当前容器
docker stop easytier-ssh
docker rm easytier-ssh

# 使用旧版本镜像重新启动
docker run -d \
  --name easytier-ssh \
  easytier-ssh-jumpserver:v2.4.0 \
  [其他参数...]
```

## 版本兼容性

### 配置兼容性

- ✅ 同一主版本内的次版本兼容（v2.x.x 之间）
- ⚠️ 跨主版本可能需要调整配置（v1.x.x → v2.x.x）
- 📋 建议查看 EasyTier 官方更新说明

### Web Console 兼容性

- ET_CONFIG_SERVER 协议保持向后兼容
- 建议使用相同主版本的 Web Console 和 Core

## 版本历史

### v2.5.0 (当前版本)

- 基于 EasyTier Core v2.5.0
- 支持 ET_CONFIG_SERVER 连接 Web Console
- 支持 ET_MACHINE_ID 机器标识
- 集成 SSH 服务
- 自动配置监控

### v2.4.0

- 基于 EasyTier Core v2.4.0
- 初始版本

## 开发版本

### 使用最新开发版本

```bash
# 构建最新开发版本
./build.sh build main

# 镜像标签
easytier-ssh-jumpserver:dev
```

⚠️ **注意**: 开发版本可能不稳定，生产环境请使用正式 release 版本

## 镜像大小

典型镜像大小：

- **压缩后**: ~15 MB
- **解压后**: ~50 MB
- **运行时**: ~60 MB (包含 SSH 服务)

## 相关资源

- [EasyTier 发布页面](https://github.com/EasyTier/EasyTier/releases)
- [EasyTier SSH Jumpserver](https://github.com/EasyTier/EasyTier/tree/main/easytier-ssh-jumpserver)
- [版本更新日志](./CHANGELOG.md)

---

**最后更新**: 2024
**当前版本**: v2.5.0

# 快速开始指南

## 项目概述

EasyTier SSH Jumpserver 是一个基于 EasyTier 虚拟网络的 SSH 跳板机解决方案，让你可以通过 EasyTier 组建的去中心化虚拟网络安全地访问远程服务器。

## 核心特性

- ✅ 基于 EasyTier 去中心化虚拟网络
- ✅ 支持密码和 SSH 公钥认证
- ✅ 🖥️ **支持外部 Web Console 管理** - 可被 EasyTier Web Console 集中管理
- ✅ 一键部署脚本
- ✅ 自动 GitHub Actions 构建
- ✅ 多架构支持 (x86\_64, ARM64, ARMv7, RISCV64)
- ✅ 完整的文档和示例
- ✅ 📝 **配置自动应用** - 监控配置文件变化自动重启

## 项目结构

```
easytier-ssh-jumpserver/
├── Dockerfile              # Docker 镜像构建文件
├── docker-compose.yml      # Docker Compose 配置
├── build.sh               # 自动化构建脚本
├── deploy.sh              # 一键部署脚本
├── README.md              # 项目说明文档
├── EXAMPLES.md            # 使用场景示例
├── LICENSE                # LGPL-3.0 许可证
├── .env.example           # 环境变量示例
├── .gitignore            # Git 忽略文件
├── .github/
│   └── workflows/
│       └── build.yml     # GitHub Actions 工作流
└── scripts/
    ├── entrypoint.sh     # 容器启动脚本
    └── init-ssh.sh       # SSH 初始化脚本
```

## 快速部署（3 步）

### 步骤 1: 准备环境

确保已安装 Docker 和 Docker Compose：

```bash
docker --version
docker compose version
```

### 步骤 2: 配置环境变量

```bash
# 克隆项目
git clone https://github.com/your-username/easytier-ssh-jumpserver.git
cd easytier-ssh-jumpserver

# 复制环境变量示例文件
cp .env.example .env

# 编辑 .env 文件，修改配置
vi .env
```

最少需要修改的配置：

```bash
SSH_PASSWORD=YourSecurePassword123
ET_CONFIG_SERVER=ws://api.easytier.hinswu.top:0/HINS
ET_MACHINE_ID=HINS-UZ801-SSH01
```

### 步骤 3: 一键部署

```bash
chmod +x deploy.sh
./deploy.sh deploy
```

## 验证部署

### 1. 检查容器状态

```bash
docker ps | grep easytier-ssh
```

### 2. 访问 Web 控制台（推荐）

打开浏览器访问：

```
http://<服务器 IP>:9999
```

默认登录凭据：

- 用户名：`admin`
- 密码：`admin`

⚠️ **首次使用请立即修改密码！**

通过 Web 控制台你可以：

- ✅ 可视化配置 EasyTier 网络
- ✅ 查看节点和对等点状态
- ✅ 监控网络延迟和带宽
- ✅ 管理多个配置

### 3. 查看 EasyTier 节点信息

```bash
docker exec easytier-ssh easytier-cli node
```

### 4. 查看对等节点

```bash
docker exec easytier-ssh easytier-cli peer
```

### 5. SSH 测试连接

获取虚拟 IP 后（例如 10.144.144.x）：

```bash
ssh root@10.144.144.x
```

## 从 EasyTier 原仓库拉取文件

本项目设计为从 EasyTier 原仓库自动拉取二进制文件。构建过程：

### 自动构建（推荐）

GitHub Actions 会自动从 [EasyTier/EasyTier](https://github.com/EasyTier/EasyTier) 仓库的 latest release 下载二进制文件并构建镜像。

### 手动构建

```bash
# 使用 build.sh 脚本
chmod +x build.sh
./build.sh build

# 这会：
# 1. 清理旧的构建文件
# 2. 从 EasyTier GitHub Releases 下载最新二进制
# 3. 构建 Docker 镜像
```

### 多平台构建

```bash
./build.sh multiarch v1.0.0
```

## 常用命令

### 部署相关

```bash
./deploy.sh deploy          # 部署服务
./deploy.sh build           # 仅构建镜像
./deploy.sh start           # 启动服务
./deploy.sh stop            # 停止服务
./deploy.sh restart         # 重启服务
./deploy.sh status          # 查看状态
./deploy.sh logs            # 查看日志
./deploy.sh clean           # 清理所有
```

### Docker 命令

```bash
# 查看日志
docker logs -f easytier-ssh

# 进入容器
docker exec -it easytier-ssh bash

# 查看 EasyTier 状态
docker exec easytier-ssh easytier-cli node
docker exec easytier-ssh easytier-cli peer
docker exec easytier-ssh easytier-cli route

# 重启容器
docker restart easytier-ssh

# 停止并删除
docker stop easytier-ssh
docker rm easytier-ssh
```

### Docker Compose 命令

```bash
# 启动
docker-compose up -d

# 停止
docker-compose down

# 查看日志
docker-compose logs -f

# 重启
docker-compose restart

# 重新构建并启动
docker-compose up -d --build
```

## 配置说明

### 环境变量

| 变量                        | 说明      | 示例                    | 必填 |
| ------------------------- | ------- | --------------------- | -- |
| `SSH_USER`                | SSH 用户名 | `root`                | 否  |
| `SSH_PASSWORD`            | SSH 密码  | `SecurePass123`       | 推荐 |
| `EASYTIER_NETWORK_NAME`   | 网络名称    | `myjumpserver`        | 是  |
| `EASYTIER_NETWORK_SECRET` | 网络密钥    | `mysecret`            | 是  |
| `EASYTIER_SERVERS`        | 服务器地址   | `tcp://1.2.3.4:11010` | 推荐 |
| `TZ`                      | 时区      | `Asia/Shanghai`       | 否  |

### 使用共享节点

```bash
# 编辑 .env
EASYTIER_SERVERS=tcp://shared-node-ip:11010

# 重新部署
./deploy.sh restart
```

### 使用公钥认证

```bash
# 生成密钥对
ssh-keygen -t ed25519

# 复制公钥
mkdir -p ./ssh_keys
cp ~/.ssh/id_ed25519.pub ./ssh_keys/authorized_keys

# 修改 docker-compose.yml，添加 volumes 映射：
# volumes:
#   - ./ssh_keys:/root/.ssh:rw

# 重启
./deploy.sh restart
```

## 使用场景

### 1. 远程服务器管理

在没有公网 IP 的服务器上部署，通过虚拟网络 SSH 访问。

### 2. 多节点跳板

多个服务器组成虚拟网络，通过一个跳板机访问所有节点。

### 3. 临时运维通道

临时开放给外部人员访问，任务完成后立即销毁。

### 4. 数据库安全访问

通过 SSH 隧道安全访问云数据库。

### 5. Kubernetes 集群管理

作为 K8s 集群的管理入口。

详细示例请查看 [EXAMPLES.md](./EXAMPLES.md)

## 故障排查

### 容器无法启动

```bash
# 查看日志
docker logs easytier-ssh

# 检查配置
docker exec easytier-ssh env | grep EASYTIER
```

### EasyTier 无法连接

```bash
# 检查网络名称和密钥
docker exec easytier-ssh easytier-cli node

# 检查服务器连接
docker exec easytier-ssh easytier-cli peer
```

### SSH 无法连接

```bash
# 检查 SSH 服务
docker exec easytier-ssh ps aux | grep sshd

# 检查 SSH 日志
docker exec easytier-ssh cat /var/log/auth.log

# 重启 SSH 服务
docker exec easytier-ssh pkill sshd
docker exec easytier-ssh /usr/sbin/sshd
```

## 安全建议

1. **使用强密码**: 至少 12 位，包含大小写字母、数字和特殊字符
2. **使用 SSH 公钥**: 优先使用公钥认证
3. **定期更新**: 保持镜像最新版本
4. **网络隔离**: 使用独立的网络名称和密钥
5. **最小权限**: 创建专用用户而非使用 root

## 下一步

- 📖 阅读完整文档：[README.md](./README.md)
- 💡 查看使用示例：[EXAMPLES.md](./EXAMPLES.md)
- 🔧 自定义配置：编辑 `docker-compose.yml`
- 🚀 生产部署：参考安全建议进行加固

## 获取帮助

- 查看文档：README.md, EXAMPLES.md
- 提交 Issue: GitHub Issues
- 讨论交流：Telegram / QQ 群

## 相关项目

- [EasyTier](https://github.com/EasyTier/EasyTier) - 基础虚拟网络项目
- [OpenSSH](https://www.openssh.com/) - SSH 服务

***

**开始使用吧！** 🚀

```bash
./deploy.sh deploy
```


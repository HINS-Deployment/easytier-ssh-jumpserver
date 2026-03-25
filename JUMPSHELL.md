# SSH 跳板机受限模式配置指南

## 🔒 什么是受限模式？

受限模式（Restricted Mode）下，跳板机用户**只能执行 SSH 命令**，无法访问系统 shell 或其他命令，极大提高了安全性。

### 功能对比

| 功能 | 普通模式 | 受限模式 |
|------|----------|----------|
| SSH 登录 | ✅ | ✅ |
| 执行 SSH 命令 | ✅ | ✅ |
| 访问 Shell | ✅ | ❌ |
| 执行其他命令 | ✅ | ❌ |
| SFTP 文件传输 | ✅ | ✅ |
| 端口转发 | ✅ | ✅ |

---

## 🚀 快速开始

### 默认配置（推荐）

**镜像默认已经启用受限模式**，用户名为 `ssh`，只能执行 SSH 命令。

```bash
# 准备 SSH 公钥
mkdir -p ssh_keys
cp ~/.ssh/id_ed25519.pub ssh_keys/authorized_keys
chmod 600 ssh_keys/authorized_keys

# 启动容器
docker compose up -d

# 使用受限用户连接
ssh ssh@<virtual-ip>
```

连接后只能执行 SSH 命令：
```bash
========================================
  EasyTier SSH Jumpserver
  受限环境 - 仅允许 SSH 命令
========================================

ssh> ssh user@target-server
```

---

### 自定义受限用户

#### 步骤 1：创建额外的受限用户

```bash
# 进入容器
docker exec -it easytier-ssh bash

# 创建受限用户（需要密码）
create-jumpuser.sh jumpuser YourSecurePassword123

# 或创建无密码用户（只用 SSH 密钥）
create-jumpuser.sh jumpuser
```

#### 步骤 2：配置 SSH 密钥（可选但推荐）

```bash
# 将你的公钥添加到用户
mkdir -p /home/jumpuser/.ssh
echo "ssh-ed25519 AAAA..." >> /home/jumpuser/.ssh/authorized_keys
chown -R jumpuser:jumpuser /home/jumpuser/.ssh
chmod 700 /home/jumpuser/.ssh
chmod 600 /home/jumpuser/.ssh/authorized_keys
```

#### 步骤 3：测试连接

```bash
# 使用密码连接
ssh jumpuser@<virtual-ip>

# 使用密钥连接
ssh -i ~/.ssh/id_ed25519 jumpuser@<virtual-ip>
```

连接后会看到：
```
========================================
  EasyTier SSH Jumpserver
  受限环境 - 仅允许 SSH 命令
========================================

用法：ssh <目标主机>
示例：ssh user@192.168.1.100
      ssh -p 2222 user@example.com

按 Ctrl+D 或输入 'exit' 退出

jumpserver>
```

#### 步骤 4：使用 SSH 跳转

```bash
jumpserver> ssh user@target-server
Password: ******
```

---

### 方式 2：全局启用受限模式

如果你希望**所有用户**（包括 root）都使用受限模式：

#### Docker Compose 配置

```yaml
services:
  easytier-ssh:
    image: ghcr.io/wuhins/easytier-ssh-jumpserver:latest
    environment:
      - SSH_JUMPShell=true  # 启用全局受限模式
      - SSH_USER=root
      - SSH_PASSWORD=YourPassword123
    # ... 其他配置
```

#### Docker 命令

```bash
docker run -d \
  --name easytier-ssh \
  -e SSH_JUMPShell=true \
  -e SSH_USER=root \
  -e SSH_PASSWORD=YourPassword123 \
  # ... 其他配置
  ghcr.io/wuhins/easytier-ssh-jumpserver:latest
```

重启容器后，所有用户登录后都会自动进入受限模式。

---

## 📋 详细配置

### 环境变量说明

| 变量名 | 说明 | 默认值 | 示例 |
|--------|------|--------|------|
| `SSH_JUMPShell` | 是否启用受限模式 | `false` | `true`/`false` |
| `SSH_USER` | SSH 用户名 | `root` | `root` |
| `SSH_PASSWORD` | SSH 密码 | 无 | `YourPassword123` |

### 创建多个受限用户

```bash
# 进入容器
docker exec -it easytier-ssh bash

# 创建多个受限用户
create-jumpuser.sh user1 Password1
create-jumpuser.sh user2 Password2
create-jumpuser.sh user3 Password3

# 查看用户列表
cat /etc/passwd | grep -E "^user[123]"
```

### 删除受限用户

```bash
# 删除用户及其主目录
userdel -r jumpuser
```

---

## 🔐 安全增强建议

### 1. 使用 SSH 密钥认证

```bash
# 创建无密码用户
create-jumpuser.sh jumpuser

# 配置公钥
docker exec -it easytier-ssh bash
echo "ssh-ed25519 AAAA..." >> /home/jumpuser/.ssh/authorized_keys
chown -R jumpuser:jumpuser /home/jumpuser/.ssh
```

### 2. 禁用密码登录

编辑 `docker-compose.yml`：
```yaml
environment:
  - SSH_PASSWORD=  # 不设置密码
```

### 3. 限制允许的 SSH 选项

修改 `/etc/ssh/sshd_config`（在容器内）：
```bash
# 禁用端口转发（如果需要）
AllowTcpForwarding no
AllowAgentForwarding no

# 禁用 X11
X11Forwarding no

# 重启 SSH 服务
service ssh restart
```

### 4. 审计日志

查看用户操作日志：
```bash
# 查看 SSH 连接日志
docker logs easytier-ssh | grep "Accepted"

# 查看 jumpshell 命令历史
docker exec easytier-ssh cat /home/jumpuser/.bash_history
```

---

## ⚠️ 注意事项

### 受限模式的限制

1. **只能执行 SSH 命令**
   ```bash
   # ✅ 允许
   ssh user@hostname
   
   # ❌ 不允许
   ls
   cd
   cat /etc/passwd
   ```

2. **无法访问系统 Shell**
   - 无法执行 `bash`、`sh` 等
   - 无法使用 `su`、`sudo`

3. **SFTP 仍然可用**
   - 文件传输功能正常
   - 如果需要禁用，修改 `sshd_config`

### 如何退出受限模式

```bash
# 方法 1：输入 exit
jumpserver> exit

# 方法 2：按 Ctrl+D

# 方法 3：关闭 SSH 连接
```

---

## 🔍 故障排查

### 问题 1：用户无法登录

**症状**：SSH 连接立即断开

**原因**：可能没有正确设置密码或 SSH 密钥

**解决**：
```bash
# 检查用户是否存在
docker exec easytier-ssh id jumpuser

# 重置密码
docker exec easytier-ssh bash
echo "jumpuser:NewPassword123" | chpasswd
```

### 问题 2：受限模式未生效

**症状**：用户仍然可以执行其他命令

**原因**：`SSH_JUMPShell` 未设置为 `true`

**解决**：
```yaml
# docker-compose.yml
environment:
  - SSH_JUMPShell=true  # 确保设置为 true
```

然后重启容器：
```bash
docker compose restart
```

### 问题 3：无法创建用户

**症状**：`create-jumpuser.sh` 命令失败

**原因**：容器内没有该命令或权限不足

**解决**：
```bash
# 确认脚本存在
docker exec easytier-ssh ls -la /usr/local/bin/create-jumpuser.sh

# 检查权限
docker exec easytier-ssh chmod +x /usr/local/bin/create-jumpuser.sh
```

---

## 📊 使用场景

### 场景 1：运维跳板

```bash
# 创建受限运维账号
create-jumpuser.sh ops_user OpsPassword123

# 运维人员只能 SSH 到目标服务器
ssh ops_user@jumpserver
# 然后：ssh user@production-server
```

### 场景 2：客户访问

```bash
# 为客户创建独立受限账号
create-jumpuser.sh client_a ClientPassword

# 客户只能访问其授权的主机
```

### 场景 3：自动化脚本

```bash
# 创建无密码的自动化账号
create-jumpuser.sh auto_deploy

# 配置 SSH 密钥
# 在 CI/CD 中使用密钥进行自动化部署
ssh -i /path/to/private/key auto_deploy@jumpserver "ssh user@target"
```

---

## 🎯 最佳实践总结

1. ✅ **为每个用户创建独立账号** - 便于审计
2. ✅ **使用 SSH 密钥而非密码** - 更安全
3. ✅ **定期审查用户列表** - 删除不再需要的账号
4. ✅ **启用日志记录** - 便于追踪操作
5. ✅ **定期更新镜像** - 保持安全补丁最新

---

**最后更新**: 2026-03-21  
**版本**: v2.4.5

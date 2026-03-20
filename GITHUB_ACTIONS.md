# GitHub Actions 使用指南

## 自动触发

### Push 到 main 分支
当你推送代码到 `main` 分支时，会自动构建并推送镜像到：
- Docker Hub: `wuhins/easytier-ssh-jumpserver:latest`
- GitHub Container Registry: `ghcr.io/wuhins/easytier-ssh-jumpserver:latest`

### 创建版本标签
当你创建版本标签（如 `v2.5.0`）时，会自动构建并推送对应版本的镜像：
```bash
git tag v2.5.0
git push origin v2.5.0
```

镜像标签：
- `wuhins/easytier-ssh-jumpserver:v2.5.0`
- `wuhins/easytier-ssh-jumpserver:v2`
- `wuhins/easytier-ssh-jumpserver:v2.5`

## 手动触发（Workflow Dispatch）

### 在 GitHub 网站上触发

1. 进入仓库页面：https://github.com/WUHINS/easytier-ssh-jumpserver
2. 点击 **Actions** 标签
3. 选择 **Build and Push Docker Image** 工作流
4. 点击 **Run workflow** 按钮
5. 填写参数：
   - **Version tag**: 版本号（如 `v2.5.0` 或 `latest`）
   - **Push to registry**: 是否推送到镜像仓库（默认 true）
   - **Platforms**: 构建的平台（默认 `linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6`）
6. 点击 **Run workflow**

### 使用 GitHub CLI 触发

```bash
# 触发工作流
gh workflow run build.yml

# 带参数触发
gh workflow run build.yml \
  -f version=v2.5.0 \
  -f push_to_registry=true \
  -f platforms=linux/amd64,linux/arm64
```

### 使用 GitHub API 触发

```bash
# 使用 curl
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/WUHINS/easytier-ssh-jumpserver/actions/workflows/build.yml/dispatches \
  -d '{"ref":"main","inputs":{"version":"v2.5.0","push_to_registry":"true"}}'
```

## 配置 Secrets

在 GitHub 仓库中配置以下 Secrets：

1. 进入仓库 **Settings** > **Secrets and variables** > **Actions**
2. 点击 **New repository secret**
3. 添加以下 secrets：

### Docker Hub
```
Name: DOCKERHUB_USERNAME
Value: your-dockerhub-username

Name: DOCKERHUB_TOKEN
Value: your-dockerhub-access-token
```

获取 Docker Hub Token：
1. 登录 Docker Hub: https://hub.docker.com
2. 进入 **Account Settings** > **Security**
3. 点击 **New Access Token**
4. 输入描述，选择读写权限
5. 复制生成的 token

### GitHub Container Registry
GHCR 使用 `GITHUB_TOKEN` 自动认证，无需额外配置。

## 工作流输出

工作流运行成功后，你会收到：
- ✅ 构建成功的通知
- 📦 Docker Hub 镜像：https://hub.docker.com/r/wuhins/easytier-ssh-jumpserver
- 📦 GHCR 镜像：https://github.com/WUHINS/easytier-ssh-jumpserver/pkgs/container/easytier-ssh-jumpserver

## 查看构建日志

1. 进入 **Actions** 标签
2. 点击对应的工作流运行
3. 查看各个步骤的日志输出

### 查看版本信息
```bash
# 在工作流日志中搜索 "Downloading EasyTier"
# 会显示当前使用的 EasyTier 版本
```

## 故障排查

### 构建失败

检查项目：
1. **Dockerfile 语法**: 确保 Dockerfile 正确
2. **EasyTier 下载地址**: 确保 GitHub Releases 存在
3. **Secrets 配置**: 确保 Docker Hub 凭证正确

### 推送失败

检查项目：
1. **Docker Hub 凭证**: 确认 username 和 token 正确
2. **GHCR 权限**: 确认仓库有写入权限
3. **镜像名称**: 确认镜像名称格式正确

### 手动触发不显示

确保：
1. 你有仓库的 **write** 权限
2. 仓库已启用 GitHub Actions
3. 工作流文件语法正确

## 自定义工作流

### 添加更多平台

编辑 `.github/workflows/build.yml`：

```yaml
platforms:
  description: 'Platforms to build'
  required: false
  default: 'linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6,linux/riscv64'
```

### 添加测试步骤

```yaml
- name: Test Docker image
  run: |
    docker run --rm docker.io/wuhins/easytier-ssh-jumpserver:latest easytier-core --version
```

### 发送通知

```yaml
- name: Notify on success
  if: success()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "Build succeeded! Check: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
      }
```

## 最佳实践

1. **使用标签发布**: 使用语义化版本标签（v2.5.0）
2. **定期更新**: 定期触发构建以获取最新的 EasyTier 版本
3. **多平台测试**: 在推送前测试主要平台（amd64, arm64）
4. **清理旧镜像**: 定期清理 Docker Hub 上的旧版本镜像

## 相关资源

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Docker Buildx 文档](https://docs.docker.com/buildx/working-with-buildx/)
- [EasyTier 发布页面](https://github.com/EasyTier/EasyTier/releases)

---

**祝你使用愉快！** 🚀

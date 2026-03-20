#!/bin/bash

set -e

echo "=== EasyTier SSH Jumpserver Quick Deploy ==="

# 配置变量
CONTAINER_NAME="easytier-ssh"
IMAGE_NAME="easytier-ssh-jumpserver:latest"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查 Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
    fi
    
    if ! docker ps &> /dev/null; then
        error "Docker daemon is not running. Please start Docker."
    fi
    
    info "Docker is running"
}

# 检查 Docker Compose
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        error "Docker Compose is not installed."
    fi
    
    info "Docker Compose found: $COMPOSE_CMD"
}

# 停止并删除旧容器
cleanup() {
    info "Cleaning up old containers..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
}

# 拉取镜像
pull_image() {
    info "Pulling Docker image..."
    docker pull "$IMAGE_NAME" || warn "Failed to pull image, will build locally"
}

# 构建镜像
build_image() {
    info "Building Docker image..."
    docker build -t "$IMAGE_NAME" .
}

# 创建网络目录
setup_directories() {
    info "Setting up directories..."
    mkdir -p /etc/easytier-ssh
    mkdir -p ./ssh_keys
    
    if [ ! -f ./ssh_keys/authorized_keys ]; then
        warn "No authorized_keys found in ./ssh_keys/"
        info "You can add your SSH public key to ./ssh_keys/authorized_keys"
    fi
}

# 部署服务
deploy() {
    info "Deploying EasyTier SSH Jumpserver..."
    
    $COMPOSE_CMD up -d
    
    if [ $? -eq 0 ]; then
        info "Deployment successful!"
        show_status
    else
        error "Deployment failed!"
    fi
}

# 显示状态
show_status() {
    echo ""
    info "Container status:"
    docker ps | grep "$CONTAINER_NAME"
    
    echo ""
    info "Recent logs:"
    docker logs --tail 20 "$CONTAINER_NAME"
    
    echo ""
    info "To view EasyTier status:"
    echo "  docker exec $CONTAINER_NAME easytier-cli node"
    echo "  docker exec $CONTAINER_NAME easytier-cli peer"
    echo ""
    echo "To SSH into the jumpserver:"
    echo "  ssh root@<virtual-ip>"
}

# 主流程
main() {
    case "${1:-deploy}" in
        deploy)
            check_docker
            check_docker_compose
            setup_directories
            
            if [ "$2" = "--build" ]; then
                build_image
            else
                pull_image || build_image
            fi
            
            cleanup
            deploy
            ;;
        build)
            check_docker
            build_image
            ;;
        start)
            check_docker
            check_docker_compose
            $COMPOSE_CMD up -d
            show_status
            ;;
        stop)
            check_docker
            check_docker_compose
            $COMPOSE_CMD down
            info "Container stopped"
            ;;
        restart)
            check_docker
            check_docker_compose
            $COMPOSE_CMD restart
            show_status
            ;;
        status)
            show_status
            ;;
        logs)
            docker logs -f "$CONTAINER_NAME"
            ;;
        clean)
            check_docker
            check_docker_compose
            $COMPOSE_CMD down
            docker rmi "$IMAGE_NAME" 2>/dev/null || true
            info "Cleaned up"
            ;;
        *)
            echo "Usage: $0 {deploy [--build]|build|start|stop|restart|status|logs|clean}"
            exit 1
            ;;
    esac
}

main "$@"

#!/bin/bash

set -e

echo "=== EasyTier SSH Jumpserver Build Script ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
EASYTIER_REPO="https://github.com/EasyTier/EasyTier.git"
EASYTIER_BRANCH="main"

# 清理旧构建
cleanup() {
    echo "Cleaning up build directory..."
    rm -rf "$BUILD_DIR"
}

# 下载 EasyTier 二进制文件
download_easytier() {
    echo "Downloading EasyTier binaries..."
    
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # 从 GitHub Releases 下载最新版本的 EasyTier
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/EasyTier/EasyTier/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    echo "Latest EasyTier version: $LATEST_RELEASE"
    
    # 下载不同架构的二进制文件
    ARCHIVES=(
        "easytier-linux-x86_64"
        "easytier-linux-aarch64"
        "easytier-linux-armv7hf"
        "easytier-linux-armhf"
        "easytier-linux-riscv64"
    )
    
    for arch in "${ARCHIVES[@]}"; do
        URL="https://github.com/EasyTier/EasyTier/releases/download/$LATEST_RELEASE/${arch}.zip"
        echo "Downloading $arch..."
        
        if curl -L -o "${arch}.zip" "$URL" 2>/dev/null; then
            unzip -o "${arch}.zip"
            mkdir -p "$arch"
            mv easytier-core* "$arch/" 2>/dev/null || true
            echo "Downloaded $arch successfully"
        else
            echo "Warning: Failed to download $arch"
        fi
    done
    
    # 下载 easytier-web（用于 Web 控制台）
    echo "Downloading easytier-web..."
    WEB_ARCHIVES=(
        "easytier-web-linux-x86_64"
        "easytier-web-linux-aarch64"
    )
    
    for arch in "${WEB_ARCHIVES[@]}"; do
        URL="https://github.com/EasyTier/EasyTier/releases/download/$LATEST_RELEASE/${arch}.zip"
        echo "Downloading $arch..."
        
        if curl -L -o "${arch}.zip" "$URL" 2>/dev/null; then
            unzip -o "${arch}.zip"
            mkdir -p "easytier-web"
            mv easytier-web* "easytier-web/" 2>/dev/null || true
            echo "Downloaded $arch successfully"
        else
            echo "Warning: Failed to download $arch"
        fi
    done
    
    cd "$SCRIPT_DIR"
}

# 构建 Docker 镜像
build_docker() {
    echo "Building Docker image..."
    
    # 使用 EasyTier 版本号作为镜像标签
    if [ -n "$LATEST_RELEASE" ]; then
        EASYTIER_VERSION="$LATEST_RELEASE"
        echo "Building image with EasyTier version: $EASYTIER_VERSION"
        
        docker build \
            --build-arg TARGETPLATFORM=linux/amd64 \
            -t easytier-ssh-jumpserver:latest \
            -t "easytier-ssh-jumpserver:$EASYTIER_VERSION" \
            -f "$SCRIPT_DIR/Dockerfile" \
            "$BUILD_DIR"
        
        echo "Docker image built successfully!"
        echo "Image tags:"
        echo "  - easytier-ssh-jumpserver:latest"
        echo "  - easytier-ssh-jumpserver:$EASYTIER_VERSION"
    else
        docker build \
            --build-arg TARGETPLATFORM=linux/amd64 \
            -t easytier-ssh-jumpserver:latest \
            -f "$SCRIPT_DIR/Dockerfile" \
            "$BUILD_DIR"
        
        echo "Docker image built successfully!"
    fi
}

# 多平台构建
build_multiarch() {
    echo "Building multi-architecture Docker images..."
    
    docker buildx build \
        --platform linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6,linux/riscv64 \
        -t easytier-ssh-jumpserver:latest \
        -t easytier-ssh-jumpserver:$1 \
        --push \
        -f "$SCRIPT_DIR/Dockerfile" \
        "$BUILD_DIR"
    
    echo "Multi-architecture images built and pushed!"
}

# 主流程
main() {
    case "${1:-build}" in
        clean)
            cleanup
            ;;
        download)
            download_easytier
            ;;
        build)
            cleanup
            download_easytier
            build_docker
            ;;
        multiarch)
            cleanup
            download_easytier
            build_multiarch "${2:-latest}"
            ;;
        *)
            echo "Usage: $0 {clean|download|build|multiarch [tag]}"
            exit 1
            ;;
    esac
}

main "$@"

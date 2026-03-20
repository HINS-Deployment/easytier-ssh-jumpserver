FROM alpine:latest AS base
FROM base AS builder

ARG TARGETPLATFORM

COPY . /tmp/artifacts
WORKDIR /tmp/output
RUN ARTIFACT_ARCH=""; \
    if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        ARTIFACT_ARCH="x86_64"; \
    elif [ "$TARGETPLATFORM" = "linux/arm/v6" ]; then \
        ARTIFACT_ARCH="armhf"; \
    elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
        ARTIFACT_ARCH="armv7hf"; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        ARTIFACT_ARCH="aarch64"; \
    elif [ "$TARGETPLATFORM" = "linux/riscv64" ]; then \
        ARTIFACT_ARCH="riscv64"; \
    else \
        echo "Unsupported architecture: $TARGETPLATFORM"; \
        exit 1; \
    fi; \
    cp /tmp/artifacts/easytier-linux-${ARTIFACT_ARCH}/* /tmp/output;

FROM base

RUN apk add --no-cache tzdata tini openssh-server sshpass bash curl

WORKDIR /app

# 安装 easytier-core
COPY --from=builder --chmod=755 /tmp/output/* /usr/local/bin

# 复制脚本
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# 获取 EasyTier 版本并设置为环境变量
RUN EASYTIER_VERSION=$(easytier-core --version 2>&1 | head -n1 || echo "unknown") && \
    echo "Built with EasyTier version: $EASYTIER_VERSION" && \
    echo "EASYTIER_VERSION=$EASYTIER_VERSION" > /etc/easytier_version

ENV TZ=Asia/Shanghai
ENV SSH_PORT=22
ENV SSH_USER=root
ENV SSH_PASSWORD=
ENV EASYTIER_NETWORK_NAME=
ENV EASYTIER_NETWORK_SECRET=
ENV EASYTIER_SERVERS=
ENV ET_CONFIG_SERVER=

# 暴露端口
EXPOSE 22/tcp
EXPOSE 11010/tcp
EXPOSE 11010/udp
EXPOSE 11011/udp
EXPOSE 11011/tcp
EXPOSE 11012/tcp

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]

# 启动 SSH 服务
start_sshd() {
    echo "=== Starting SSHD ==="
    # 确保 sshd 目录存在
    mkdir -p /var/run/sshd
    
    # 测试 sshd 配置
    echo "Testing SSH configuration..."
    if /usr/sbin/sshd -t 2>&1; then
        echo "✓ SSH configuration test passed"
    else
        echo "✗ SSH configuration test failed, check config"
        cat /etc/ssh/sshd_config
        return 1
    fi
    
    # 启动 sshd（前台模式，后台运行）
    echo "Starting sshd daemon..."
    /usr/sbin/sshd -D &
    SSHD_PID=$!
    
    # 检查是否启动成功
    sleep 2
    
    # 方法 1：检查进程
    if kill -0 $SSHD_PID 2>/dev/null; then
        echo "✓ SSHD started successfully (PID: $SSHD_PID)"
    else
        echo "✗ SSHD failed to start"
        # 显示错误日志
        echo "=== Last SSH errors ==="
        dmesg | grep -i ssh | tail -5 || true
        echo "========================"
    fi
}
#!/bin/bash
#
# SSH 跳板机受限 Shell
# 只允许执行 SSH 命令，禁止其他所有操作
#

# 显示欢迎信息
echo "========================================"
echo "  EasyTier SSH Jumpserver"
echo "  受限环境 - 仅允许 SSH 命令"
echo "========================================"
echo ""

# 检查是否提供了命令
if [ $# -eq 0 ]; then
    echo "用法：ssh <目标主机>"
    echo "示例：ssh user@192.168.1.100"
    echo "      ssh -p 2222 user@example.com"
    echo ""
    echo "按 Ctrl+D 或输入 'exit' 退出"
    echo ""
    
    # 交互式模式
    while true; do
        read -p "jumpserver> " cmd
        
        # 检查是否退出
        if [ "$cmd" = "exit" ] || [ "$cmd" = "quit" ] || [ "$cmd" = "logout" ]; then
            echo "退出连接"
            exit 0
        fi
        
        # 检查是否为空
        if [ -z "$cmd" ]; then
            continue
        fi
        
        # 只允许 ssh 命令
        first_cmd=$(echo "$cmd" | awk '{print $1}')
        if [ "$first_cmd" != "ssh" ]; then
            echo "❌ 错误：只允许执行 ssh 命令"
            echo "   示例：ssh user@hostname"
            continue
        fi
        
        # 执行 SSH 命令
        echo "正在执行：$cmd"
        eval "$cmd"
        echo ""
    done
else
    # 直接执行模式（SSH 强制命令）
    first_cmd=$(echo "$1" | awk '{print $1}')
    
    if [ "$first_cmd" = "ssh" ]; then
        # 允许执行 SSH
        exec "$@"
    else
        echo "❌ 错误：跳板机只允许执行 SSH 命令" >&2
        exit 1
    fi
fi

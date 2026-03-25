#!/bin/bash
#
# SSH 跳板机受限 Shell
# 只允许执行 SSH 命令和查看系统状态（只读）
#

# 显示欢迎信息
echo "========================================"
echo "  EasyTier SSH Jumpserver"
echo "  受限环境 - 仅允许 SSH 命令和状态查看"
echo "========================================"
echo ""

# 定义只读命令白名单
readonly COMMANDS=(
    "ssh"
    "ping"
    "top"
    "ps"
    "free"
    "df"
    "uptime"
    "w"
    "who"
    "date"
    "uname"
    "hostname"
    "netstat"
    "ss"
    "ip"
    "ifconfig"
    "cat /etc/os-release"
    "cat /proc/cpuinfo"
    "cat /proc/meminfo"
    "cat /proc/uptime"
    "cat /proc/loadavg"
)

# 检查命令是否在白名单中
is_allowed() {
    local cmd="$1"
    local base_cmd=$(basename "$cmd" | awk '{print $1}')
    
    # 检查是否是基础命令
    for allowed in "${COMMANDS[@]}"; do
        if [ "$base_cmd" = "$allowed" ]; then
            return 0
        fi
    done
    
    # 特殊处理：允许 cat 查看特定的只读文件
    if [[ "$cmd" == "cat /etc/os-release" ]] || \
       [[ "$cmd" == "cat /proc/"* ]] || \
       [[ "$cmd" == "cat /sys/"* ]]; then
        return 0
    fi
    
    return 1
}

# 检查是否提供了命令
if [ $# -eq 0 ]; then
    echo "可用命令:"
    echo "  SSH 连接:"
    echo "    ssh <目标主机>              # SSH 连接到目标服务器"
    echo "    ssh user@hostname           # 指定用户"
    echo "    ssh -p 2222 user@host       # 指定端口"
    echo ""
    echo "  系统状态（只读）:"
    echo "    ping <主机>                 # 测试网络连通性"
    echo "    top                         # 查看进程状态"
    echo "    ps aux                      # 查看进程列表"
    echo "    free -h                     # 查看内存使用"
    echo "    df -h                       # 查看磁盘使用"
    echo "    uptime                      # 查看运行时间"
    echo "    w / who                     # 查看在线用户"
    echo "    netstat / ss                # 查看网络连接"
    echo "    ip addr / ifconfig          # 查看网络接口"
    echo ""
    echo "  系统信息（只读）:"
    echo "    uname -a                    # 查看系统信息"
    echo "    hostname                    # 查看主机名"
    echo "    cat /etc/os-release         # 查看系统版本"
    echo "    cat /proc/cpuinfo           # 查看 CPU 信息"
    echo "    cat /proc/meminfo           # 查看内存信息"
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
        
        # 检查是否在白名单中
        if is_allowed "$cmd"; then
            # 执行命令
            eval "$cmd"
        else
            echo "❌ 错误：不允许的命令"
            echo "   请输入 'help' 查看可用命令"
        fi
        echo ""
    done
else
    # 直接执行模式（SSH 强制命令）
    first_cmd=$(echo "$1" | awk '{print $1}')
    
    # 组合所有参数
    full_cmd="$*"
    
    if is_allowed "$full_cmd"; then
        # 允许执行
        exec "$@"
    else
        echo "❌ 错误：跳板机只允许执行 SSH 命令和系统状态查看命令" >&2
        echo "   可用命令：ssh, ping, top, ps, free, df, uptime, netstat, ss, ip 等" >&2
        exit 1
    fi
fi

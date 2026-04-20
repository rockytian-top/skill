#!/bin/bash
# rocky-know-how generate.sh v1.0
# 从解决方案生成可执行脚本
# 用法: bash generate.sh "解决方案内容" --type <类型>

set -e

VERSION="1.0.0"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
SCRIPTS_DIR="$STATE_DIR/.learnings/scripts"

# 获取状态目录
get_state_dir() {
  if [ -n "$OPENCLAW_STATE_DIR" ]; then
    echo "$OPENCLAW_STATE_DIR"
  else
    echo "$HOME/.openclaw"
  fi
}

STATE_DIR=$(get_state_dir)
SCRIPTS_DIR="$STATE_DIR/.learnings/scripts"

# 创建脚本目录
mkdir -p "$SCRIPTS_DIR"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 使用说明
usage() {
    cat << EOF
rocky-know-how generate.sh v$VERSION

从解决方案生成可执行脚本

用法:
    bash generate.sh "解决方案" --type <类型> [--name <名称>]
    bash generate.sh "解决方案" --type <类型> --preview

参数:
    解决方案      问题的解决方案描述
    --type        脚本类型 (ssh/mysql/system/deploy/generic)
    --name        脚本名称 (可选，默认自动生成)
    --preview     仅预览，不保存

示例:
    bash generate.sh "内存不足，卸载BT-Panel后恢复" --type ssh
    bash generate.sh "数据库连接慢，加索引" --type mysql --preview
EOF
}

# 生成脚本内容
generate_script() {
    local solution="$1"
    local type="$2"
    local name="$3"
    local content=""
    
    # 根据类型生成脚本
    case "$type" in
        ssh)
            content="#!/bin/bash
# SSH修复脚本
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 解决方案: ${solution:0:50}...

set -e

echo \"=== SSH修复开始 ===

\"

# 1. 检查SSH服务状态
echo \"[1/5] 检查SSH服务状态...\"
sudo systemctl status sshd 2>/dev/null || sudo systemctl status ssh 2>/dev/null || echo \"无法获取SSH状态\"

# 2. 检查内存使用
echo \"[2/5] 检查内存使用...\"
free -h

# 3. 检查SSH连接数
echo \"[3/5] 检查SSH连接数...\"
who | wc -l
connections=\$(who | wc -l)
if [ \$connections -gt 10 ]; then
    echo \"警告: 当前有 \$connections 个SSH连接\"
fi

# 4. 检查SSH配置文件
echo \"[4/5] 检查SSH配置...\"
if [ -f /etc/ssh/sshd_config ]; then
    echo \"SSH配置文件: /etc/ssh/sshd_config\"
fi

# 5. 建议操作
echo \"[5/5] 建议操作...\"
echo \"如果内存不足，考虑:\"
echo \"  - 清理不必要的进程\"
echo \"  - 卸载占用内存大的软件 (如BT-Panel)\"
echo \"  - 增加Swap空间\"

echo \"\"
echo \"=== SSH修复完成 ===
如果问题仍存在，请进一步排查日志: journalctl -u sshd\"
"
            ;;
        mysql)
            content="#!/bin/bash
# MySQL修复脚本
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 解决方案: ${solution:0:50}...

set -e

echo \"=== MySQL修复开始 ===

\"

# 1. 检查MySQL服务状态
echo \"[1/5] 检查MySQL服务状态...\"
sudo systemctl status mysql 2>/dev/null || sudo systemctl status mysqld 2>/dev/null || echo \"无法获取MySQL状态\"

# 2. 检查MySQL连接
echo \"[2/5] 检查MySQL连接...\"
mysql -e \"SHOW STATUS LIKE 'Threads_connected';\" 2>/dev/null || echo \"无法连接MySQL\"

# 3. 检查慢查询日志
echo \"[3/5] 检查慢查询日志配置...\"
mysql -e \"SHOW VARIABLES LIKE 'slow_query_log%';\" 2>/dev/null || echo \"无法获取慢查询配置\"

# 4. 检查索引情况
echo \"[4/5] 检查建议...\"
echo \"解决方案: ${solution}\"
echo \"建议执行:\"
echo \"  - 检查慢查询日志\"
echo \"  - 为常用查询字段添加索引\"
echo \"  - 使用 EXPLAIN 分析查询\"

# 5. 优化建议
echo \"[5/5] 优化建议...\"
echo \"查看慢查询: mysql -e 'SHOW GLOBAL STATUS LIKE \\\"Slow_queries\\\"';\"
echo \"查看进程:   mysql -e 'SHOW PROCESSLIST;';\"

echo \"\"
echo \"=== MySQL修复完成 ===
如需进一步帮助，请提供具体的慢查询语句\"
"
            ;;
        system)
            content="#!/bin/bash
# 系统修复脚本
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 解决方案: ${solution:0:50}...

set -e

echo \"=== 系统修复开始 ===

\"

# 1. 检查系统负载
echo \"[1/5] 检查系统负载...\"
uptime

# 2. 检查内存使用
echo \"[2/5] 检查内存使用...\"
free -h
echo \"\"
cat /proc/meminfo | grep -E \"MemTotal|MemFree|MemAvailable\" | head -3

# 3. 检查CPU使用
echo \"[3/5] 检查CPU使用...\"
top -bn1 | head -5

# 4. 检查磁盘空间
echo \"[4/5] 检查磁盘空间...\"
df -h | grep -E \"^/dev|Filesystem\"

# 5. 解决方案
echo \"[5/5] 解决方案...\"
echo \"${solution}\"

echo \"\"
echo \"=== 系统修复完成 ===
如需进一步帮助，请提供完整的系统信息\"
"
            ;;
        deploy)
            content="#!/bin/bash
# 部署脚本
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 解决方案: ${solution:0:50}...

set -e

echo \"=== 部署开始 ===

\"

# 1. 备份
echo \"[1/4] 备份当前版本...\"
backup_dir=\"/tmp/backup_\$(date +%Y%m%d_%H%M%S)\"
mkdir -p \"\$backup_dir\"
echo \"备份目录: \$backup_dir\"

# 2. 部署
echo \"[2/4] 执行部署...\"
echo \"解决方案: ${solution}\"

# 3. 验证
echo \"[3/4] 验证部署...\"
echo \"验证命令待添加\"

# 4. 完成
echo \"[4/4] 部署完成\"

echo \"\"
echo \"=== 部署完成 ===
请检查服务是否正常运行\"
"
            ;;
        *)
            content="#!/bin/bash
# 通用修复脚本
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 解决方案: ${solution:0:100}...

set -e

echo \"=== 修复开始 ===

\"

echo \"问题描述: ${problem:-未知}\"
echo \"解决方案: ${solution}\"

echo \"\"
echo \"=== 修复完成 ===
如需调整，请修改此脚本\"
"
            ;;
    esac
    
    echo "$content"
}

# 主逻辑
main() {
    local solution=""
    local type="generic"
    local name=""
    local preview=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type)
                type="$2"
                shift 2
                ;;
            --name)
                name="$2"
                shift 2
                ;;
            --preview)
                preview=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                if [[ -z "$solution" ]]; then
                    solution="$1"
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "$solution" ]]; then
        log_error "请提供解决方案内容"
        usage
        exit 1
    fi
    
    # 生成脚本名称
    if [[ -z "$name" ]]; then
        # 从解决方案提取关键词生成名称
        local keywords=$(echo "$solution" | grep -oE '[a-zA-Z]+' | head -3 | tr '[:upper:]' '[:lower:]' | tr '\n' '-' | sed 's/-$//')
        name="fix-$(echo "$keywords" | cut -c1-30)"
    fi
    
    # 生成脚本
    local script_content=$(generate_script "$solution" "$type" "$name")
    
    if $preview; then
        echo "=== 预览: ${name}.sh ==="
        echo "$script_content"
        echo ""
        log_info "预览模式，未保存"
    else
        # 保存脚本
        local script_path="$SCRIPTS_DIR/${name}.sh"
        echo "$script_content" > "$script_path"
        chmod +x "$script_path"
        
        echo ""
        log_info "脚本已保存: $script_path"
        echo ""
        echo "$script_content"
    fi
}

main "$@"

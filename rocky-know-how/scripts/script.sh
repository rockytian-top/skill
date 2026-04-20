#!/bin/bash
# rocky-know-how script.sh v1.0
# 脚本管理：创建、执行、列出、搜索
# 用法: bash script.sh <command> [args]

set -e

VERSION="1.0.0"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"

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
EXPERIENCES_FILE="$STATE_DIR/.learnings/experiences.json"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 使用说明
usage() {
    cat << EOF
rocky-know-how script.sh v$VERSION

脚本管理命令

用法:
    bash script.sh create-from-exp <exp_id> [--type <类型>]
    bash script.sh exec-from-exp <exp_id>
    bash script.sh exec <script_name>
    bash script.sh list
    bash script.sh search "<关键词>"
    bash script.sh show <script_name>
    bash script.sh delete <script_name>
    bash script.sh link <exp_id> <script_name>

示例:
    bash script.sh create-from-exp EXP-20260420-001 --type ssh
    bash script.sh exec-from-exp EXP-20260420-001
    bash script.sh list
    bash script.sh search "SSH 超时"
    bash script.sh show ssh-fix.sh

EOF
}

# 读取经验
read_exp() {
    local exp_id="$1"
    if [ ! -f "$EXPERIENCES_FILE" ]; then
        echo "{}"
        return
    fi
    grep -o "\"$exp_id\"[^}]*}" "$EXPERIENCES_FILE" 2>/dev/null || echo "{}"
}

# 获取经验总数
get_exp_count() {
    if [ ! -f "$EXPERIENCES_FILE" ]; then
        echo "0"
        return
    fi
    grep -o '"id":' "$EXPERIENCES_FILE" | wc -l
}

# 创建脚本目录
init() {
    mkdir -p "$SCRIPTS_DIR"
    chmod 755 "$SCRIPTS_DIR"
    if [ ! -f "$EXPERIENCES_FILE" ]; then
        echo '{"experiences":[]}' > "$EXPERIENCES_FILE"
    fi
}

# 从经验创建脚本
cmd_create_from_exp() {
    local exp_id=""
    local type="generic"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type)
                type="$2"
                shift 2
                ;;
            *)
                exp_id="$1"
                shift
                ;;
        esac
    done
    
    if [ -z "$exp_id" ]; then
        log_error "请提供经验ID"
        exit 1
    fi
    
    # 读取经验 - 支持 entries 结构
    local solution=$(python3 -c "
import json
with open('$EXPERIENCES_FILE', 'r') as f:
    data = json.load(f)
# 支持 entries 结构
entries = data.get('entries', data.get('experiences', []))
if isinstance(entries, dict):
    exp = entries.get('$exp_id', {})
else:
    exp = {}
    for e in entries:
        if e.get('id') == '$exp_id':
            exp = e
            break
print(exp.get('solution', '') or exp.get('SOLUTION', ''))
" 2>/dev/null || echo "")
    
    if [ -z "$solution" ]; then
        log_error "未找到经验: $exp_id 或 solution 为空"
        exit 1
    fi
    
    # 生成脚本
    local script_name="exp-${exp_id##*-}"
    log_info "正在生成脚本: $script_name.sh"
    log_info "解决方案: ${solution:0:50}..."
    
    bash "$SKILL_DIR/generate.sh" "$solution" --type "$type" --name "$script_name"
    
    # 更新经验记录
    local script_path="$SCRIPTS_DIR/${script_name}.sh"
    if [ -f "$script_path" ]; then
        # 更新JSON - 支持 entries 结构
        python3 << PYEOF
import json

exp_id = "$exp_id"
script_path = "$script_path"
script_name = "${script_name}.sh"
script_type = "$type"
exp_file = "$EXPERIENCES_FILE"

with open(exp_file, 'r') as f:
    data = json.load(f)

entries = data.get('entries', data.get('experiences', []))
if isinstance(entries, dict) and exp_id in entries:
    entries[exp_id]['script'] = script_path
    entries[exp_id]['scriptName'] = script_name
    entries[exp_id]['scriptType'] = script_type
    print(f"updated: {exp_id}")
else:
    if isinstance(entries, list):
        for exp in entries:
            if exp.get('id') == exp_id:
                exp['script'] = script_path
                exp['scriptName'] = script_name
                exp['scriptType'] = script_type
                print(f"updated: {exp_id}")
                break

with open(exp_file, 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
PYEOF
        
        log_info "经验 $exp_id 已关联脚本: $script_path"
    fi
}

# 执行经验对应的脚本
cmd_exec_from_exp() {
    local exp_id="$1"
    
    if [ -z "$exp_id" ]; then
        log_error "请提供经验ID"
        exit 1
    fi
    
    # 读取经验 - 支持 entries 结构
    local script=$(python3 -c "
import json
with open('$EXPERIENCES_FILE', 'r') as f:
    data = json.load(f)
entries = data.get('entries', data.get('experiences', []))
if isinstance(entries, dict):
    exp = entries.get('$exp_id', {})
else:
    exp = {}
    for e in entries:
        if e.get('id') == '$exp_id':
            exp = e
            break
print(exp.get('script', '') or exp.get('SCRIPT', ''))
" 2>/dev/null || echo "")
    
    if [ -z "$script" ]; then
        log_error "经验 $exp_id 没有关联脚本"
        log_info "使用 create-from-exp 创建脚本"
        exit 1
    fi
    
    if [ ! -f "$script" ]; then
        log_error "脚本不存在: $script"
        exit 1
    fi
    
    log_info "执行经验 $exp_id 的脚本..."
    echo ""
    bash "$script"
}

# 执行指定脚本
cmd_exec() {
    local script_name="$1"
    local script_path="$SCRIPTS_DIR/${script_name}.sh"
    
    if [ ! -f "$script_path" ]; then
        log_error "脚本不存在: $script_name"
        log_info "可用脚本: $(basename -a $SCRIPTS_DIR/*.sh 2>/dev/null | tr '\n' ' ')"
        exit 1
    fi
    
    log_info "执行脚本: $script_name"
    echo ""
    bash "$script_path"
}

# 列出所有脚本
cmd_list() {
    log_info "脚本目录: $SCRIPTS_DIR"
    echo ""
    
    if [ ! -d "$SCRIPTS_DIR" ] || [ -z "$(ls -A $SCRIPTS_DIR 2>/dev/null)" ]; then
        log_warn "暂无脚本"
        return
    fi
    
    echo -e "${BLUE}可用脚本:${NC}"
    echo ""
    
    for script in "$SCRIPTS_DIR"/*.sh; do
        if [ -f "$script" ]; then
            local name=$(basename "$script" .sh)
            local lines=$(wc -l < "$script")
            local modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$script" 2>/dev/null || stat -c "%y" "$script" 2>/dev/null | cut -d' ' -f1)
            echo -e "  ${GREEN}$name${NC}"
            echo "    路径: $script"
            echo "    行数: $lines | 修改: $modified"
            echo ""
        fi
    done
}

# 搜索脚本
cmd_search() {
    local keyword="$1"
    
    if [ -z "$keyword" ]; then
        log_error "请提供搜索关键词"
        exit 1
    fi
    
    log_info "搜索关键词: $keyword"
    echo ""
    
    # 搜索脚本文件
    local results=$(grep -l "$keyword" "$SCRIPTS_DIR"/*.sh 2>/dev/null || echo "")
    
    if [ -z "$results" ]; then
        log_warn "未找到匹配的脚本"
    else
        echo -e "${BLUE}匹配的脚本:${NC}"
        for result in $results; do
            local name=$(basename "$result" .sh)
            echo -e "  ${GREEN}$name${NC}"
            grep -n "$keyword" "$result" | head -2 | sed 's/^/    /'
            echo ""
        done
    fi
    
    # 同时搜索经验
    if [ -f "$EXPERIENCES_FILE" ]; then
        local exp_results=$(python3 -c "
import json
with open('$EXPERIENCES_FILE', 'r') as f:
    data = json.load(f)
entries = data.get('entries', data.get('experiences', {}))
if isinstance(entries, dict):
    for exp_id, exp in entries.items():
        if '$keyword' in exp.get('problem', '') or '$keyword' in exp.get('solution', ''):
            script = exp.get('scriptName', '(无脚本)')
            print(f'  {exp_id}: {exp.get("problem", "")[:40]}... [{script}]')
else:
    for exp in entries:
        if '$keyword' in exp.get('problem', '') or '$keyword' in exp.get('solution', ''):
            script = exp.get('scriptName', '(无脚本)')
            print(f'  {exp.get("id")}: {exp.get("problem", "")[:40]}... [{script}]')
" 2>/dev/null || echo "")
        
        if [ -n "$exp_results" ]; then
            echo -e "${BLUE}匹配的经验:${NC}"
            echo "$exp_results"
        fi
    fi
}

# 显示脚本内容
cmd_show() {
    local script_name="$1"
    local script_path="$SCRIPTS_DIR/${script_name}.sh"
    
    if [ ! -f "$script_path" ]; then
        log_error "脚本不存在: $script_name"
        exit 1
    fi
    
    echo -e "${BLUE}=== $script_name.sh ===${NC}"
    echo ""
    cat "$script_path"
}

# 删除脚本
cmd_delete() {
    local script_name="$1"
    local script_path="$SCRIPTS_DIR/${script_name}.sh"
    
    if [ ! -f "$script_path" ]; then
        log_error "脚本不存在: $script_name"
        exit 1
    fi
    
    log_warn "确定要删除 $script_name 吗？此操作不可恢复"
    read -p "输入 y 确认: " confirm
    
    if [ "$confirm" = "y" ]; then
        rm "$script_path"
        log_info "已删除: $script_name"
    else
        log_info "取消删除"
    fi
}

# 关联经验和脚本
cmd_link() {
    local exp_id="$1"
    local script_name="$2"
    local script_path="$SCRIPTS_DIR/${script_name}.sh"
    
    if [ ! -f "$script_path" ]; then
        log_error "脚本不存在: $script_name"
        exit 1
    fi
    
    local tmp_file="/tmp/update_exp_$$.json"
    python3 -c "
import json

with open('$EXPERIENCES_FILE', 'r') as f:
    data = json.load(f)

for exp in data.get('experiences', []):
    if exp.get('id') == '$exp_id':
        exp['script'] = '$script_path'
        exp['scriptName'] = '${script_name}.sh'
        print(f\"已关联: \$exp_id -> $script_name\")
        break
else:
    print('未找到经验: $exp_id')

with open('$tmp_file', 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
" 2>/dev/null && mv "$tmp_file" "$EXPERIENCES_FILE"
}

# 主逻辑
main() {
    init
    
    if [ $# -eq 0 ]; then
        usage
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        create-from-exp)
            cmd_create_from_exp "$@"
            ;;
        exec-from-exp)
            cmd_exec_from_exp "$@"
            ;;
        exec)
            cmd_exec "$@"
            ;;
        list)
            cmd_list
            ;;
        search)
            cmd_search "$@"
            ;;
        show)
            cmd_show "$@"
            ;;
        delete)
            cmd_delete "$@"
            ;;
        link)
            cmd_link "$@"
            ;;
        --help|-h)
            usage
            ;;
        *)
            log_error "未知命令: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"

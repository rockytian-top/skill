#!/bin/bash
# rocky-know-how generate.sh v2.0
# 用AI从解决方案生成可执行脚本
# 用法: bash generate.sh "解决方案内容" --type <类型>

set -e

VERSION="2.0.0"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw-gateway2}"
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

# 调用LLM生成修复脚本（用Python调用）
generate_with_ai() {
    local solution="$1"
    local script_type="$2"
    
    python3 - "$solution" "$script_type" << 'PYEOF'
import subprocess
import json
import sys

solution = sys.argv[1]
script_type = sys.argv[2] if len(sys.argv) > 2 else "auto"

prompt = f"""根据以下解决方案生成一个bash修复脚本。

解决方案: {solution}
脚本类型: {script_type}

要求：
1. 只输出脚本内容，开头要有 #!/bin/bash
2. 使用set -e
3. 包含步骤echo输出
4. 根据解决方案生成针对性的修复命令
5. 不要使用通用模板，要针对具体问题"""

payload = {
    "model": "lingshu-7b",
    "messages": [
        {"role": "system", "content": "你是一个专业的Shell脚本生成器。根据用户描述的问题和解决方案，生成一个可执行的bash修复脚本。只输出脚本内容，不要其他解释。"},
        {"role": "user", "content": prompt}
    ],
    "temperature": 0.2,
    "max_tokens": 800
}

try:
    result = subprocess.run(
        ["curl", "-s", "-X", "POST", "http://localhost:1234/v1/chat/completions",
         "-H", "Content-Type: application/json",
         "-d", json.dumps(payload)],
        capture_output=True, text=True, timeout=30
    )
    data = json.loads(result.stdout)
    content = data.get('choices', [{}])[0].get('message', {}).get('content', '')
    # 清理markdown代码块
    content = content.replace('```bash', '').replace('```', '').strip()
    print(content)
except Exception as e:
    print('')
PYEOF
}

# 生成脚本名称
generate_name() {
    local solution="$1"
    local keywords=$(echo "$solution" | grep -oE '[a-zA-Z]+' | head -3 | tr '[:upper:]' '[:lower:]' | tr '\n' '-' | sed 's/-$//')
    echo "fix-$(echo "$keywords" | cut -c1-30)"
}

# 使用说明
usage() {
    cat << EOF
rocky-know-how generate.sh v$VERSION

用法:
    bash generate.sh "解决方案" --type <类型> [--name <名称>]
    bash generate.sh "解决方案" --type <类型> --preview
EOF
}

# 主逻辑
main() {
    local solution=""
    local type="auto"
    local name=""
    local preview=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type) type="$2"; shift 2 ;;
            --name) name="$2"; shift 2 ;;
            --preview) preview=true; shift ;;
            --help|-h) usage; exit 0 ;;
            *) [[ -z "$solution" ]] && solution="$1"; shift ;;
        esac
    done
    
    if [[ -z "$solution" ]]; then
        log_error "请提供解决方案内容"
        exit 1
    fi
    
    log_info "正在用AI生成修复脚本..."
    
    # 用AI生成
    local script_content=$(generate_with_ai "$solution" "$type")
    
    if [[ -z "$script_content" ]]; then
        log_warn "AI生成失败，使用通用模板"
        script_content="#!/bin/bash
# 修复脚本
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 解决方案: ${solution:0:100}...

set -e

echo \"=== 修复开始 ===\"
echo \"解决方案: $solution\"
echo \"=== 修复完成 ===\""
    fi
    
    [[ -z "$name" ]] && name=$(generate_name "$solution")
    
    if $preview; then
        echo "=== 预览: ${name}.sh ==="
        echo "$script_content"
    else
        local script_path="$SCRIPTS_DIR/${name}.sh"
        echo "$script_content" > "$script_path"
        chmod +x "$script_path"
        log_info "脚本已保存: $script_path"
        echo ""
        echo "$script_content"
    fi
}

main "$@"

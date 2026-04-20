#!/bin/bash
# decision.sh - 决策记录管理 v3.0
# 用法: 
#   bash decision.sh add "问题" "选项A" "选项B" "决策" "原因" "决策者"
#   bash decision.sh list
#   bash decision.sh show <ID>
#   bash decision.sh search <关键词>

VERSION="3.0"

# 动态获取状态目录
get_state_dir() {
    if [ -n "$OPENCLAW_STATE_DIR" ]; then
        echo "$OPENCLAW_STATE_DIR"
    else
        echo "$HOME/.openclaw"
    fi
}

STATE_DIR=$(get_state_dir)
DECISIONS_FILE="$STATE_DIR/.learnings/decisions.md"
DECISIONS_JSON="$STATE_DIR/.learnings/decisions.json"

# 确保目录存在
mkdir -p "$STATE_DIR/.learnings"

# 初始化文件
init_files() {
    if [ ! -f "$DECISIONS_FILE" ]; then
        cat > "$DECISIONS_FILE" << 'EOF'
# 决策记录 / Decision Log

> 记录团队重要决策及原因，便于追溯和复盘

---

EOF
    fi
    
    if [ ! -f "$DECISIONS_JSON" ]; then
        echo '{"version": "3.0", "decisions": {}, "lastUpdate": ""}' > "$DECISIONS_JSON"
    fi
}

# 生成ID
generate_id() {
    date +%Y%m%d-%H%M%S
}

# 添加决策
add_decision() {
    local problem="$1"
    local options="$2"  # JSON数组格式: '["选项A","选项B"]'
    local decision="$3"
    local reason="$4"
    local decider="${5:-unknown}"
    
    init_files
    
    local id="DEC-$(generate_id)"
    local date="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # 解析选项
    local options_md=""
    local count=1
    echo "$options" | python3 -c "
import json, sys
options = json.loads(sys.stdin.read())
for i, opt in enumerate(options):
    print(f'  - {chr(65+i)}. {opt}')
" > /tmp/dec_options.txt 2>/dev/null || options_md="  - $options"
    
    options_md=$(cat /tmp/dec_options.txt 2>/dev/null || echo "  - $options")
    
    # 更新markdown
    cat >> "$DECISIONS_FILE" << EOF

## [$id] $problem

**状态**: 有效
**日期**: $date
**决策者**: $decider

### 问题
$problem

### 选项
$options_md

### 决策
$decision

### 原因
$reason

---

EOF
    
    # 更新JSON
    python3 - "$DECISIONS_FILE" "$DECISIONS_JSON" "$id" "$problem" "$decision" "$reason" "$decider" "$date" << 'PYEOF'
import json
import sys

md_file = sys.argv[1]
json_file = sys.argv[2]
dec_id = sys.argv[3]
problem = sys.argv[4]
decision = sys.argv[5]
reason = sys.argv[6]
decider = sys.argv[7]
date = sys.argv[8]

# 读取现有JSON
try:
    with open(json_file, 'r') as f:
        data = json.load(f)
except:
    data = {"version": "3.0", "decisions": {}, "lastUpdate": ""}

# 添加新决策
data["decisions"][dec_id] = {
    "id": dec_id,
    "problem": problem,
    "decision": decision,
    "reason": reason,
    "decider": decider,
    "date": date,
    "status": "active",
    "links": []
}

data["lastUpdate"] = date

# 写入
with open(json_file, 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"决策已添加: {dec_id}")
PYEOF
    
    echo "✅ 决策已添加: $id"
}

# 列出所有决策
list_decisions() {
    init_files
    
    echo "=== 决策列表 ==="
    
    python3 - "$DECISIONS_JSON" << 'PYEOF'
import json
import sys

json_file = sys.argv[1]
try:
    with open(json_file, 'r') as f:
        data = json.load(f)
except:
    print("暂无决策记录")
    sys.exit(0)

decisions = data.get("decisions", {})
if not decisions:
    print("暂无决策记录")
    sys.exit(0)

for dec_id, dec in sorted(decisions.items(), key=lambda x: x[1].get("date", ""), reverse=True):
    status_icon = "✅" if dec.get("status") == "active" else "❌"
    print(f"{status_icon} {dec_id}")
    print(f"   问题: {dec.get('problem', '')[:50]}")
    print(f"   决策: {dec.get('decision', '')}")
    print(f"   日期: {dec.get('date', '')}")
    print()
PYEOF
}

# 显示单个决策
show_decision() {
    local id="$1"
    
    init_files
    
    python3 - "$DECISIONS_FILE" "$id" << 'PYEOF'
import sys

md_file = sys.argv[1]
dec_id = sys.argv[2]

with open(md_file, 'r') as f:
    content = f.read()

# 简单解析
in_section = False
lines_to_print = []
current_h2 = ""

for line in content.split('\n'):
    if line.startswith('## [') and dec_id in line:
        in_section = True
        current_h2 = line
    elif line.startswith('## [') and in_section:
        break
    elif in_section:
        lines_to_print.append(line)

if lines_to_print:
    print('\n'.join(lines_to_print))
else:
    print(f"未找到决策: {dec_id}")
PYEOF
}

# 搜索决策
search_decisions() {
    local keyword="$1"
    
    init_files
    
    python3 - "$DECISIONS_JSON" "$keyword" << 'PYEOF'
import json
import sys

json_file = sys.argv[1]
keyword = sys.argv[2].lower()

try:
    with open(json_file, 'r') as f:
        data = json.load(f)
except:
    print("暂无决策记录")
    sys.exit(0)

decisions = data.get("decisions", {})
matches = []

for dec_id, dec in decisions.items():
    if (keyword in dec.get('problem', '').lower() or 
        keyword in dec.get('decision', '').lower() or
        keyword in dec.get('reason', '').lower()):
        matches.append((dec_id, dec))

if not matches:
    print(f"未找到包含 '{keyword}' 的决策")
else:
    print(f"找到 {len(matches)} 条相关决策：\n")
    for dec_id, dec in matches:
        print(f"✅ {dec_id}")
        print(f"   问题: {dec.get('problem', '')[:50]}")
        print(f"   决策: {dec.get('decision', '')}")
        print()
PYEOF
}

# 主逻辑
case "${1:-}" in
    add)
        if [ $# -lt 5 ]; then
            echo "用法: decision.sh add \"问题\" '[\"选项A\",\"选项B\"]' \"决策\" \"原因\" [决策者]"
            exit 1
        fi
        add_decision "$2" "$3" "$4" "$5" "$6"
        ;;
    list)
        list_decisions
        ;;
    show)
        if [ -z "$2" ]; then
            echo "用法: decision.sh show <ID>"
            exit 1
        fi
        show_decision "$2"
        ;;
    search)
        if [ -z "$2" ]; then
            echo "用法: decision.sh search <关键词>"
            exit 1
        fi
        search_decisions "$2"
        ;;
    *)
        echo "decision.sh v${VERSION} - 决策记录管理"
        echo ""
        echo "用法:"
        echo "  decision.sh add \"问题\" '[\"选项A\",\"选项B\"]' \"决策\" \"原因\" [决策者]"
        echo "  decision.sh list"
        echo "  decision.sh show <ID>"
        echo "  decision.sh search <关键词>"
        ;;
esac

#!/bin/bash
# auto_link.sh - 自动关联知识 v3.0
# 当添加新经验时，自动链接到相关的已有知识

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
EXPERIENCES_JSON="$STATE_DIR/.learnings/experiences.json"
DECISIONS_JSON="$STATE_DIR/.learnings/decisions.json"

# 查找相关经验
find_related_experiences() {
    local new_content="$1"
    local max_results="${2:-3}"
    
    # 调用搜索脚本获取相关内容
    local results
    results=$(bash "$STATE_DIR/skills/rocky-know-how/scripts/search.sh" "$new_content" "$max_results" 2>/dev/null)
    
    # 解析搜索结果中的ID
    echo "$results" | grep "^ID:" | awk '{print $2}' | head -"$max_results"
}

# 查找相关决策
find_related_decisions() {
    local keyword="$1"
    
    if [ ! -f "$DECISIONS_JSON" ]; then
        return
    fi
    
    python3 - "$DECISIONS_JSON" "$keyword" << 'PYEOF'
import json
import sys

json_file = sys.argv[1]
keyword = sys.argv[2].lower()

try:
    with open(json_file, 'r') as f:
        data = json.load(f)
except:
    sys.exit(0)

decisions = data.get("decisions", {})
for dec_id, dec in decisions.items():
    if (keyword in dec.get('problem', '').lower() or 
        keyword in dec.get('reason', '').lower()):
        print(dec_id)
PYEOF
}

# 提取关键词
extract_keywords() {
    local content="$1"
    
    # 简单的关键词提取（基于词频）
    echo "$content" | python3 -c "
import sys
import re
from collections import Counter

text = sys.stdin.read().lower()
# 提取英文词和中文词
words = re.findall(r'[\w]+', text)
# 过滤停用词
stopwords = {'the', 'a', 'an', 'is', 'are', 'was', 'were', 'this', 'that', '的', '是', '在', '和', '了'}
words = [w for w in words if len(w) > 2 and w not in stopwords]
# 取top5
counter = Counter(words)
for word, count in counter.most_common(5):
    print(word)
" 2>/dev/null
}

# 主逻辑：自动关联
auto_link() {
    local new_exp_id="$1"
    local new_content="$2"  # 新经验的问题+解决方案
    
    echo "🔗 开始自动关联..."
    
    # 1. 提取关键词
    local keywords=$(extract_keywords "$new_content")
    echo "📌 关键词: $keywords"
    
    # 2. 查找相关经验
    echo ""
    echo "🔗 相关经验:"
    local related_exp
    related_exp=$(find_related_experiences "$new_content" 3)
    if [ -n "$related_exp" ]; then
        echo "$related_exp" | while read -r exp_id; do
            echo "   → $exp_id"
        done
    else
        echo "   (无相关经验)"
    fi
    
    # 3. 查找相关决策
    echo ""
    echo "📋 相关决策:"
    local first_keyword=$(echo "$keywords" | head -1)
    if [ -n "$first_keyword" ]; then
        local related_dec
        related_dec=$(find_related_decisions "$first_keyword")
        if [ -n "$related_dec" ]; then
            echo "$related_dec" | while read -r dec_id; do
                echo "   → $dec_id"
            done
        else
            echo "   (无相关决策)"
        fi
    else
        echo "   (无相关决策)"
    fi
    
    echo ""
    echo "✅ 自动关联完成"
}

# 列出某个经验的所有关联
show_links() {
    local exp_id="$1"
    
    if [ ! -f "$EXPERIENCES_JSON" ]; then
        echo "经验文件不存在"
        return
    fi
    
    python3 - "$EXPERIENCES_JSON" "$exp_id" << 'PYEOF'
import json
import sys

json_file = sys.argv[1]
exp_id = sys.argv[2]

try:
    with open(json_file, 'r') as f:
        data = json.load(f)
except Exception as e:
    print(f"读取失败: {e}")
    sys.exit(1)

entries = data.get("entries", {})
exp = entries.get(exp_id)

if not exp:
    print(f"未找到经验: {exp_id}")
    sys.exit(1)

print(f"经验: {exp_id}")
print(f"问题: {exp.get('problem', '')}")
print()

links = exp.get("links", [])
if links:
    print(f"关联知识 ({len(links)}):")
    for link in links:
        print(f"   → {link}")
else:
    print("关联知识: (无)")

print()
related = exp.get("related", [])
if related:
    print(f"相关经验 ({len(related)}):")
    for r in related:
        print(f"   → {r}")
else:
    print("相关经验: (无)")
PYEOF
}

# 显示用法
usage() {
    echo "auto_link.sh v${VERSION} - 自动关联知识"
    echo ""
    echo "用法:"
    echo "  auto_link.sh link <新经验ID> \"<新经验内容>\""
    echo "  auto_link.sh show <经验ID>"
    echo "  auto_link.sh keywords \"<内容>\""
}

case "${1:-}" in
    link)
        auto_link "$2" "$3"
        ;;
    show)
        show_links "$2"
        ;;
    keywords)
        extract_keywords "$2"
        ;;
    *)
        usage
        ;;
esac

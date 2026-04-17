#!/bin/bash
# rocky-know-how Tag晋升机制 v1.3.0
# 用法: promote.sh
# 检查30天内同一Tag出现≥3次，自动写入TOOLS.md
# 环境变量: WORKSPACE (由 record.sh 传入)

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
get_state_dir() { [ -n "$OPENCLAW_STATE_DIR" ] && echo "$OPENCLAW_STATE_DIR" || echo "$HOME/.openclaw"; }
STATE_DIR=$(get_state_dir)
SHARED_DIR="$STATE_DIR/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"

[ ! -f "$ERRORS_FILE" ] && echo "经验诀窍文件不存在，跳过晋升检查" && exit 0

# 动态获取 workspace 路径
if [ -n "$WORKSPACE" ]; then
  TOOLS_FILE="$WORKSPACE/TOOLS.md"
elif [ -n "$OPENCLAW_WORKSPACE" ]; then
  TOOLS_FILE="$OPENCLAW_WORKSPACE/TOOLS.md"
elif [ -n "$OPENCLAW_SESSION_KEY" ]; then
  agentId=$(echo "$OPENCLAW_SESSION_KEY" | cut -d: -f2)
  TOOLS_FILE="$STATE_DIR/workspace-${agentId}/TOOLS.md"
else
  TOOLS_FILE="$STATE_DIR/workspace/TOOLS.md"
fi

CUTOFF_DATE=$(date -v-30d +%Y%m%d 2>/dev/null || date -d "30 days ago" +%Y%m%d)
TODAY=$(date +%Y%m%d)

echo "=== Tag晋升检查 ==="
echo "检查周期: ${CUTOFF_DATE} - ${TODAY}"
echo "目标 TOOLS: $TOOLS_FILE"
echo ""

# 提取近30天的 Tags
TAGS_DATA=$(awk -v cutoff="$CUTOFF_DATE" '
  /^## \[EXP-/ {
    date = substr($0, index($0, "[EXP-") + 5, 8)
    if (date >= cutoff) {
      # 继续往后读找 Tags 行
      while (getline > 0) {
        if (/^\*\*Tags\*\*:/) {
          sub(/^\*\*Tags\*\*: /, "")
          print
          break
        }
        if (/^## \[EXP-/) break
      }
    }
  }
' "$ERRORS_FILE")

[ -z "$TAGS_DATA" ] && echo "无Tag达到晋升标准（30天内无条目）" && exit 0

# 统计 Tag 频率
echo "近期Tags统计:"
echo "$TAGS_DATA" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$' | sort | uniq -c | sort -rn

# 晋升检查
echo ""
echo "晋升检查:"
promoted=0

# 用临时文件避免管道子shell问题
TAG_COUNT_FILE="/tmp/rocky-know-how-tags-$$.txt"
echo "$TAGS_DATA" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$' | sort | uniq -c | sort -rn > "$TAG_COUNT_FILE"

while read -r count tag; do
  [ -z "$count" ] && continue
  if [ "$count" -ge 3 ]; then
    echo "🎯 晋升Tag: $tag (出现 $count 次)"
    promoted=$((promoted+1))

    # 提取该 Tag 最近一条的"正确方案"
    solution=$(grep --color=never -A20 "\\*\\*Tags\\*\\*:.*${tag}" "$ERRORS_FILE" | sed -n '/^### 正确方案$/{n;p;}' | head -1)

    if [ -n "$solution" ] && [ -f "$TOOLS_FILE" ]; then
      if grep -q --color=never "$tag.*经验诀窍" "$TOOLS_FILE" 2>/dev/null; then
        echo "   已存在于 TOOLS.md，跳过"
      else
        echo "" >> "$TOOLS_FILE"
        echo "### $tag" >> "$TOOLS_FILE"
        echo "" >> "$TOOLS_FILE"
        echo "- $solution (来源: 经验诀窍, ${count}次实战)" >> "$TOOLS_FILE"
        echo "  - 自动晋升日期: $(date '+%Y-%m-%d')" >> "$TOOLS_FILE"
        echo "✅ 已写入 TOOLS.md"
      fi
    elif [ -n "$solution" ] && [ ! -f "$TOOLS_FILE" ]; then
      echo "   ⚠️ TOOLS.md 不存在: $TOOLS_FILE，跳过写入"
    fi
  fi
done < "$TAG_COUNT_FILE"

if [ $promoted -eq 0 ]; then
  echo "无Tag达到晋升标准（需≥3次）"
fi

rm -f "$TAG_COUNT_FILE"
echo ""
echo "检查完成"

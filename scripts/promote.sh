#!/bin/bash
# rocky-know-how Tag晋升机制
# 用法: promote.sh
# 检查30天内同一Tag出现≥3次，自动写入TOOLS.md

SHARED_DIR="$HOME/.openclaw/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"

[ ! -f "$ERRORS_FILE" ] && echo "经验诀窍文件不存在，跳过晋升检查" && exit 0

TOOLS_FILE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}/TOOLS.md"

CUTOFF_DATE=$(date -v-30d +%Y%m%d 2>/dev/null || date -d "30 days ago" +%Y%m%d)
TODAY=$(date +%Y%m%d)

echo "=== Tag晋升检查 ==="
echo "检查周期: ${CUTOFF_DATE} - ${TODAY}"
echo ""

# 提取近30天的 Tags
TAGS_DATA=$(awk -v cutoff="$CUTOFF_DATE" '
  /^## \[EXP-/ {
    date = substr($0, index($0, "[EXP-") + 5, 8)
    if (date >= cutoff) {
      for (i = 1; i <= 10; i++) {
        if (/^\*\*Tags\*\*:/) {
          sub(/^\*\*Tags\*\*: /, "")
          print
          next
        }
        getline
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

grep -v '^$' "$TAG_COUNT_FILE" | while read count tag; do
  if [ "$count" -ge 3 ]; then
    echo "🎯 晋升Tag: $tag (出现 $count 次)"
    echo "promoted" >> "/tmp/rocky-know-how-promoted-$$.flag"

    # 提取该 Tag 最近一条的"正确方案"
    solution=$(grep -A20 "\\*\\*Tags\\*\\*:.*${tag}" "$ERRORS_FILE" | sed -n '/^### 正确方案$/{n;p;}' | head -1)

    if [ -n "$solution" ] && [ -f "$TOOLS_FILE" ]; then
      if grep -q "$tag.*经验诀窍" "$TOOLS_FILE" 2>/dev/null; then
        echo "   已存在于 TOOLS.md，跳过"
      else
        cat >> "$TOOLS_FILE" << EOF

### $tag

- $solution (来源: 经验诀窍, ${count}次实战)
  - 自动晋升日期: $(date '+%Y-%m-%d')

EOF
        echo "✅ 已写入 TOOLS.md"
      fi
    fi
  fi
done

if [ -f "/tmp/rocky-know-how-promoted-$$.flag" ]; then
  rm -f "/tmp/rocky-know-how-promoted-$$.flag"
else
  echo "无Tag达到晋升标准（需≥3次）"
fi
rm -f "$TAG_COUNT_FILE"
echo ""
echo "检查完成"

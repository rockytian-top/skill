#!/bin/bash
# rocky-know-how 统计面板
# 用法: stats.sh

get_state_dir() { [ -n "$OPENCLAW_STATE_DIR" ] && echo "$OPENCLAW_STATE_DIR" || echo "$HOME/.openclaw"; }
STATE_DIR=$(get_state_dir)
SHARED_DIR="$STATE_DIR/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"

echo "╔══════════════════════════════════════════╗"
echo "║     📊 经验诀窍统计面板                ║"
echo "╚══════════════════════════════════════════╝"
echo ""

[ ! -f "$ERRORS_FILE" ] && echo "经验诀窍文件不存在" && exit 0

# 总条目
total_entries=$(grep -c '^## \[EXP-' "$ERRORS_FILE" 2>/dev/null || echo "0")
echo "📚 总条目: $total_entries"

# 本月新增
current_month=$(date +%Y%m)
this_month=$(grep '^## \[EXP-' "$ERRORS_FILE" 2>/dev/null | grep -c "${current_month}" || echo "0")
echo "🆕 本月新增: $this_month"

# Area 分布
echo ""
echo "📂 Area 分布:"
echo "─────────────────────────────────"
grep '^\*\*Area\*\*:' "$ERRORS_FILE" 2>/dev/null | sed 's/^\*\*Area\*\*: //' | sort | uniq -c | sort -rn | while read count area; do
  printf "  %-15s %3d\n" "$area" "$count"
done

# Tag 分布
echo ""
echo "🏷️  Tag 分布 (Top 10):"
echo "─────────────────────────────────"
grep '^\*\*Tags\*\*:' "$ERRORS_FILE" 2>/dev/null | sed 's/^\*\*Tags\*\*: //' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$' | sort | uniq -c | sort -rn | head -10 | while read count tag; do
  bar=""
  i=1
  while [ $i -le $count ] && [ $i -le 10 ]; do
    bar="${bar}█"
    i=$((i + 1))
  done
  printf "  %-20s %3d %s\n" "$tag" "$count" "$bar"
done

# 最近条目
echo ""
echo "📝 最近条目:"
echo "─────────────────────────────────"
grep '^## \[EXP-' "$ERRORS_FILE" 2>/dev/null | tail -5 | while read line; do
  echo "  $line"
done

# 归档统计
echo ""
archive_count=$(find "$SHARED_DIR/archive" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo "📦 已归档文件: $archive_count"

echo ""
echo "💡 晋升提示: 30天内同一Tag≥3次 → 自动写入TOOLS.md"

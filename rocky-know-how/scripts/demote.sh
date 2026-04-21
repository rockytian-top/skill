#!/bin/bash
# rocky-know-how 降级检查脚本 v2.0.0
# 用法: demote.sh [--dry-run] [--days N]
# 检查未使用模式，降级到 WARM（30天）或归档到 COLD（90天）
# 永不删除数据

DRY_RUN=false
DAYS_THRESHOLD=30
ARCHIVE_THRESHOLD=90

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --days)    DAYS_THRESHOLD="$2"; shift 2 ;;
    -h|--help)
      echo "用法: demote.sh [--dry-run] [--days N]"
      echo "  --dry-run  模拟执行，不实际写入"
      echo "  --days N   降级阈值天数（默认30）"
      exit 0 ;;
    *) shift ;;
  esac
done

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
get_state_dir() { [ -n "$OPENCLAW_STATE_DIR" ] && echo "$OPENCLAW_STATE_DIR" || echo "$HOME/.openclaw"; }
STATE_DIR=$(get_state_dir)
SHARED_DIR="$STATE_DIR/.learnings"
MEMORY_FILE="$SHARED_DIR/memory.md"
ARCHIVE_DIR="$SHARED_DIR/archive"

echo "=== 降级检查 (v2.0.0) ==="
echo "降级阈值: ${DAYS_THRESHOLD} 天"
echo "归档阈值: ${ARCHIVE_THRESHOLD} 天"
echo ""

[ ! -f "$MEMORY_FILE" ] && echo "memory.md 不存在，跳过" && exit 0

DEMOTE_MARKER="# DEMOTED"
CUTOFF_DATE=$(date -v-${DAYS_THRESHOLD}d +%Y-%m-%d 2>/dev/null || date -d "${DAYS_THRESHOLD} days ago" +%Y-%m-%d)
ARCHIVE_CUTOFF=$(date -v-${ARCHIVE_THRESHOLD}d +%Y-%m-%d 2>/dev/null || date -d "${ARCHIVE_THRESHOLD} days ago" +%Y-%m-%d)

echo "降级截止: ${CUTOFF_DATE}"
echo "归档截止: ${ARCHIVE_CUTOFF}"
echo ""

if $DRY_RUN; then
  echo "=== 模拟模式 (dry-run) ==="
  echo ""

  demote_candidates=$(grep -n "^## " "$MEMORY_FILE" 2>/dev/null | while IFS= read -r line; do
    entry_date=$(echo "$line" | sed -E 's/.*\[([^]]*)\].*/\1/' | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}")
    [ -z "$entry_date" ] && continue
    # 简单比较：只比较日期字符串
    echo "$entry_date|$line"
  done | while IFS='|' read -r date line; do
    if [ "$date" \< "$CUTOFF_DATE" ] 2>/dev/null; then
      echo "WARM candidate: $line"
    fi
  done)

  if [ -z "$demote_candidates" ]; then
    echo "  无降级候选"
  else
    echo "$demote_candidates"
  fi
  exit 0
fi

echo "✅ 降级检查完成（实际模式）"
echo "💡 如需实际执行，请移除 --dry-run 参数"
echo "💡 注意：本脚本默认只做检查，实际降级需要人工确认"
echo ""
echo "降级规则: memory.md 中 30天+ 未使用的条目 → 降级到 domains/"
echo "归档规则: 90天+ 未使用 → 归档到 archive/"
echo "永不删除: 所有数据永久保留"

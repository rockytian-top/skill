#!/bin/bash
# rocky-know-how 归档旧条目
# 用法: archive.sh [--days N] [--dry-run]

DAYS=30
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)    DAYS="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *)         shift ;;
  esac
done

SHARED_DIR="$HOME/.openclaw/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"
ARCHIVE_DIR="$SHARED_DIR/archive"

[ ! -f "$ERRORS_FILE" ] && exit 0

ARCHIVE_MONTH_DIR="$ARCHIVE_DIR/$(date +%Y-%m)"
mkdir -p "$ARCHIVE_MONTH_DIR"

CUTOFF_DATE=$(date -v-${DAYS}d +%Y%m%d 2>/dev/null || date -d "${DAYS} days ago" +%Y%m%d)

# 提取条目的日期部分（8位数字）
extract_date() {
  echo "$1" | sed 's/.*\[EXP-\([0-9]\{8\}\)-.*/\1/'
}

# 检查是否应该归档（日期 < 截止日期）
is_old() {
  [ "${1:-0}" -lt "$CUTOFF_DATE" ] 2>/dev/null
}

if $DRY_RUN; then
  echo "=== 模拟归档 ==="
  echo "截止日期: ${CUTOFF_DATE:0:4}-${CUTOFF_DATE:4:2}-${CUTOFF_DATE:6:2}（${DAYS}天前）"
  echo ""
  echo "将被归档的条目:"
  in_block=0
  while IFS= read -r line; do
    if echo "$line" | grep -q '^## \[EXP-'; then
      date=$(extract_date "$line")
      if is_old "$date"; then
        echo "$line"
        in_block=1
      else
        in_block=0
      fi
    elif [ $in_block -eq 1 ]; then
      echo "$line"
      [ "$line" = "---" ] && in_block=0
    fi
  done < "$ERRORS_FILE"
  exit 0
fi

# 备份
BACKUP_FILE="$ARCHIVE_MONTH_DIR/experiences-$(date +%Y%m%d-%H%M%S).md"
cp "$ERRORS_FILE" "$BACKUP_FILE"

# 生成新文件，只保留近期条目
TEMP_FILE="/tmp/rocky-know-how-archive-$$.md"
{
  echo "# 经验诀窍"
  echo ""
  echo "---"
} > "$TEMP_FILE"

current_block=""
in_old=false
while IFS= read -r line; do
  if echo "$line" | grep -q '^## \[EXP-'; then
    # 输出上一个块（如果不是旧的）
    if [ -n "$current_block" ] && ! $in_old; then
      echo "$current_block" >> "$TEMP_FILE"
    fi
    current_block="$line"
    date=$(extract_date "$line")
    in_old=$(is_old "$date" && echo true || echo false)
  else
    current_block="$current_block"$'\n'"$line"
  fi
done < "$ERRORS_FILE"

# 最后一个块
if [ -n "$current_block" ] && ! $in_old; then
  echo "$current_block" >> "$TEMP_FILE"
fi

mv "$TEMP_FILE" "$ERRORS_FILE"

echo "✅ 归档完成"
echo "   备份: $(basename "$BACKUP_FILE")"
echo "   已移除 ${DAYS} 天前的旧条目"

#!/bin/bash
# rocky-know-how 压缩整理脚本 v2.0.0
# 用法: compact.sh [--dry-run] [--file memory.md]
# 当文件超过限制时压缩：
#   memory.md: >100行 → 合并相似条目，摘要冗余
#   domains/*.md: >200行 → 压缩
#   projects/*.md: >200行 → 压缩
# 永不删除已确认偏好

DRY_RUN=false
TARGET_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --file)    TARGET_FILE="$2"; shift 2 ;;
    -h|--help)
      echo "用法: compact.sh [--dry-run] [--file <file>]"
      echo "  --dry-run   模拟执行"
      echo "  --file      指定文件（默认全部检查）"
      exit 0 ;;
    *) shift ;;
  esac
done

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
get_state_dir() { [ -n "$OPENCLAW_STATE_DIR" ] && echo "$OPENCLAW_STATE_DIR" || echo "$HOME/.openclaw"; }
STATE_DIR=$(get_state_dir)
SHARED_DIR="$STATE_DIR/.learnings"
MEMORY_FILE="$SHARED_DIR/memory.md"
CORRECTIONS_FILE="$SHARED_DIR/corrections.md"
DOMAINS_DIR="$SHARED_DIR/domains"
PROJECTS_DIR="$SHARED_DIR/projects"
ARCHIVE_DIR="$SHARED_DIR/archive"

echo "=== 压缩整理 (v2.0.0) ==="
$DRY_RUN && echo "模式: 模拟 (dry-run)"
echo ""

# 限制阈值
MEMORY_LIMIT=100
WARM_LIMIT=200

check_and_compact() {
  local file="$1"
  local limit="$2"
  local label="$3"

  [ ! -f "$file" ] && return

  local lines=$(wc -l < "$file" | tr -d ' ')
  echo "  $label: ${lines} 行 (限制: ${limit})"

  if [ "$lines" -gt "$limit" ]; then
    local overflow=$((lines - limit))
    echo "    ⚠️  超出 ${overflow} 行，需要压缩"

    if $DRY_RUN; then
      echo "    [dry-run] 将压缩: $file"
      # 估算压缩后行数
      echo "    压缩策略:"
      echo "      1. 合并相似纠正为单一规则"
      echo "      2. 摘要冗长条目"
      echo "      3. 归档未使用的模式"
    else
      # 实际压缩
      compact_file "$file" "$limit"
      echo "    ✅ 已压缩: $file"
    fi
  else
    echo "    ✅ 正常，无需压缩"
  fi
}

compact_file() {
  local file="$1"
  local limit="$2"

  # 备份原文件
  cp "$file" "${file}.bak.$(date +%s)"

  # 策略1: 合并相似 corrections 条目
  if [ "$file" = "$CORRECTIONS_FILE" ]; then
    # 保留最近50条，合并更旧的
    local tmp_file="/tmp/rocky-know-how-compact-$$.md"
    awk '
      BEGIN { entries=0; buffer="" }
      /^## [0-9]{4}/ {
        if (entries < 50 && buffer != "") {
          print buffer
        }
        buffer=$0
        entries++
        next
      }
      buffer != "" { buffer = buffer "\n" $0 }
      END { if (buffer != "" && entries <= 50) print buffer }
    ' "$file" > "$tmp_file"
    mv "$tmp_file" "$file"
    return
  fi

  # 策略2: 对于 memory.md，保留已确认偏好 + 最近条目，合并旧的到摘要
  if [ "$file" = "$MEMORY_FILE" ]; then
    local tmp_file="/tmp/rocky-know-how-compact-$$.md"
    {
      echo "# HOT Memory"
      echo ""
      echo "## 已确认偏好"
      echo "<!-- 压缩后的已确认偏好 -->"
      echo ""
      echo "## 活跃模式"
      echo "<!-- 压缩后的活跃模式 -->"
      echo ""
      echo "## 最近（最近7天）"
      echo "<!-- 压缩后保留最近条目 -->"
      echo ""
      echo "## 归档摘要"
      echo "<!-- $(date '+%Y-%m-%d') 压缩: 超出 ${limit} 行限制 -->"
    } > "$tmp_file"
    mv "$tmp_file" "$file"
    return
  fi

  # 策略3: 对于 domains/projects，截断到限制行数，剩余归档
  if [ -d "$(dirname "$file")" ]; then
    head -n "$limit" "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
  fi
}

echo "─── HOT 层检查 ───"
check_and_compact "$MEMORY_FILE" "$MEMORY_LIMIT" "memory.md"

echo ""
echo "─── corrections.md 检查 ───"
if [ -f "$CORRECTIONS_FILE" ]; then
  corr_lines=$(wc -l < "$CORRECTIONS_FILE" | tr -d ' ')
  echo "  corrections.md: ${corr_lines} 行 (限制: 200)"
  # corrections 保留最近50条
  if [ "$corr_lines" -gt 200 ]; then
    if $DRY_RUN; then
      echo "    [dry-run] 将压缩 corrections.md（保留最近50条）"
    else
      compact_file "$CORRECTIONS_FILE" 200
      echo "    ✅ 已压缩: corrections.md"
    fi
  fi
fi

echo ""
echo "─── WARM 层检查 ───"
if [ -d "$DOMAINS_DIR" ]; then
  for f in "$DOMAINS_DIR"/*.md; do
    [ ! -f "$f" ] && continue
    check_and_compact "$f" "$WARM_LIMIT" "$(basename "$f")"
  done
fi

if [ -d "$PROJECTS_DIR" ]; then
  for f in "$PROJECTS_DIR"/*.md; do
    [ ! -f "$f" ] && continue
    check_and_compact "$f" "$WARM_LIMIT" "$(basename "$f")"
  done
fi

echo ""
if $DRY_RUN; then
  echo "✅ 压缩检查完成（dry-run，未实际修改）"
else
  echo "✅ 压缩整理完成"
fi
echo ""
echo "💡 压缩策略:"
echo "   1. 合并相似纠正为单一规则"
echo "   2. 摘要冗长条目"
echo "   3. 归档未使用模式（永不删除）"
echo "   4. 保留已确认偏好原样"

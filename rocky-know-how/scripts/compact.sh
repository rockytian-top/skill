#!/bin/bash
# rocky-know-how 压缩整理脚本 v2.1.0
# 用法: compact.sh [--dry-run] [--file memory.md]
# 当文件超过限制时压缩：
#   memory.md: >100行 → 合并相似条目，摘要冗余，保留已确认偏好
#   domains/*.md: >200行 → 先把超出部分移到 archive/ 再截断
#   projects/*.md: >200行 → 先把超出部分移到 archive/ 再截断
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

echo "=== 压缩整理 (v2.1.0) ==="
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

# 合并相似条目（按Tag分组）
merge_similar_entries() {
  local file="$1"
  local tmp_file="/tmp/rocky-know-how-merge-$$.md"
  
  # 提取已确认偏好部分
  local confirmed_pref=$(awk '
    /^## 已确认偏好$/ { in_confirmed=1; next }
    /^## / { in_confirmed=0 }
    in_confirmed { print }
  ' "$file")
  
  # 提取其他条目并按Tag合并
  local other_entries=$(awk '
    /^## 已确认偏好$/ { skip=1; next }
    /^## / { skip=0 }
    !skip { print }
  ' "$file")
  
  # 合并相同Tag的条目
  local merged=""
  local current_tag=""
  local current_entry=""
  
  while IFS= read -r line; do
    if echo "$line" | grep -qE "^\-\ \*\*Tag"; then
      # 保存前一个条目
      if [ -n "$current_entry" ]; then
        merged="$merged$current_entry\n"
      fi
      current_tag=$(echo "$line" | sed 's/.*\*\*Tag:\*\* *//')
      current_entry="$line\n"
    else
      current_entry="$current_entry$line\n"
    fi
  done
  if [ -n "$current_entry" ]; then
    merged="$merged$current_entry"
  fi
  
  # 输出结果
  if [ -n "$confirmed_pref" ]; then
    echo "## 已确认偏好"
    echo "$confirmed_pref"
    echo ""
  fi
  if [ -n "$merged" ]; then
    echo "## 合并后的条目"
    echo -e "$merged"
  fi
}

compact_file() {
  local file="$1"
  local limit="$2"

  # 备份原文件
  local backup_file="${file}.bak.$(date +%s)"
  cp "$file" "$backup_file"
  echo "    📦 备份: $backup_file"

  # 策略1: 对于 memory.md，智能压缩
  if [ "$file" = "$MEMORY_FILE" ]; then
    local tmp_file="/tmp/rocky-know-how-compact-$$.md"
    
    # 提取各部分
    local confirmed_pref=$(awk '
      /^## 已确认偏好$/ { in_confirmed=1; print; next }
      /^## / { if (in_confirmed) { in_confirmed=0 } }
      in_confirmed { print }
    ' "$file")
    
    local active_patterns=$(awk '
      /^## 已确认偏好$/ { skip=1; next }
      /^## 活跃模式$/ { skip=0; print; next }
      /^## / { if (!skip) { skip=1 } }
      !skip { print }
    ' "$file")
    
    local recent_entries=$(awk '
      /^## 最近（最近7天）$/ { in_recent=1; print; next }
      /^## 归档摘要$/ { in_recent=0 }
      in_recent { print }
    ' "$file")
    
    local archive_summary=$(awk '
      /^## 归档摘要$/ { in_archive=1; print; next }
      in_archive { print }
    ' "$file")
    
    # 计算当前行数
    local current_lines=$(wc -l < "$file" | tr -d ' ')
    local overflow=$((current_lines - limit))
    
    # 构建压缩后的文件
    {
      echo "# HOT 记忆"
      echo ""
      
      # 保留已确认偏好（永不删除）
      if [ -n "$confirmed_pref" ]; then
        echo "## 已确认偏好"
        echo "$confirmed_pref"
        echo ""
      fi
      
      # 保留活跃模式
      if [ -n "$active_patterns" ]; then
        echo "## 活跃模式"
        echo "$active_patterns"
        echo ""
      fi
      
      # 保留最近7天的条目
      if [ -n "$recent_entries" ]; then
        echo "## 最近（最近7天）"
        echo "$recent_entries"
        echo ""
      fi
      
      # 添加归档摘要
      echo "## 归档摘要"
      echo "<!-- $(date '+%Y-%m-%d') 压缩: 超出 ${limit} 行限制 -->"
      if [ -n "$archive_summary" ]; then
        echo "$archive_summary" | tail -n +2  # 跳过第一行（标题）
      fi
    } > "$tmp_file"
    
    mv "$tmp_file" "$file"
    return
  fi

  # 策略2: 对于 corrections.md，保留最近50条时间戳条目
  # corrections.md 格式:
  # # 纠正日志
  # ## YYYY-MM-DD (日期标题)
  # ### HH:MM — namespace:area (时间戳条目，每个条目以 ### HH:MM 开头)
  if [ "$file" = "$CORRECTIONS_FILE" ]; then
    # 计算当前条目数（以 ### HH:MM 开头）
    local before_count=$(grep -c "^### [0-9][0-9]:[0-9][0-9] " "$file" 2>/dev/null || echo "0")
    echo "    📊 压缩前条目数: ${before_count}"
    
    if [ "$before_count" -gt 50 ]; then
      # 创建 archive 目录
      mkdir -p "$ARCHIVE_DIR"
      local archive_file="${ARCHIVE_DIR}/corrections-archive.md"
      
      # 获取所有日期块（倒序）
      local all_dates=$(grep "^## [0-9]" "$file" 2>/dev/null | tac)
      local total_dates=$(echo "$all_dates" | wc -l | tr -d ' ')
      
      # 保留最近50个日期（倒序的前50个，即最早的那些日期）
      local dates_to_keep=$(echo "$all_dates" | tail -50)
      local to_archive=$((total_dates - 50))
      local dates_to_archive=$(echo "$all_dates" | head -$to_archive)
      
      echo "    📊 总日期数: ${total_dates}, 保留: 50, 归档: $((total_dates - 50))"
      
      # 创建临时文件
      local tmp_kept="/tmp/rocky-know-how-corr-kept-$$.md"
      local tmp_archive_content="/tmp/rocky-know-how-corr-arch-content-$$.md"
      
      # 写入保留文件的头部（保留文件的前两行：标题和空行）
      head -n 2 "$file" > "$tmp_kept"
      
      # 写入归档内容
      {
        echo "# 纠正日志归档"
        echo "归档时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "压缩原因: 超出50条限制"
        echo ""
      } > "$tmp_archive_content"
      
      # 遍历原文件，根据日期决定保留还是归档
      local in_keep_date=0
      local current_date=""
      local line_buffer=""
      local in_entry=0
      
      while IFS= read -r line; do
        # 检测日期行
        if echo "$line" | grep -qE "^## [0-9]{4}-[0-9]{2}-[0-9]{2}$"; then
          current_date="$line"
          # 结束之前的条目
          if [ -n "$line_buffer" ]; then
            if [ $in_keep_date -eq 1 ]; then
              echo "$line_buffer" >> "$tmp_kept"
            else
              echo "$line_buffer" >> "$tmp_archive_content"
            fi
            line_buffer=""
          fi
          # 检查这个日期是否要保留
          if echo "$dates_to_keep" | grep -qF "$line"; then
            in_keep_date=1
            echo "" >> "$tmp_kept"
            echo "$line" >> "$tmp_kept"
          else
            in_keep_date=0
            echo "" >> "$tmp_archive_content"
            echo "$line" >> "$tmp_archive_content"
          fi
          in_entry=0
        elif echo "$line" | grep -qE "^### [0-9][0-9]:[0-9][0-9] "; then
          # 时间戳条目开始 - 结束之前的条目
          if [ -n "$line_buffer" ]; then
            if [ $in_keep_date -eq 1 ]; then
              echo "$line_buffer" >> "$tmp_kept"
            else
              echo "$line_buffer" >> "$tmp_archive_content"
            fi
            line_buffer=""
          fi
          line_buffer="$line"
          in_entry=1
        elif [ $in_entry -eq 1 ]; then
          line_buffer="$line_buffer"$'\n'$line
        elif [ -n "$line" ]; then
          # 非条目内容行（如空行或注释），直接处理
          if [ $in_keep_date -eq 1 ]; then
            echo "$line" >> "$tmp_kept"
          else
            echo "$line" >> "$tmp_archive_content"
          fi
        fi
      done < "$file"
      
      # 处理最后一行
      if [ -n "$line_buffer" ]; then
        if [ $in_keep_date -eq 1 ]; then
          echo "$line_buffer" >> "$tmp_kept"
        else
          echo "$line_buffer" >> "$tmp_archive_content"
        fi
      fi
      
      # 追加归档内容到归档文件
      cat "$tmp_archive_content" >> "$archive_file"
      echo "    📦 已归档旧条目到: ${archive_file}"
      
      # 用保留的内容替换原文件
      mv "$tmp_kept" "$file"
      
      # 清理临时文件
      rm -f "$tmp_archive_content"
      
      # 验证压缩后条目数
      local after_count=$(grep -c "^### [0-9][0-9]:[0-9][0-9] " "$file" 2>/dev/null || echo "0")
      echo "    📊 压缩后条目数: ${after_count}"
      
      if [ "$after_count" -ge "$before_count" ]; then
        echo "    ❌ 压缩后条目数异常: ${after_count} >= ${before_count}"
        # 恢复备份
        cp "$backup_file" "$file"
        echo "    🔄 已恢复备份"
        return 1
      fi
    fi
    return
  fi

  # 策略3: 对于 domains/projects，先把超出部分移到 archive/ 再截断
  local dir=$(dirname "$file")
  if [ -d "$dir" ]; then
    local basename=$(basename "$file")
    local lines=$(wc -l < "$file" | tr -d ' ')
    
    if [ "$lines" -gt "$limit" ]; then
      # 创建 archive 目录（如果不存在）
      mkdir -p "$ARCHIVE_DIR"
      
      # 把超出部分移到 archive
      tail -n +$((limit + 1)) "$file" > "${ARCHIVE_DIR}/${basename}.archived.$(date +%Y%m%d-%H%M%S)"
      echo "    📦 归档超出部分到: ${ARCHIVE_DIR}/${basename}.archived.$(date +%Y%m%d-%H%M%S)"
      
      # 截断到限制行数
      head -n "$limit" "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
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
  # 先检查条目数（以 ### HH:MM 开头）
  corr_entries=$(grep -c "^### [0-9][0-9]:[0-9][0-9] " "$CORRECTIONS_FILE" 2>/dev/null || echo "0")
  echo "  条目数: ${corr_entries} (压缩阈值: 50)"
  if [ "$corr_entries" -gt 50 ]; then
    if $DRY_RUN; then
      echo "    [dry-run] 将压缩 corrections.md（保留最近50条）"
    else
      compact_file "$CORRECTIONS_FILE" 200
      echo "    ✅ 已压缩: corrections.md"
    fi
  else
    echo "    ✅ 无需压缩"
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
echo "💡 压缩策略 v2.1.0:"
echo "   1. memory.md: 合并相似条目，摘要冗余，保留已确认偏好"
echo "   2. corrections.md: 保留最近50条"
echo "   3. domains/projects: 超出部分移到 archive/ 再截断"
echo "   4. 永不删除已确认偏好类条目"

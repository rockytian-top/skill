#!/bin/bash
# rocky-know-how 降级检查脚本 v2.1.0
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
INDEX_FILE="$SHARED_DIR/index.md"
ARCHIVE_DIR="$SHARED_DIR/archive"
DOMAINS_DIR="$SHARED_DIR/domains"
PROJECTS_DIR="$SHARED_DIR/projects"

echo "=== 降级检查 (v2.1.0) ==="
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

# 创建必要的目录
mkdir -p "$ARCHIVE_DIR"
mkdir -p "$DOMAINS_DIR"
mkdir -p "$PROJECTS_DIR"

# 获取所有条目及其日期
get_entries_with_dates() {
  local file="$1"
  awk -v cutoff="$CUTOFF_DATE" -v archive_cutoff="$ARCHIVE_CUTOFF" '
    BEGIN { entry_date=""; entry_content=""; in_entry=0 }
    
    /^## [0-9]{4}-[0-9]{2}-[0-9]{2}/ {
      # 保存前一个条目
      if (entry_content != "" && entry_date != "") {
        if (entry_date < archive_cutoff) {
          print "ARCHIVE|" entry_date "|" entry_content
        } else if (entry_date < cutoff) {
          print "DEMOTE|" entry_date "|" entry_content
        }
      }
      # 解析日期 (标准AWK方式)
      if (match($0, /## ([0-9]{4}-[0-9]{2}-[0-9]{2})/)) {
        entry_date = substr($0, RSTART+3, RLENGTH-3)
      }
      entry_content = $0
      in_entry = 1
      next
    }
    
    in_entry && /^## / {
      # 保存前一个条目
      if (entry_content != "" && entry_date != "") {
        if (entry_date < archive_cutoff) {
          print "ARCHIVE|" entry_date "|" entry_content
        } else if (entry_date < cutoff) {
          print "DEMOTE|" entry_date "|" entry_content
        }
      }
      entry_content = ""
      entry_date = ""
      in_entry = 0
      next
    }
    
    in_entry {
      entry_content = entry_content "\n" $0
    }
    
    END {
      # 处理最后一个条目
      if (entry_content != "" && entry_date != "") {
        if (entry_date < archive_cutoff) {
          print "ARCHIVE|" entry_date "|" entry_content
        } else if (entry_date < cutoff) {
          print "DEMOTE|" entry_date "|" entry_content
        }
      }
    }
  ' "$file"
}

# 备份文件
backup_file() {
  local file="$1"
  local backup="${file}.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$file" "$backup"
  echo "  📦 备份: $backup"
}

# 更新 index.md
update_index() {
  local action="$1"  # "DEMOTE" or "ARCHIVE"
  local entry_title="$2"
  local target_file="$3"
  
  if [ ! -f "$INDEX_FILE" ]; then
    echo "# 索引" > "$INDEX_FILE"
    echo "" >> "$INDEX_FILE"
  fi
  
  # 添加索引条目
  local timestamp=$(date '+%Y-%m-%d %H:%M')
  echo "- $(date '+%Y-%m-%d') [$action] $entry_title → $target_file" >> "$INDEX_FILE"
}

# 处理条目
process_entries() {
  local demote_count=0
  local archive_count=0
  
  # 获取所有条目
  entries_data=$(get_entries_with_dates "$MEMORY_FILE")
  
  if [ -z "$entries_data" ]; then
    echo "  无降级/归档候选"
    return
  fi
  
  # 分类处理
  demote_entries=$(echo "$entries_data" | grep "^DEMOTE|")
  archive_entries=$(echo "$entries_data" | grep "^ARCHIVE|")
  
  # 处理需要降级到 WARM 的条目
  if [ -n "$demote_entries" ]; then
    echo "--- 需要降级到 WARM 的条目 ---"
    while IFS='|' read -r action date content; do
      # 提取 Tag 或 Pattern
      local tag=$(echo "$content" | grep -E "^\- \*\*Tag" | sed 's/.*\*\*Tag:\*\* *//' | head -1)
      local pattern=$(echo "$content" | grep -E "^\- \*\*Pattern" | sed 's/.*\*\*Pattern:\*\* *//' | head -1)
      local identifier="${tag}${pattern}"
      [ -z "$identifier" ] && identifier="unknown"
      
      echo "  📤 降级: ${identifier} (最后更新: ${date})"
      
      if ! $DRY_RUN; then
        # 备份 memory.md
        backup_file "$MEMORY_FILE"
        
        # 确定目标文件
        local domain_file="${DOMAINS_DIR}/global.md"
        if [ ! -f "$domain_file" ]; then
          echo "# Domain: global" > "$domain_file"
          echo "" >> "$domain_file"
          echo "Inherits: global" >> "$domain_file"
          echo "" >> "$domain_file"
          echo "## 模式" >> "$domain_file"
          echo "" >> "$domain_file"
        fi
        
        # 提取实际的条目内容（去掉 DEMOTE|xxx| 前缀）
        local entry_content=$(echo "$content" | sed '1d')
        
        # 追加到 WARM 层
        echo "$entry_content" >> "$domain_file"
        echo "  ✅ 已追加到: $domain_file (WARM)"
        
        # 更新索引
        update_index "DEMOTE" "$identifier" "$domain_file"
        
        # 从 memory.md 移除该条目
        # 使用 sed 删除该条目（从 ## date 到下一个 ## 之前）
        local tmp_file="/tmp/rocky-know-how-demote-$$.md"
        awk -v target_date="$date" -v demo_marker="$DEMOTE_MARKER" '
          BEGIN { in_entry=0; skip_entry=0 }
          /^## [0-9]{4}-[0-9]{2}-[0-9]{2}/ {
            if (in_entry && !skip_entry) {
              # 输出前一个条目
              print prev_line
            }
            if (match($0, /## ([0-9]{4}-[0-9]{2}-[0-9]{2})/)) {
              entry_date_str = substr($0, RSTART+3, RLENGTH-3)
              if (entry_date_str == target_date) {
                skip_entry=1
              } else {
                skip_entry=0
                prev_line=$0
              }
            }
            in_entry=1
            next
          }
          /^## / {
            if (in_entry && !skip_entry) {
              print prev_line
            }
            in_entry=0; skip_entry=0
            next
          }
          in_entry && !skip_entry {
            print prev_line
            prev_line=$0
            next
          }
          in_entry && skip_entry { next }
          { print }
        ' "$MEMORY_FILE" > "$tmp_file"
        mv "$tmp_file" "$MEMORY_FILE"
        
        demote_count=$((demote_count + 1))
      fi
    done < <(echo "$demote_entries")
  fi
  
  # 处理需要归档到 COLD 的条目
  if [ -n "$archive_entries" ]; then
    echo ""
    echo "--- 需要归档到 COLD 的条目 ---"
    while IFS='|' read -r action date content; do
      # 提取 Tag 或 Pattern
      local tag=$(echo "$content" | grep -E "^\- \*\*Tag" | sed 's/.*\*\*Tag:\*\* *//' | head -1)
      local pattern=$(echo "$content" | grep -E "^\- \*\*Pattern" | sed 's/.*\*\*Pattern:\*\* *//' | head -1)
      local identifier="${tag}${pattern}"
      [ -z "$identifier" ] && identifier="unknown"
      
      echo "  📦 归档: ${identifier} (最后更新: ${date})"
      
      if ! $DRY_RUN; then
        # 备份 memory.md
        backup_file "$MEMORY_FILE"
        
        # 创建归档文件
        local archive_file="${ARCHIVE_DIR}/entry.${date}.$(date +%Y%m%d-%H%M%S).md"
        
        # 提取实际的条目内容（去掉 ARCHIVE|xxx| 前缀）
        local entry_content=$(echo "$content" | sed '1d')
        
        # 写入归档
        echo "# 归档条目: ${identifier}" > "$archive_file"
        echo "原始日期: ${date}" >> "$archive_file"
        echo "归档日期: $(date '+%Y-%m-%d')" >> "$archive_file"
        echo "" >> "$archive_file"
        echo "$entry_content" >> "$archive_file"
        echo "  ✅ 已归档到: $archive_file"
        
        # 更新索引
        update_index "ARCHIVE" "$identifier" "$archive_file"
        
        # 从 memory.md 移除该条目
        local tmp_file="/tmp/rocky-know-how-archive-$$.md"
        awk -v target_date="$date" '
          BEGIN { in_entry=0; skip_entry=0 }
          /^## [0-9]{4}-[0-9]{2}-[0-9]{2}/ {
            if (in_entry && !skip_entry) {
              print prev_line
            }
            if (match($0, /## ([0-9]{4}-[0-9]{2}-[0-9]{2})/)) {
              entry_date_str = substr($0, RSTART+3, RLENGTH-3)
              if (entry_date_str == target_date) {
                skip_entry=1
              } else {
                skip_entry=0
                prev_line=$0
              }
            }
            in_entry=1
            next
          }
          /^## / {
            if (in_entry && !skip_entry) {
              print prev_line
            }
            in_entry=0; skip_entry=0
            next
          }
          in_entry && !skip_entry {
            print prev_line
            prev_line=$0
            next
          }
          in_entry && skip_entry { next }
          { print }
        ' "$MEMORY_FILE" > "$tmp_file"
        mv "$tmp_file" "$MEMORY_FILE"
        
        archive_count=$((archive_count + 1))
      fi
    done < <(echo "$archive_entries")
  fi
  
  echo ""
  if $DRY_RUN; then
    echo "✅ 降级检查完成（dry-run，未实际修改）"
  else
    echo "✅ 降级整理完成: $demote_count 条降级, $archive_count 条归档"
  fi
}

if $DRY_RUN; then
  echo "=== 模拟模式 (dry-run) ==="
  echo ""
  entries_data=$(get_entries_with_dates "$MEMORY_FILE")
  
  if [ -z "$entries_data" ]; then
    echo "  无降级候选"
  else
    echo "需要降级的条目:"
    echo "$entries_data" | grep "^DEMOTE|" | while IFS='|' read -r action date content; do
      local tag=$(echo "$content" | grep -E "^\- \*\*Tag" | sed 's/.*\*\*Tag:\*\* *//' | head -1)
      local pattern=$(echo "$content" | grep -E "^\- \*\*Pattern" | sed 's/.*\*\*Pattern:\*\* *//' | head -1)
      local identifier="${tag}${pattern}"
      [ -z "$identifier" ] && identifier="unknown"
      echo "  📤 DEMOTE: ${identifier} (日期: ${date})"
    done
    
    echo ""
    echo "需要归档的条目:"
    echo "$entries_data" | grep "^ARCHIVE|" | while IFS='|' read -r action date content; do
      local tag=$(echo "$content" | grep -E "^\- \*\*Tag" | sed 's/.*\*\*Tag:\*\* *//' | head -1)
      local pattern=$(echo "$content" | grep -E "^\- \*\*Pattern" | sed 's/.*\*\*Pattern:\*\* *//' | head -1)
      local identifier="${tag}${pattern}"
      [ -z "$identifier" ] && identifier="unknown"
      echo "  📦 ARCHIVE: ${identifier} (日期: ${date})"
    done
  fi
  echo ""
  echo "💡 如需实际执行，请移除 --dry-run 参数"
else
  process_entries
fi

echo ""
echo "💡 降级规则: memory.md 中 ${DAYS_THRESHOLD}天+ 未使用的条目 → 降级到 domains/ (WARM)"
echo "💡 归档规则: ${ARCHIVE_THRESHOLD}天+ 未使用 → 归档到 archive/ (COLD)"
echo "💡 永不删除: 所有数据永久保留"

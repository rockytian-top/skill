#!/bin/bash
# rocky-know-how 搜经验诀窍
# 用法: search.sh [选项] <关键词1> [关键词2]...
#       search.sh --all              显示所有
#       search.sh --preview "关键词"  只显示摘要
#       search.sh --global "关键词"   搜所有workspace
#       search.sh --since YYYY-MM-DD  按日期过滤

MAX_RESULTS=10
SINCE_DATE=""
SHOW_ALL=false
PREVIEW=false
GLOBAL=false
KEYWORDS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)         SHOW_ALL=true; shift ;;
    --preview)     PREVIEW=true; shift ;;
    --global)      GLOBAL=true; shift ;;
    --since)       SINCE_DATE="$2"; shift 2 ;;
    --max-results) MAX_RESULTS="$2"; shift 2 ;;
    -h|--help)     echo "用法: search.sh [--all] [--preview] [--global] [--since YYYY-MM-DD] <关键词...>"; exit 0 ;;
    -*)             echo "未知选项: $1"; exit 1 ;;
    *)              KEYWORDS+=("$1"); shift ;;
  esac
done

# 共享 .learnings 路径
SHARED_DIR="$HOME/.openclaw/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"

# --global: 收集各 agent workspace 的文件
EXTRA_FILES=()
if $GLOBAL; then
  for d in "$HOME"/.openclaw/workspace-*/.learnings/experiences.md; do
    [ -f "$d" ] && EXTRA_FILES+=("$d")
  done
fi

# 格式化单个条目（供 --all 使用）
format_entry() {
  awk '
    /^## \[EXP-/ { id=$0; area=""; tags=""; created=""; problem="" }
    /^\*\*Area\*\*:/ { sub(/^\*\*Area\*\*: /,""); area=$0 }
    /^\*\*Tags\*\*:/ { sub(/^\*\*Tags\*\*: /,""); tags=$0 }
    /^\*\*Created\*\*:/ { sub(/^\*\*Created\*\*: /,""); created=$0 }
    /^### 问题$/ { getline; problem=$0 }
    /^---$/ && id!="" {
      printf "%s\n  Area: %s | Tags: %s | 创建: %s\n  问题: %s\n---\n\n", id, area, tags, created, problem
      id=""
    }
  ' "$1"
}

# 打印条目（预览或完整）
print_entry() {
  local block="$1"
  local id problem prevent

  id=$(echo "$block" | grep '^## \[EXP-' | sed 's/## //')
  problem=$(echo "$block" | sed -n '/^### 问题$/{n;p;}')
  prevent=$(echo "$block" | sed -n '/^### 预防$/{n;p;}')

  if $PREVIEW; then
    echo "📌 $id"
    echo "   问题: $problem"
    echo "   预防: $prevent"
    echo ""
  else
    echo "$block"
    echo ""
  fi
}

# 搜索单个文件
search_file() {
  local file="$1"
  local count=0

  # 无条目则直接返回
  local lines=$(grep -n '^## \[EXP-' "$file" 2>/dev/null | cut -d: -f1)
  [ -z "$lines" ] && return 1

  local prev=""
  for line in $lines; do
    [ -z "$prev" ] && { prev=$line; continue; }

    local block=$(sed -n "${prev},$((line-1))p" "$file")

    # 日期过滤
    if [ -n "$SINCE_DATE" ]; then
      local entry_date=$(echo "$block" | grep '^## \[EXP-' | sed 's/.*\[EXP-\([0-9]\{8\}\)-.*/\1/')
      local since_num=$(echo "$SINCE_DATE" | sed 's/-//g')
      [ "${entry_date:-0}" -lt "${since_num:-0}" ] 2>/dev/null && { prev=$line; continue; }
    fi

    # AND 关键词匹配
    local match=true
    for kw in "${KEYWORDS[@]}"; do
      echo "$block" | grep -qi --color=never "$kw" || { match=false; break; }
    done

    $match || { prev=$line; continue; }

    print_entry "$block"
    count=$((count+1))
    [ $count -ge $MAX_RESULTS ] && break
    prev=$line
  done

  # 处理最后一个块（prev 指向倒数第二个条目的起始行）
  local total=$(wc -l < "$file" | tr -d ' ')
  local block=$(sed -n "${prev},${total}p" "$file")
  local match=true
  for kw in "${KEYWORDS[@]}"; do
    echo "$block" | grep -qi --color=never "$kw" || { match=false; break; }
  done
  if $match; then
    print_entry "$block"
    count=$((count+1))
  fi

  [ $count -gt 0 ] && return 0 || return 1
}

# --all 模式
if $SHOW_ALL; then
  echo "=== 全部经验诀窍 ==="
  [ -f "$ERRORS_FILE" ] && format_entry "$ERRORS_FILE"
  for f in "${EXTRA_FILES[@]:-}"; do
    [ "$f" = "$ERRORS_FILE" ] && continue
    [ -z "$f" ] && continue
    echo "--- $(basename "$(dirname "$f")") ---"
    format_entry "$f"
  done
  exit 0
fi

[ ${#KEYWORDS[@]} -eq 0 ] && echo "用法: search.sh [--all] [--preview] [--global] <关键词...>" && exit 1

# 搜索
total_found=0
[ -f "$ERRORS_FILE" ] && search_file "$ERRORS_FILE" && total_found=1
for f in "${EXTRA_FILES[@]:-}"; do
  [ "$f" = "$ERRORS_FILE" ] && continue
  [ -z "$f" ] && continue
  search_file "$f" && total_found=1
done

[ $total_found -eq 0 ] && echo "经验诀窍未找到相关记录" && exit 1
exit 0

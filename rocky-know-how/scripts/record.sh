#!/bin/bash
# rocky-know-how 写入经验诀窍 v1.3.0
# 用法: record.sh [--dry-run] "<问题>" "<踩坑过程>" "<正确方案>" "<预防>" "<tags>" [area]
# 例: record.sh "排查网站只看进程" "第1次:只看进程→报正常" "curl验证" "必须curl" "troubleshooting" infra

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_DIR="$HOME/.openclaw/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"

# 初始化
mkdir -p "$SHARED_DIR/archive"

# 初始化文件（只写一次头部）
init_file() {
  if [ ! -f "$ERRORS_FILE" ]; then
    printf "# 经验诀窍\n\n---\n" > "$ERRORS_FILE"
  fi
}

# 动态获取 workspace 路径（和 handler.js 保持一致）
get_workspace() {
  if [ -n "$OPENCLAW_WORKSPACE" ]; then
    echo "$OPENCLAW_WORKSPACE"
  elif [ -n "$OPENCLAW_SESSION_KEY" ]; then
    agentId=$(echo "$OPENCLAW_SESSION_KEY" | cut -d: -f2)
    echo "$HOME/.openclaw/workspace-${agentId}"
  else
    echo "$HOME/.openclaw/workspace"
  fi
}

# 解析参数
DRY_RUN=false
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    *)         ARGS+=("$1"); shift ;;
  esac
done

if [ ${#ARGS[@]} -lt 5 ]; then
  echo "用法: record.sh [--dry-run] \"<问题>\" \"<踩坑过程>\" \"<正确方案>\" \"<预防>\" \"<tags>\" [area]"
  echo "  --dry-run  预览将写入的内容，不实际写入"
  echo "  area 可选: frontend|backend|infra|tests|docs|config (默认: infra)"
  exit 1
fi

PROBLEM="${ARGS[0]}"
FAILURES="${ARGS[1]}"
SOLUTION="${ARGS[2]}"
PREVENT="${ARGS[3]}"
TAGS="${ARGS[4]}"
AREA="${ARGS[5]:-infra}"

# 去重检查
check_duplicate() {
  local found_id=""
  local found_summary=""

  # 1. 精确问题文本匹配
  if grep -qF "$PROBLEM" "$ERRORS_FILE" 2>/dev/null; then
    found_id=$(grep -B0 "^## \[EXP-" "$ERRORS_FILE" | head -1 | sed 's/## \[\(EXP-[0-9]*-[0-9]*\)\].*/\1/')
    found_summary=$(grep -A1 "^### 问题$" "$ERRORS_FILE" | grep -F "$PROBLEM" | head -1)
  fi

  # 2. Tags 组合 + 问题关键词重叠去重
  if [ -z "$found_id" ] && [ -f "$ERRORS_FILE" ]; then
    # 提取所有已有条目
    local prev=""
    local lines=$(grep -n "^## \[EXP-" "$ERRORS_FILE" 2>/dev/null | cut -d: -f1)
    [ -z "$lines" ] && return 1

    for line in $lines; do
      [ -z "$prev" ] && { prev=$line; continue; }
      local block=$(sed -n "${prev},$((line-1))p" "$ERRORS_FILE")

      # 提取已有 Tags
      local exist_tags=$(echo "$block" | grep "^\*\*Tags\*\*:" | sed 's/\*\*Tags\*\*: //' | tr ',' ' ')
      local exist_problem=$(echo "$block" | sed -n '/^### 问题$/{n;p;}')
      local exist_id=$(echo "$block" | grep "^## \[EXP-" | sed 's/## \[\(EXP-[0-9]*-[0-9]*\)\].*/\1/')

      # Tags 完全匹配检查
      local sorted_new=$(echo "$TAGS" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sort | tr '\n' ',' | sed 's/,$//')
      local sorted_exist=$(echo "$exist_tags" | sed 's/  */ /g' | tr ' ' '\n' | sort | tr '\n' ',' | sed 's/,$//')

      if [ "$sorted_new" = "$sorted_exist" ]; then
        # 关键词重叠检查（>80%）
        local new_words=$(echo "$PROBLEM" | tr ' ' '\n' | grep -v '^$' | sort -u)
        local exist_words=$(echo "$exist_problem" | tr ' ' '\n' | grep -v '^$' | sort -u)
        local total=$(echo "$new_words" | wc -l | tr -d ' ')
        [ "$total" -eq 0 ] && { prev=$line; continue; }
        local match=0
        while IFS= read -r w; do
          echo "$exist_words" | grep -qF "$w" && match=$((match+1))
        done < <(echo "$new_words")
        local ratio=$((match * 100 / total))
        if [ "$ratio" -ge 80 ]; then
          found_id="$exist_id"
          found_summary="$exist_problem"
          break
        fi
      fi
      prev=$line
    done
  fi

  if [ -n "$found_id" ]; then
    echo "⚠️  相似条目已存在:"
    echo "   ID: $found_id"
    echo "   问题: $found_summary"
    echo "   Tags: $TAGS"
    return 0
  fi
  return 1
}

# 生成 ID
generate_id() {
  local today=$(date +%Y%m%d)
  local count
  count=$(grep -c "\[EXP-${today}-" "$ERRORS_FILE" 2>/dev/null || true)
  count=$(echo "$count" | tr -d ' \n')
  [ -z "$count" ] && count=0
  local seq=$(printf "%03d" $((count + 1)))
  echo "EXP-${today}-${seq}"
}

init_file

# 去重检查
if ! $DRY_RUN && check_duplicate; then
  exit 0
fi

ID=$(generate_id)
NOW=$(date '+%Y-%m-%d %H:%M:%S')

# 要写入的内容
ENTRY="

## [${ID}] ${PROBLEM}

**Area**: ${AREA}
**Failed-Count**: ≥2
**Tags**: ${TAGS}
**Created**: ${NOW}

### 问题
${PROBLEM}

### 踩坑过程
${FAILURES}

### 正确方案
${SOLUTION}

### 预防
${PREVENT}

---
"

if $DRY_RUN; then
  echo "=== 预览写入内容 (dry-run) ==="
  echo "$ENTRY"
  echo "=== 目标文件: $ERRORS_FILE ==="
  exit 0
fi

# 写入经验诀窍文件
echo "$ENTRY" >> "$ERRORS_FILE"
echo "✅ 已写入经验诀窍: ${ID} [${AREA}]"

# P0: 同步写入 memory/*.md（让原生 memory_search 能搜到）
WORKSPACE=$(get_workspace)
MEMORY_DIR="$WORKSPACE/memory"
MEMORY_FILE="$MEMORY_DIR/$(date +%Y-%m-%d).md"

if [ -d "$MEMORY_DIR" ]; then
  cat >> "$MEMORY_FILE" << MEMEOF

## 📚 经验诀窍 ${ID}: ${PROBLEM}
<!-- rocky-know-how:${ID} -->

- **踩坑**: ${FAILURES}
- **正确方案**: ${SOLUTION}
- **预防**: ${PREVENT}
- **Tags**: ${TAGS}

MEMEOF
  echo "✅ 已同步到 memory/$(date +%Y-%m-%d).md"
fi

# 异步晋升检查（传入 workspace 路径）
(
  WORKSPACE="$WORKSPACE" "$SKILL_DIR/promote.sh" >> /dev/null 2>&1 &
)

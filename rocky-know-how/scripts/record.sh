#!/bin/bash
# rocky-know-how 写入经验诀窍 v2.0.0
# 用法: record.sh [--dry-run] [--namespace global|domain|project] "<问题>" "<踩坑过程>" "<正确方案>" "<预防>" "<tags>" [area|domain]
# 例: record.sh "排查网站只看进程" "第1次:只看进程→报正常" "curl验证" "必须curl" "troubleshooting" infra

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"

# 动态获取状态目录
get_state_dir() {
  if [ -n "$OPENCLAW_STATE_DIR" ]; then
    echo "$OPENCLAW_STATE_DIR"
  else
    echo "$HOME/.openclaw"
  fi
}

STATE_DIR=$(get_state_dir)
SHARED_DIR="$STATE_DIR/.learnings"
ERRORS_FILE="$SHARED_DIR/experiences.md"
CORRECTIONS_FILE="$SHARED_DIR/corrections.md"
MEMORY_FILE="$SHARED_DIR/memory.md"
DOMAINS_DIR="$SHARED_DIR/domains"
PROJECTS_DIR="$SHARED_DIR/projects"
ARCHIVE_DIR="$SHARED_DIR/archive"

# 初始化目录
mkdir -p "$SHARED_DIR" "$DOMAINS_DIR" "$PROJECTS_DIR" "$ARCHIVE_DIR"

# 初始化文件
init_file() {
  local file="$1"
  local header="$2"
  if [ ! -f "$file" ]; then
    printf "%s\n\n---\n" "$header" > "$file"
  fi
}

init_file "$ERRORS_FILE" "# 经验诀窍"

# 动态获取 workspace 路径
get_workspace() {
  if [ -n "$OPENCLAW_WORKSPACE" ]; then
    echo "$OPENCLAW_WORKSPACE"
  elif [ -n "$OPENCLAW_SESSION_KEY" ]; then
    agentId=$(echo "$OPENCLAW_SESSION_KEY" | cut -d: -f2)
    echo "$STATE_DIR/workspace-${agentId}"
  else
    echo "$STATE_DIR/workspace"
  fi
}

# 解析参数
DRY_RUN=false
NAMESPACE="global"
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --namespace)
      NAMESPACE="$2"; shift 2 ;;
    *)         ARGS+=("$1"); shift ;;
  esac
done

if [ ${#ARGS[@]} -lt 5 ]; then
  echo "用法: record.sh [--dry-run] [--namespace global|domain|project] \"<问题>\" \"<踩坑过程>\" \"<正确方案>\" \"<预防>\" \"<tags>\" [namespace]"
  echo "  --dry-run    预览将写入的内容，不实际写入"
  echo "  --namespace  写入命名空间: global(默认)|domain|project"
  echo "  area/domain/project 名由第五个参数指定"
  exit 1
fi

PROBLEM="${ARGS[0]}"
FAILURES="${ARGS[1]}"
SOLUTION="${ARGS[2]}"
PREVENT="${ARGS[3]}"
TAGS="${ARGS[4]}"
NS_VALUE="${ARGS[5]:-}"

# 确定领域/项目名
AREA="${NS_VALUE:-infra}"
DOMAIN_TARGET=""
PROJECT_TARGET=""

case "$NAMESPACE" in
  domain)
    DOMAIN_TARGET="${NS_VALUE:-general}"
    AREA="domain:${DOMAIN_TARGET}"
    ;;
  project)
    PROJECT_TARGET="${NS_VALUE:-default}"
    AREA="project:${PROJECT_TARGET}"
    ;;
  *)
    AREA="${NS_VALUE:-infra}"
    ;;
esac

# 生成 ID（统计所有相关文件中的今日 ID 数量，避免序号撞车）
generate_id() {
  local today=$(date +%Y%m%d)
  local count=0
  local c

  # 统计 experiences.md 中的
  c=$(grep -c "\[EXP-${today}-" "$ERRORS_FILE" 2>/dev/null | tr -d '[:space:]')
  if echo "$c" | grep -qE '^[0-9]+$'; then
    count=$((count + c))
  fi

  # 统计 domains/*.md 中的
  if [ -d "$DOMAINS_DIR" ]; then
    for f in "$DOMAINS_DIR"/*.md; do
      [ -f "$f" ] || continue
      c=$(grep -c "\[EXP-${today}-" "$f" 2>/dev/null | tr -d '[:space:]')
      if echo "$c" | grep -qE '^[0-9]+$'; then
        count=$((count + c))
      fi
    done
  fi

  # 统计 projects/*.md 中的
  if [ -d "$PROJECTS_DIR" ]; then
    for f in "$PROJECTS_DIR"/*.md; do
      [ -f "$f" ] || continue
      c=$(grep -c "\[EXP-${today}-" "$f" 2>/dev/null | tr -d '[:space:]')
      if echo "$c" | grep -qE '^[0-9]+$'; then
        count=$((count + c))
      fi
    done
  fi

  local seq=$(printf "%03d" $((count + 1)))
  echo "EXP-${today}-${seq}"
}

# 去重检查（仅对 experiences.md）
check_duplicate() {
  local found_id=""
  local found_summary=""

  if grep -qF "$PROBLEM" "$ERRORS_FILE" 2>/dev/null; then
    found_id=$(grep -n -F "$PROBLEM" "$ERRORS_FILE" | head -1 | cut -d: -f1)
    if [ -n "$found_id" ]; then
      found_id=$(sed -n "1,${found_id}p" "$ERRORS_FILE" | grep '^## \[EXP-' | tail -1 | sed 's/## \[\(EXP-[0-9]*-[0-9]*\)\].*/\1/')
    fi
    found_summary="$PROBLEM"
  fi

  if [ -z "$found_id" ] && [ -f "$ERRORS_FILE" ]; then
    local prev=""
    local lines=$(grep -n "^## \[EXP-" "$ERRORS_FILE" 2>/dev/null | cut -d: -f1)
    [ -z "$lines" ] && return 1

    for line in $lines; do
      [ -z "$prev" ] && { prev=$line; continue; }
      local block=$(sed -n "${prev},$((line-1))p" "$ERRORS_FILE")

      local exist_tags=$(echo "$block" | grep "^\*\*Tags\*\*:" | sed 's/\*\*Tags\*\*: //' | tr ',' ' ')
      local exist_problem=$(echo "$block" | sed -n '/^### 问题$/{n;p;}')
      local exist_id=$(echo "$block" | grep "^## \[EXP-" | sed 's/## \[\(EXP-[0-9]*-[0-9]*\)\].*/\1/')

      local sorted_new=$(echo "$TAGS" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sort | tr '\n' ',' | sed 's/,$//')
      local sorted_exist=$(echo "$exist_tags" | sed 's/  */ /g' | tr ' ' '\n' | sort | tr '\n' ',' | sed 's/,$//')

      if [ "$sorted_new" = "$sorted_exist" ]; then
        local new_words=$(echo "$PROBLEM" | tr ' ' '\n' | grep -v '^$' | sort -u)
        local exist_words=$(echo "$exist_problem" | tr ' ' '\n' | grep -v '^$' | sort -u)
        local total=$(echo "$new_words" | wc -l | tr -d ' ')
        [ "$total" -eq 0 ] && { prev=$line; continue; }
        local match=0
        while IFS= read -r w; do
          echo "$exist_words" | grep -qF --color=never "$w" && match=$((match+1))
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

init_file "$ERRORS_FILE" "# 经验诀窍"

# 去重检查
if ! $DRY_RUN && check_duplicate; then
  exit 0
fi

ID=$(generate_id)
NOW=$(date '+%Y-%m-%d %H:%M:%S')

ENTRY="

## [${ID}] ${PROBLEM}

**Area**: ${AREA}
**Failed-Count**: ≥2
**Tags**: ${TAGS}
**Created**: ${NOW}
**Namespace**: ${NAMESPACE}

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

# ============ 写入 experiences.md（v1 主数据） ============
if $DRY_RUN; then
  echo "=== 预览写入内容 (dry-run) ==="
  echo "$ENTRY"
  echo "=== 目标文件: $ERRORS_FILE ==="
else
  echo "$ENTRY" >> "$ERRORS_FILE"
  echo "✅ 已写入经验诀窍: ${ID} [${AREA}]"
fi

# ============ 同步到 corrections.md（v2 纠正日志） ============
CORRECTION_ENTRY="

## $(date '+%Y-%m-%d')

### $(date '+%H:%M') — ${NAMESPACE}:${AREA}
- **纠正:** ${PROBLEM}
- **正确方案:** ${SOLUTION}
- **Tags:** ${TAGS}
- **Count:** 1 (first occurrence)
- **Source:** ${ID}
"

if $DRY_RUN; then
  echo "=== corrections.md 同步 ==="
  echo "$CORRECTION_ENTRY"
else
  if [ ! -f "$CORRECTIONS_FILE" ]; then
    printf "# 纠正日志\n\n" > "$CORRECTIONS_FILE"
  fi
  echo "$CORRECTION_ENTRY" >> "$CORRECTIONS_FILE"
  echo "✅ 已同步到 corrections.md"
fi

# ============ 写入 layered 存储（domain/project 命名空间） ============
if [ "$NAMESPACE" = "domain" ] && [ -n "$DOMAIN_TARGET" ]; then
  DOMAIN_FILE="$DOMAINS_DIR/${DOMAIN_TARGET}.md"
  if [ ! -f "$DOMAIN_FILE" ]; then
    printf "# Domain: %s\n\nInherits: global\n\n## 模式\n\n" "$DOMAIN_TARGET" > "$DOMAIN_FILE"
  fi
  DOMAIN_ENTRY="
### $(date '+%Y-%m-%d') [${ID}]
- **问题:** ${PROBLEM}
- **方案:** ${SOLUTION}
- **预防:** ${PREVENT}
- **Tags:** ${TAGS}
"
  if $DRY_RUN; then
    echo "=== domain: ${DOMAIN_TARGET} 写入 ==="
    echo "$DOMAIN_ENTRY"
  else
    echo "$DOMAIN_ENTRY" >> "$DOMAIN_FILE"
    echo "✅ 已写入 domains/${DOMAIN_TARGET}.md"
  fi
fi

if [ "$NAMESPACE" = "project" ] && [ -n "$PROJECT_TARGET" ]; then
  PROJECT_FILE="$PROJECTS_DIR/${PROJECT_TARGET}.md"
  if [ ! -f "$PROJECT_FILE" ]; then
    printf "# Project: %s\n\nInherits: global, domains/code\n\n## 模式\n\n" "$PROJECT_TARGET" > "$PROJECT_FILE"
  fi
  PROJECT_ENTRY="
### $(date '+%Y-%m-%d') [${ID}]
- **问题:** ${PROBLEM}
- **方案:** ${SOLUTION}
- **预防:** ${PREVENT}
- **Tags:** ${TAGS}
"
  if $DRY_RUN; then
    echo "=== project: ${PROJECT_TARGET} 写入 ==="
    echo "$PROJECT_ENTRY"
  else
    echo "$PROJECT_ENTRY" >> "$PROJECT_FILE"
    echo "✅ 已写入 projects/${PROJECT_TARGET}.md"
  fi
fi

# ============ 同步到 workspace memory/*.md（v1 兼容） ============
if ! $DRY_RUN; then
  WORKSPACE=$(get_workspace)
  MEMORY_DIR="$WORKSPACE/memory"
  MEMORY_FILE_WS="$MEMORY_DIR/$(date +%Y-%m-%d).md"

  if [ -d "$MEMORY_DIR" ]; then
    cat >> "$MEMORY_FILE_WS" << MEMEOF

## 📚 经验诀窍 ${ID}: ${PROBLEM}
<!-- rocky-know-how:${ID} -->

- **踩坑**: ${FAILURES}
- **正确方案**: ${SOLUTION}
- **预防**: ${PREVENT}
- **Tags**: ${TAGS}
- **Namespace**: ${NAMESPACE}

MEMEOF
    echo "✅ 已同步到 memory/$(date +%Y-%m-%d).md"
  fi

  # 异步晋升检查
  (
    WORKSPACE="$WORKSPACE" STATE_DIR="$STATE_DIR" "$SKILL_DIR/promote.sh" >> /dev/null 2>&1 &
  )
fi

$DRY_RUN && echo "=== (dry-run 模式，未实际写入) ==="

#!/bin/bash
# rocky-know-how 写入经验诀窍 v2.7.1
# 用法: record.sh [--dry-run] [--namespace global|domain|project] "<问题>" "<踩坑过程>" "<正确方案>" "<预防>" "<tags>" [area|domain]
# 例: record.sh "排查网站只看进程" "第1次:只看进程→报正常" "curl验证" "必须curl" "troubleshooting" infra

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPTS_DIR/lib/common.sh"

STATE_DIR=$(get_state_dir)
SHARED_DIR=$(get_shared_dir)
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
    local agentId=$(echo "$OPENCLAW_SESSION_KEY" | cut -d: -f2)
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

# 校验：位置参数不能以 -- 开头
# ARGS[0] 以 -- 开头 → 调用者传了未知选项（如 record.sh --tag "..."）
# ARGS[i]（i>=1）以 -- 开头 → 调用者把选项名当值传了（如 record.sh "..." "..." "..." "..." "--tag"）
for i in "${!ARGS[@]}"; do
  if [[ "${ARGS[$i]}" == --* ]]; then
    if [[ $i -eq 0 ]]; then
      echo "❌ 未知选项: ${ARGS[0]}"
      echo "支持的选项: --dry-run, --namespace"
    else
      echo "❌ 参数错误: '${ARGS[$i]}' 不是有效的值"
    fi
    echo "用法: record.sh [--dry-run] [--namespace global|domain|project] \"<问题>\" \"<踩坑过程>\" \"<正确方案>\" \"<预防>\" \"<tags>\" [area|domain]"
    exit 1
  fi
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
    AREA="${DOMAIN_TARGET}"
    ;;
  project)
    PROJECT_TARGET="${NS_VALUE:-default}"
    AREA="${PROJECT_TARGET}"
    ;;
  *)
    AREA="${NS_VALUE:-infra}"
    ;;
esac

# 生成 ID（扫描所有文件中的最大编号，避免序号撞车）
generate_id() {
  local today=$(date +%Y%m%d)
  local prefix="EXP-${today}-"
  local max_seq=0
  local files
  
  # 文件锁机制：防止并发 generate_id 冲突（P5 fix）
  local lock_dir="$SHARED_DIR/.id_lock"
  local max_retry=100
  local retry=0
  while ! mkdir "$lock_dir" 2>/dev/null; do
    sleep 0.05
    retry=$((retry+1))
    if [ $retry -ge $max_retry ]; then
      echo "⚠️  ID生成超时（锁竞争超过5秒），使用随机后缀" >&2
      rmdir "$lock_dir" 2>/dev/null
      echo "${prefix}$(date +%s%N | head -c 12)"
      return
    fi
  done
  
  # 收集所有可能含ID的文件
  files="$ERRORS_FILE"
  [ -d "$DOMAINS_DIR" ]  && files="$files $(ls "$DOMAINS_DIR"/*.md 2>/dev/null)"
  [ -d "$PROJECTS_DIR" ] && files="$files $(ls "$PROJECTS_DIR"/*.md 2>/dev/null)"
  [ -d "$ARCHIVE_DIR" ]  && files="$files $(ls "$ARCHIVE_DIR"/*.md 2>/dev/null)"

  # 用临时文件收集所有 seq，避免子 shell 变量修改丢失问题
  local tmpfile=$(mktemp)
  for f in $files; do
    [ -f "$f" ] || continue
    grep -oE "${prefix}[0-9]+" "$f" 2>/dev/null | sed "s/${prefix}//" >> "$tmpfile"
  done

  # 去掉前导零，取最大编号（awk 在主 shell 执行）
  if [ -s "$tmpfile" ]; then
    max_seq=$(awk '{gsub(/^0+/,"",$0); if($1+0>max)max=$1+0} END{print max+0}' "$tmpfile")
  fi
  rm -f "$tmpfile"

  local new_seq=$((max_seq + 1))
  local new_id="${prefix}$(printf '%03d' $new_seq)"
  
  # 释放锁
  rmdir "$lock_dir"
  
  echo "$new_id"
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

      # P2 fix: O(n) tag重叠检测，用 grep+sort 一次性替代嵌套循环
      local new_tag_set=$(echo "$sorted_new" | tr ',' '\n' | grep -v '^$' | sort -u)
      local exist_tag_set=$(echo "$sorted_exist" | tr ',' '\n' | grep -v '^$' | sort -u)
      local tag_total=$(echo "$new_tag_set" | wc -l | tr -d ' ')
      # 将 exist_tag_set 写入临时文件，用 grep 批量匹配，避免 O(n²) 嵌套循环
      local exist_tmp=$(mktemp)
      echo "$exist_tag_set" > "$exist_tmp"
      local tag_match=$(echo "$new_tag_set" | grep -F -f "$exist_tmp" 2>/dev/null | wc -l | tr -d ' ')
      rm -f "$exist_tmp"
      [ "$tag_total" -eq 0 ] && tag_total=1
      local tag_ratio=$((tag_match * 100 / tag_total))
      if [ "$tag_ratio" -ge 50 ]; then
        # Tags 重叠度≥50%即拦截（不需要文字相似度检查）
        found_id="$exist_id"
        found_summary="$exist_problem"
        break
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

# 去重检查（dry-run 也执行，以便预览）
if check_duplicate; then
  if $DRY_RUN; then
    echo "⚠️  与已有条目重复 (dry-run 模式，仍显示预览)"
  else
    echo "(未写入，因与已有条目重复)"
    exit 1
  fi
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
    # P4 fix: 使用单引号 heredoc 防止命令注入（变量不展开）
    printf '%s\n' "" >> "$MEMORY_FILE_WS"
    printf '## 📚 经验诀窍 %s: %s\n' "$ID" "$PROBLEM" >> "$MEMORY_FILE_WS"
    printf '<!-- rocky-know-how:%s -->\n\n' "$ID" >> "$MEMORY_FILE_WS"
    printf '- **踩坑**: %s\n' "$FAILURES" >> "$MEMORY_FILE_WS"
    printf '- **正确方案**: %s\n' "$SOLUTION" >> "$MEMORY_FILE_WS"
    printf '- **预防**: %s\n' "$PREVENT" >> "$MEMORY_FILE_WS"
    printf '- **Tags**: %s\n' "$TAGS" >> "$MEMORY_FILE_WS"
    printf '- **Namespace**: %s\n' "$NAMESPACE" >> "$MEMORY_FILE_WS"
    echo "✅ 已同步到 memory/$(date +%Y-%m-%d).md"
  fi

  # 异步晋升检查
  # R6 fix: 记录 promote 后台进程结果到日志文件
  PROMOTE_LOG="$SHARED_DIR/.promote.log"
  (
    WORKSPACE="$WORKSPACE" STATE_DIR="$STATE_DIR" "$SKILL_DIR/promote.sh" >> "$PROMOTE_LOG" 2>&1
    promote_exit=$?
    if [ $promote_exit -ne 0 ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] promote.sh 失败 (exit=$promote_exit)" >> "$PROMOTE_LOG"
    fi
  ) &
fi

if $DRY_RUN; then
  echo "=== (dry-run 模式，未实际写入) ==="
fi

# ============ 向量索引（优雅降级） ============
if ! $DRY_RUN; then
  source "$SKILL_DIR/lib/vectors.sh" 2>/dev/null
  if type vector_check &>/dev/null && vector_check 2>/dev/null; then
    vector_init "$STATE_DIR"
    VECTOR_TEXT="${PROBLEM}。${SOLUTION}。Tags: ${TAGS}"
    if vector_index_add "$ID" "$VECTOR_TEXT" "$AREA" "$NAMESPACE" "$TAGS" 2>/dev/null; then
      echo "✅ 已同步到向量索引"
    else
      echo "⚠️ 向量索引生成失败（不影响写入）"
    fi
  fi
fi

#!/bin/bash
# rocky-know-how 自动提取经验脚本 v1.4.0
# 从 pending 记录中提取有价值的内容，写入 experiences.md
# 用法: bash auto-extract.sh [--dry-run]

set -e

VERSION="1.4.0"
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
PENDING_DIR="$STATE_DIR/.learnings/pending"
EXPERIENCES_FILE="$STATE_DIR/.learnings/experiences.md"
PROCESSED_DIR="$STATE_DIR/.learnings/archive"

DRY_RUN=false
[ "$1" = "--dry-run" ] && DRY_RUN=true

echo "=== rocky-know-how 自动提取 v${VERSION} ==="
echo "状态目录: $STATE_DIR"
echo ""

# 初始化
mkdir -p "$PENDING_DIR" "$PROCESSED_DIR"

if [ ! -f "$EXPERIENCES_FILE" ]; then
  printf "# 经验诀窍\n\n---\n" > "$EXPERIENCES_FILE"
fi

# 统计
total=$(find "$PENDING_DIR" -name "lesson_*.json" 2>/dev/null | wc -l | tr -d ' ')
processed=0
extracted=0

echo "待处理记录: $total"
echo ""

if [ "$total" -eq 0 ]; then
  echo "没有待处理记录，退出。"
  exit 0
fi

# 生成唯一ID
generate_id() {
  date +%Y%m%d
  random=$(openssl rand -hex 2 2>/dev/null || echo $RANDOM | head -c4)
  echo "${date}-${random}"
}

# 遍历所有待处理记录
for file in "$PENDING_DIR"/lesson_*.json; do
  [ -f "$file" ] || continue
  
  processed=$((processed + 1))
  filename=$(basename "$file")
  
  # 读取记录
  record=$(cat "$file" 2>/dev/null)
  if [ -z "$record" ]; then
    echo "[$filename] 读取失败，跳过"
    continue
  fi
  
  # 提取字段
  outcome=$(echo "$record" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('outcome','unknown'))" 2>/dev/null || echo "unknown")
  message=$(echo "$record" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null || echo "")
  agent_id=$(echo "$record" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('agentId',''))" 2>/dev/null || echo "")
  timestamp=$(echo "$record" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('timestamp',''))" 2>/dev/null || echo "")
  
  # 只处理有意义的outcome
  if [ "$outcome" = "success" ] || [ "$outcome" = "solved_after_failure" ]; then
    if [ -n "$message" ] && [ ${#message} -gt 10 ]; then
      # 简单分类
      area="infra"
      tags="auto"
      
      if echo "$message" | grep -qi "vps\|服务器\|ssh\|端口"; then
        area="infra"
        tags="auto,server"
      elif echo "$message" | grep -qi "代码\|开发\|php\|js"; then
        area="backend"
        tags="auto,dev"
      elif echo "$message" | grep -qi "测试\|bug\|修复"; then
        area="tests"
        tags="auto,debug"
      fi
      
      # 生成经验ID
      exp_id="EXP-$(date +%Y%m%d)-$(printf '%03d' $((RANDOM % 999 + 1)))"
      
      # 构建经验条目
      problem=$(echo "$message" | head -c 150 | tr -d '\n"')
      solution=$(echo "$message" | tail -c 200 | tr -d '\n"')
      
      entry="## [${exp_id}] ${problem}

**Area**: ${area}
**Tags**: ${tags}
**Source**: auto (auto-extract)
**Agent**: ${agent_id}
**Created**: ${timestamp}

### 问题
${problem}

### 解决
${solution}

---
"
      
      if [ "$DRY_RUN" = true ]; then
        echo "[Dry Run] 会写入:"
        echo "$entry"
        echo "---"
      else
        echo "$entry" >> "$EXPERIENCES_FILE"
        extracted=$((extracted + 1))
        echo "[$filename] -> ${exp_id} ✓"
        
        # 移到 archive
        mv "$file" "$PROCESSED_DIR/"
      fi
    fi
  else
    # 非成功记录，标记为已处理但未提取
    if [ "$DRY_RUN" = false ]; then
      mv "$file" "$PROCESSED_DIR/"
    fi
  fi
done

echo ""
echo "处理完成: $processed 条记录，提取 $extracted 条经验"
[ "$DRY_RUN" = true ] && echo "(dry-run 模式，未实际写入)"

exit 0

# 清理超过7天的 pending 记录
cleanup_old_pending() {
    local pending_dir="$1"
    local max_days=7
    
    if [ -d "$pending_dir" ]; then
        local deleted=$(find "$pending_dir" -name "*.json" -mtime +${max_days} -type f 2>/dev/null | wc -l | tr -d ' ')
        if [ "$deleted" -gt 0 ]; then
            find "$pending_dir" -name "*.json" -mtime +${max_days} -type f -delete 2>/dev/null
            echo "[清理] 已删除 $deleted 条超过${max_days}天的记录"
        fi
    fi
}

# 执行清理
cleanup_old_pending "$PENDING_DIR"

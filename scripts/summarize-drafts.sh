#!/bin/bash
# ============================================================
# 经验草稿汇总脚本 - v2.0
# AI 判断草稿是否写入正式经验库
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LEARNINGS_DIR="$HOME/.openclaw/.learnings"
DRAFTS_DIR="$LEARNINGS_DIR/drafts"
ARCHIVE_DIR="$DRAFTS_DIR/archive"
LOG_FILE="$LEARNINGS_DIR/.summarize.log"

mkdir -p "$ARCHIVE_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 检查草稿
DRAFTS=$(find "$DRAFTS_DIR" -name "draft-*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
log "发现 $DRAFTS 个经验草稿"

if [ "$DRAFTS" -eq 0 ]; then
    log "没有草稿需要汇总"
    exit 0
fi

# 读取所有草稿内容，生成提示给 AI
DRAFTS_CONTENT=""
for f in "$DRAFTS_DIR"/draft-*.json; do
    [ -f "$f" ] || continue
    content=$(cat "$f")
    DRAFTS_CONTENT="${DRAFTS_CONTENT}\n---\n${content}"
done

# 生成 AI 提示
cat << AIAVS > /tmp/summarize-prompt.txt
你是一个经验记录审核员。请分析以下草稿，判断哪些值得写入正式经验库。

判断标准：
- 有具体问题描述
- 有独特经验或解决方案
- 值得复用

草稿内容：
$DRAFTS_CONTENT

请对每个草稿输出判断结果，格式：
DRAFT_ID: xxx
值得记录: 是/否
原因: xxx
如果是，输出 record.sh 命令：
record.sh "问题" "踩坑过程" "解决方案" "预防措施" "标签"

如果所有草稿都不值得记录，输出：无需记录
AIAVS

log "草稿已准备好，请使用 AI 读取 /tmp/summarize-prompt.txt 进行判断"

# 标记草稿为待审核
for f in "$DRAFTS_DIR"/draft-*.json; do
    [ -f "$f" ] || continue
    python3 -c "
import json
with open('$f', 'r') as fp:
    d = json.load(fp)
d['status'] = 'pending_review'
d['reviewedAt'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
with open('$f', 'w') as fp:
    json.dump(d, fp, indent=2)
" 2>/dev/null || true
done

log "汇总任务创建完成"

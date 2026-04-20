#!/bin/bash
# rocky-know-how 重建缓存 v2.1
# 支持向量生成：检测 LM Studio / Ollama 自动生成 embedding
# 用法: bash rebuild-cache.sh

set -e

VERSION="2.1"
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
EXPERIENCES_FILE="$STATE_DIR/.learnings/experiences.md"
CACHE_FILE="$STATE_DIR/.learnings/experiences.json"
BACKUP_DIR="$STATE_DIR/.learnings/backups"

mkdir -p "$BACKUP_DIR"

echo "=== 重建缓存 v${VERSION} ==="
echo "源文件: $EXPERIENCES_FILE"
echo "缓存文件: $CACHE_FILE"
echo ""

# 备份旧缓存
if [ -f "$CACHE_FILE" ]; then
    cp "$CACHE_FILE" "$BACKUP_DIR/cache_$(date +%Y%m%d_%H%M%S).json"
fi

# 检查向量模型可用性
check_vector_service() {
    # 检查 LM Studio
    if curl -s http://localhost:1234/v1/models > /dev/null 2>&1; then
        echo "LM_STUDIO"
        return 0
    fi
    # 检查 Ollama
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "OLLAMA"
        return 0
    fi
    return 1
}

VECTOR_SERVICE=""
VECTOR_ENABLED=false

if vector_info=$(check_vector_service); then
    VECTOR_SERVICE="$vector_info"
    VECTOR_ENABLED=true
    echo "✓ 检测到向量服务: $VECTOR_SERVICE"
else
    echo "✗ 未检测到向量服务 (LM Studio/Ollama)，将跳过向量生成"
fi
echo ""

# 解析 Markdown 经验
python3 - "$EXPERIENCES_FILE" "$CACHE_FILE" "$VECTOR_ENABLED" "$SKILL_DIR" << 'PYEOF'
import json
import re
import sys
import os
import time
from datetime import datetime

input_file = sys.argv[1]
output_file = sys.argv[2]
vector_enabled = sys.argv[3].lower() == 'true'
skill_dir = sys.argv[4]

cache = {"entries": {}, "lastUpdate": None}

def extract_section(content, start_marker, end_markers):
    """提取 Markdown 章节内容"""
    lines = content.split('\n')
    result = []
    capture = False
    for line in lines:
        if start_marker in line:
            capture = True
            continue
        if capture:
            for marker in end_markers:
                if line.strip().startswith(marker):
                    return '\n'.join(result).strip()
            result.append(line)
    return '\n'.join(result).strip()

def parse_experience(block):
    """解析单个经验块"""
    exp = {}
    
    # 提取 ID 和标题
    id_match = re.match(r'##\s+\[([^\]]+)\]\s*(.+)', block)
    if id_match:
        exp['id'] = id_match.group(1)
        exp['title'] = id_match.group(2).strip()
    
    # 提取字段
    if '**Area**:' in block:
        exp['area'] = re.search(r'\*\*Area\*\*:\s*(.+)', block).group(1).strip()
    if '**Tags**:' in block:
        exp['tags'] = re.search(r'\*\*Tags\*\*:\s*(.+)', block).group(1).strip()
    
    # 提取问题、解决、预防
    exp['problem'] = extract_section(block, '### 问题', ['###', '---'])
    exp['solution'] = extract_section(block, '### 解决', ['###', '---'])
    exp['prevention'] = extract_section(block, '### 预防', ['---'])
    
    # 统计 failedCount
    failed_count = 0
    if '**Failed-Count**:' in block:
        failed_count_match = re.search(r'\*\*Failed-Count\*\*:\s*(.+)', block)
        if failed_count_match:
            fc = failed_count_match.group(1).strip()
            if '≥2' in fc or '2次' in fc:
                failed_count = 2
    exp['failedCount'] = failed_count
    
    return exp

# 读取并解析
with open(input_file, 'r', encoding='utf-8') as f:
    content = f.read()

# 按 ## 分割经验块
blocks = re.split(r'\n(?=## )', content)

for block in blocks:
    if not block.strip() or not block.startswith('## ['):
        continue
    
    exp = parse_experience(block)
    if not exp.get('id'):
        continue
    
    # 基础数据
    entry = {
        "id": exp['id'],
        "problem": exp.get('problem', ''),
        "solution": exp.get('solution', ''),
        "tags": exp.get('tags', ''),
        "area": exp.get('area', 'general'),
        "failedCount": exp.get('failedCount', 0),
        "useCount": 0,
        "lastUsed": int(time.time()),
        "created": int(time.time()),
        "score": 0.0
    }
    
    cache['entries'][exp['id']] = entry

print(f"解析完成: {len(cache['entries'])} 条经验")

# 生成向量
if vector_enabled and skill_dir:
    vector_script = os.path.join(skill_dir, '_vector.sh')
    if os.path.exists(vector_script) and os.access(vector_script, os.X_OK):
        print(f"\n正在生成向量嵌入...")
        
        def get_embedding(text):
            """调用向量服务生成 embedding"""
            import subprocess
            try:
                result = subprocess.run(
                    ['bash', vector_script, 'embed', text],
                    capture_output=True, text=True, timeout=30
                )
                if result.returncode == 0 and result.stdout.strip().startswith('['):
                    return json.loads(result.stdout.strip())
            except:
                pass
            return None
        
        for exp_id, entry in cache['entries'].items():
            combined_text = f"{entry.get('problem', '')} {entry.get('solution', '')}"
            if combined_text.strip():
                embedding = get_embedding(combined_text)
                if embedding:
                    entry['embedding'] = embedding
                    print(f"  ✓ {exp_id}")
                else:
                    print(f"  ✗ {exp_id} (failed)")
        
        print("向量生成完成")
    else:
        print("向量脚本不可用，跳过")
else:
    print("向量生成已禁用")

# 写入缓存
cache['lastUpdate'] = datetime.utcnow().isoformat() + "Z"
cache['maxEntries'] = 1000

with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(cache, f, ensure_ascii=False, indent=2)

print(f"\n✓ 成功重建缓存: {len(cache['entries'])} 条经验")
PYEOF
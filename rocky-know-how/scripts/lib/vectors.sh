#!/bin/bash
# 向量搜索工具库 v1.0.0
# 依赖 LM Studio embedding API

VECTOR_API="http://localhost:1234/v1/embeddings"
VECTOR_MODEL="text-embedding-nomic-embed-text-v1.5"
VECTOR_DIR=""

# 初始化：设置 VECTOR_DIR 并创建目录
vector_init() {
  local state_dir="${1:-}"
  if [ -z "$state_dir" ]; then
    if [ -n "$OPENCLAW_STATE_DIR" ]; then
      state_dir="$OPENCLAW_STATE_DIR"
    else
      state_dir="$HOME/.openclaw"
    fi
  fi
  VECTOR_DIR="$state_dir/.learnings/vectors"
  mkdir -p "$VECTOR_DIR"
}

# 检测 LM Studio embedding 是否可用
vector_check() {
  curl -s --max-time 3 "$VECTOR_API" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$VECTOR_MODEL\",\"input\":\"health\"}" 2>/dev/null | grep -q '"embedding"'
}

# 调用 API 生成 embedding，输出向量 JSON 数组到 stdout
vector_embed() {
  local text="$1"
  [ -z "$text" ] && return 1
  
  # 用 python3 解析 JSON（macOS/Linux 都有）
  curl -s --max-time 10 "$VECTOR_API" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$VECTOR_MODEL\",\"input\":$(echo "$text" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))')}" \
    2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps(d["data"][0]["embedding"]))'
}

# 计算两个向量的余弦相似度（python3 实现）
vector_cosine() {
  python3 -c "
import json, sys
a = json.loads(sys.argv[1])
b = json.loads(sys.argv[2])
dot = sum(x*y for x,y in zip(a,b))
na = sum(x*x for x in a)**0.5
nb = sum(x*x for x in b)**0.5
print(dot/(na*nb) if na*nb > 0 else 0)
" "$1" "$2"
}

# 追加一条记录到 index.jsonl
vector_index_add() {
  local id="$1" text="$2" area="$3" namespace="$4" tags="$5"
  [ -z "$VECTOR_DIR" ] && vector_init
  local vec
  vec=$(vector_embed "$text") || return 1
  
  local entry=$(python3 -c "
import json
print(json.dumps({'id':'$id','text':'''$text''','vector':json.loads('''$vec'''),'area':'$area','namespace':'$namespace','tags':'$tags'}))
")
  echo "$entry" >> "$VECTOR_DIR/index.jsonl"
}

# 搜索：输入文本 → 生成向量 → 遍历 index.jsonl 计算 cosine → 返回 topN
# 输出格式: score|id|area|text
vector_search() {
  local query="$1" top_n="${2:-5}" threshold="${3:-0.6}"
  [ -z "$VECTOR_DIR" ] && vector_init
  
  local query_vec
  query_vec=$(vector_embed "$query") || return 1
  
  [ ! -f "$VECTOR_DIR/index.jsonl" ] && return 1
  
  # python3 一次性处理：遍历所有条目，计算余弦相似度，输出 topN
  python3 -c "
import json, sys
query_vec = json.loads(sys.argv[1])
threshold = float(sys.argv[2])
top_n = int(sys.argv[3])
results = []
with open(sys.argv[4]) as f:
  for line in f:
    line = line.strip()
    if not line: continue
    entry = json.loads(line)
    doc_vec = entry['vector']
    dot = sum(a*b for a,b in zip(query_vec, doc_vec))
    na = sum(x*x for x in query_vec)**0.5
    nb = sum(x*x for x in doc_vec)**0.5
    score = dot/(na*nb) if na*nb > 0 else 0
    if score >= threshold:
      results.append((score, entry['id'], entry.get('text',''), entry.get('area','')))
results.sort(reverse=True)
for score, eid, text, area in results[:top_n]:
  # 替换 text 中的换行为空格，避免破坏 | 分隔格式
  clean_text = text[:80].replace('\n', ' ').replace('\r', '')
  print(f'{score:.3f}|{eid}|{area}|{clean_text}')
" "$query_vec" "$threshold" "$top_n" "$VECTOR_DIR/index.jsonl"
}

# 从 experiences.md 重建全部索引（python3 直接处理，避免 bash regex 兼容性问题）
vector_reindex_all() {
  local errors_file="${1:-$HOME/.openclaw/.learnings/experiences.md}"
  [ -z "$VECTOR_DIR" ] && vector_init
  [ ! -f "$errors_file" ] && return 1
  
  # 使用 unquoted heredoc 让 bash 变量展开
  python3 << PYEOF
import re, json, sys, os, urllib.request, urllib.error

errors_file = "$errors_file"
vector_dir = "$VECTOR_DIR"
api_url = "$VECTOR_API"
model = "$VECTOR_MODEL"

with open(errors_file, 'r', encoding='utf-8') as f:
    content = f.read()

# 解析所有条目块
pattern = r'## \[EXP-([^\]]+)\]\s*(.*?)(?=\n## \[EXP-|$)'
entries = re.findall(pattern, content, re.DOTALL)

if not entries:
    print('WARNING: No entries found')
    sys.exit(0)

os.makedirs(vector_dir, exist_ok=True)
index_path = os.path.join(vector_dir, 'index.jsonl')

def get_embedding(text):
    payload = json.dumps({'model': model, 'input': text}).encode('utf-8')
    req = urllib.request.Request(api_url, data=payload, headers={'Content-Type': 'application/json'}, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            return data['data'][0]['embedding']
    except Exception as e:
        print('WARNING: embedding failed: ' + str(e), file=sys.stderr)
        return None

count = 0
with open(index_path, 'w', encoding='utf-8') as idx:
    for entry_id, body in entries:
        entry_id = entry_id.strip()
        
        area_match = re.search(r'\*\*Area\*\*:\s*(.+)', body)
        area = area_match.group(1).strip() if area_match else ''
        
        tags_match = re.search(r'\*\*Tags\*\*:\s*(.+)', body)
        tags = tags_match.group(1).strip() if tags_match else ''
        
        ns_match = re.search(r'\*\*Namespace\*\*:\s*(.+)', body)
        namespace = ns_match.group(1).strip() if ns_match else 'global'
        
        problem_lines = [l.strip() for l in body.split('\n') if l.strip() and not l.strip().startswith('**') and not l.strip().startswith('###')]
        problem = problem_lines[0] if problem_lines else ''
        
        solution_match = re.search(r'### 正确方案\n(.+)', body, re.DOTALL)
        solution = solution_match.group(1).strip() if solution_match else ''
        
        text = problem + '\u3002' + solution + '\u3002'
        if tags:
            text += ' Tags: ' + tags
        
        emb = get_embedding(text)
        if emb is None:
            continue
        
        record = {'id': entry_id, 'text': text, 'vector': emb, 'area': area, 'namespace': namespace, 'tags': tags}
        idx.write(json.dumps(record, ensure_ascii=False) + '\n')
        count += 1
        print('  Indexing: ' + str(count), flush=True)

print('DONE: Indexed ' + str(count) + ' entries')
PYEOF
}

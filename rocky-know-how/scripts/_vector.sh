#!/bin/bash
# 向量工具 v1.4.1
# 使用 LM Studio 本地向量模型，失败时自动降级

LM_STUDIO_URL="${LM_STUDIO_URL:-http://localhost:1234}"
EMBEDDING_MODEL="${EMBEDDING_MODEL:-text-embedding-nomic-embed-text-v1.5}"

# 生成向量嵌入
get_embedding() {
  local text="$1"
  
  # 调用 LM Studio API
  response=$(curl -s -X POST "${LM_STUDIO_URL}/v1/embeddings" \
    -H "Content-Type: application/json" \
    -d "{\"input\": \"${text}\", \"model\": \"${EMBEDDING_MODEL}\"}" 2>/dev/null)
  
  if [ $? -eq 0 ] && echo "$response" | grep -q "embedding"; then
    # 提取 embedding 数组
    echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    embedding = data.get('data', [{}])[0].get('embedding', [])
    if embedding:
        print(json.dumps(embedding))
    else:
        print('ERROR: No embedding in response')
except Exception as e:
    print(f'ERROR: {e}')
"
  else
    echo "ERROR: LM Studio API failed"
    return 1
  fi
}

# 计算余弦相似度
cosine_similarity() {
  local vec1="$1"
  local vec2="$2"
  
  python3 -c "
import sys, json, math

v1 = json.loads('$vec1')
v2 = json.loads('$vec2')

if len(v1) != len(v2):
    print('0')
    sys.exit()

dot = sum(a*b for a,b in zip(v1, v2))
norm1 = math.sqrt(sum(a*a for a in v1))
norm2 = math.sqrt(sum(a*a for a in v2))

if norm1 == 0 or norm2 == 0:
    print('0')
else:
    similarity = dot / (norm1 * norm2)
    print(str(similarity))
"
}

# 检查 LM Studio 是否可用
check_lm_studio() {
  curl -s "${LM_STUDIO_URL}/v1/models" > /dev/null 2>&1
  return $?
}

# 主函数
case "$1" in
  check)
    check_lm_studio
    ;;
  embed)
    get_embedding "$2"
    ;;
  similarity)
    cosine_similarity "$2" "$3"
    ;;
  *)
    echo "Usage: $0 {check|embed \"text\"|similarity \"vec1\" \"vec2\"}"
    exit 1
    ;;
esac

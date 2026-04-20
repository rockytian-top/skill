#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Hybrid 搜索：向量 + BM25
- 向量搜索：语义相似度（需要 LM Studio/Ollama）
- BM25：关键词精准匹配（始终工作）
- 综合排序：归一化后加权（向量40% + BM25 60%）
"""

import json
import sys
import math
import re
from collections import Counter

VECTOR_SCRIPT = '/Users/rocky/.openclaw-gateway2/skills/rocky-know-how/scripts/_vector.sh'

# ============== BM25 实现 ==============

def tokenize(text):
    if not text:
        return []
    text = text.lower()
    return re.findall(r'[\w]+', text)

class BM25:
    def __init__(self, documents, k1=1.5, b=0.75):
        self.documents = documents
        self.k1 = k1
        self.b = b
        self.N = len(documents)
        self.avgdl = sum(len(d) for d in documents) / self.N if self.N > 0 else 0
        self.doc_tf = []
        self.doc_df = Counter()
        
        for doc in documents:
            tokens = tokenize(doc)
            tf = Counter(tokens)
            self.doc_tf.append(tf)
            for word in set(tokens):
                self.doc_df[word] += 1
    
    def score(self, query, doc_index):
        doc = self.documents[doc_index]
        tokens = tokenize(doc)
        dl = len(tokens)
        score = 0.0
        for word in tokenize(query):
            if word not in self.doc_tf[doc_index]:
                continue
            tf = self.doc_tf[doc_index][word]
            df = self.doc_df.get(word, 0)
            if df == 0:
                continue
            idf = math.log((self.N - df + 0.5) / (df + 0.5) + 1)
            tf_component = (tf * (self.k1 + 1)) / (tf + self.k1 * (1 - self.b + self.b * dl / self.avgdl))
            score += idf * tf_component
        return score
    
    def get_scores(self, query):
        return [self.score(query, i) for i in range(self.N)]

def normalize(scores):
    if not scores or max(scores) == 0:
        return scores
    min_s, max_s = min(scores), max(scores)
    if max_s == min_s:
        return [1.0 for _ in scores]
    return [(s - min_s) / (max_s - min_s) for s in scores]

# ============== 向量搜索 ==============

def check_vector():
    import subprocess
    try:
        r = subprocess.run(['bash', VECTOR_SCRIPT, 'check'], capture_output=True, timeout=5)
        return r.returncode == 0
    except:
        return False

def get_embedding(text):
    import subprocess
    try:
        r = subprocess.run(['bash', VECTOR_SCRIPT, 'embed', text], capture_output=True, text=True, timeout=30)
        if r.stdout.strip().startswith('['):
            return json.loads(r.stdout.strip())
    except:
        pass
    return None

def cosine_sim(v1, v2):
    dot = sum(a*b for a,b in zip(v1, v2))
    n1 = math.sqrt(sum(a*a for a in v1))
    n2 = math.sqrt(sum(a*a for a in v2))
    if n1 == 0 or n2 == 0:
        return 0
    return dot / (n1 * n2)

# ============== 主逻辑 ==============

if len(sys.argv) < 3:
    print("用法: _hybrid_search.py <缓存文件> <关键词> [最大结果数]")
    sys.exit(1)

cache_file = sys.argv[1]
keyword = sys.argv[2]
max_results = int(sys.argv[3]) if len(sys.argv) > 3 else 10

# 加载缓存
try:
    with open(cache_file, 'r') as f:
        cache = json.load(f)
except Exception as e:
    print(f"读取缓存失败: {e}")
    sys.exit(1)

entries = cache.get('entries', {})
entry_list = list(entries.items())

if not keyword:
    print("请提供搜索关键词")
    sys.exit(1)

# 提取文档文本
doc_texts = [f"{e.get('problem','')} {e.get('solution','')}" for _, e in entry_list]

# BM25 搜索（始终执行）
bm = BM25(doc_texts)
bm_scores = bm.get_scores(keyword)
bm_normalized = normalize(bm_scores)

# 向量搜索（如果可用）
vector_enabled = check_vector()
vector_scores = [0.0] * len(entry_list)

if vector_enabled:
    query_emb = get_embedding(keyword)
    if query_emb:
        for i, (exp_id, entry) in enumerate(entry_list):
            exp_emb = entry.get('embedding')
            if exp_emb:
                vector_scores[i] = cosine_sim(query_emb, exp_emb)

# 归一化向量分数
vector_normalized = normalize(vector_scores) if any(vector_scores) else [0.0] * len(entry_list)

# 综合分数（向量40% + BM25 60%）
hybrid_scores = []
for i in range(len(entry_list)):
    v = vector_normalized[i]
    b = bm_normalized[i]
    hybrid = 0.4 * v + 0.6 * b
    hybrid_scores.append((i, hybrid, v, b))

# 按综合分数排序
hybrid_scores.sort(key=lambda x: x[1], reverse=True)

# 输出结果
for i, (idx, score, v_score, b_score) in enumerate(hybrid_scores[:max_results], 1):
    exp_id, entry = entry_list[idx]
    print(f"=== 结果 {i} ===")
    print(f"ID: {exp_id}")
    print(f"问题: {entry.get('problem','')[:100]}")
    print(f"解决: {entry.get('solution','')[:100]}")
    print(f"标签: {entry.get('tags','')} | 领域: {entry.get('area','')}")
    print(f"综合分数: {score:.3f} (向量:{v_score:.3f} BM25:{b_score:.3f})")
    print()

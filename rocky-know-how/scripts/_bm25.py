#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
BM25 实现（纯Python，无依赖）
基于 Robertson-Sparck Jones 公式
"""

import math
from collections import Counter
import re

def tokenize(text):
    """简单分词"""
    if not text:
        return []
    # 简单中文分词（按字符）+ 英文单词
    text = text.lower()
    # 分词
    words = re.findall(r'[\w]+', text)
    return words

class BM25:
    def __init__(self, documents, k1=1.5, b=0.75):
        """
        documents: list of strings
        k1, b: BM25 参数
        """
        self.documents = documents
        self.k1 = k1
        self.b = b
        self.N = len(documents)
        self.avgdl = sum(len(d) for d in documents) / self.N if self.N > 0 else 0
        
        # 构建词频和文档频率
        self.doc_tf = []  # 每个文档的词频
        self.doc_df = Counter()  # 文档频率
        
        for doc in documents:
            tokens = tokenize(doc)
            tf = Counter(tokens)
            self.doc_tf.append(tf)
            for word in set(tokens):
                self.doc_df[word] += 1
    
    def score(self, query, doc_index):
        """计算 query 对 doc_index 的 BM25 分数"""
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
            
            # IDF
            idf = math.log((self.N - df + 0.5) / (df + 0.5) + 1)
            
            # TF
            tf_component = (tf * (self.k1 + 1)) / (tf + self.k1 * (1 - self.b + self.b * dl / self.avgdl))
            
            score += idf * tf_component
        
        return score
    
    def get_scores(self, query):
        """返回所有文档的 BM25 分数"""
        return [self.score(query, i) for i in range(self.N)]

def bm25_search(query, documents, top_k=10):
    """
    搜索接口
    query: str
    documents: list of str
    返回: list of (index, score)
    """
    if not query or not documents:
        return []
    
    bm = BM25(documents)
    scores = bm.get_scores(query)
    
    # 按分数排序
    results = sorted(enumerate(scores), key=lambda x: x[1], reverse=True)
    
    return results[:top_k]

# 测试
if __name__ == '__main__':
    docs = [
        "SSH连接超时问题解决方案",
        "VPS内存不足导致服务崩溃",
        "Nginx反向代理配置",
        "数据库连接池优化",
        "SSH连接失败的处理方法"
    ]
    
    results = bm25_search("SSH连接", docs)
    print("查询: SSH连接")
    for idx, score in results:
        print(f"  {score:.2f}: {docs[idx][:30]}...")

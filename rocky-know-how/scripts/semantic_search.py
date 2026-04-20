#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
语义搜索增强 - v3.0
理解用户查询意图，提供更精准的搜索结果
"""

import json
import sys
import re

LM_STUDIO_URL = "http://localhost:1234/v1/chat/completions"

def call_llm(prompt, system="你是一个专业的搜索助手。"):
    """调用本地LM Studio"""
    import subprocess
    
    payload = {
        "model": "local-model",
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.3,
        "max_tokens": 300
    }
    
    try:
        result = subprocess.run(
            ["curl", "-s", "-X", "POST", LM_STUDIO_URL,
             "-H", "Content-Type: application/json",
             "-d", json.dumps(payload)],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode == 0:
            response = json.loads(result.stdout)
            return response.get("choices", [{}])[0].get("message", {}).get("content", "")
    except:
        pass
    
    return None

def understand_query(query):
    """
    理解用户查询意图
    
    返回:
    {
        "intent": "search|command|question|unknown",
        "keywords": ["kw1", "kw2"],
        "filters": {"tag": "ssh", "area": "infra"},
        "rewritten_query": "重写后的搜索查询",
        "explanation": "理解说明"
    }
    """
    
    system_prompt = """你是一个专业的搜索分析师。
分析用户的搜索查询，理解其真实意图。

可能的意图：
- search: 用户想搜索某个经验
- command: 用户想执行某个命令（如添加、列出）
- question: 用户在提问
- unknown: 不明确

关键词提取：找出查询中最关键的搜索词

过滤条件：从查询中提取标签、领域等过滤条件

搜索重写：将用户的自然语言重写为更适合搜索的表述

输出格式（JSON）：
{
    "intent": "search|command|question|unknown",
    "keywords": ["关键词1", "关键词2"],
    "filters": {"tag": "标签", "area": "领域"},
    "rewritten_query": "重写后的搜索查询",
    "explanation": "对查询的理解（20字以内）"
}
"""
    
    response = call_llm(query, system_prompt)
    
    if not response:
        # 默认解析
        return {
            "intent": "search",
            "keywords": re.findall(r'[\w]+', query.lower()),
            "filters": {},
            "rewritten_query": query,
            "explanation": "默认搜索"
        }
    
    try:
        result = json.loads(response)
        return result
    except:
        return {
            "intent": "search",
            "keywords": re.findall(r'[\w]+', query.lower()),
            "filters": {},
            "rewritten_query": query,
            "explanation": "解析失败，默认搜索"
        }

def expand_query(query):
    """
    扩展查询词，增加同义词和相关词
    """
    
    system_prompt = """你是一个专业的搜索词扩展专家。
根据用户查询，扩展相关的搜索词。

规则：
- 添加同义词
- 添加相关技术术语
- 添加常见的错误拼写

输出格式（JSON）：
{
    "expanded_keywords": ["词1", "词2", "词3", "词4", "词5"]
}

只返回JSON，不要其他内容。
"""
    
    response = call_llm(f"原始查询: {query}", system_prompt)
    
    if not response:
        return [query]
    
    try:
        result = json.loads(response)
        keywords = result.get("expanded_keywords", [query])
        if query not in keywords:
            keywords.append(query)
        return keywords[:5]
    except:
        return [query]

def interpret_command(query):
    """
    解释用户是否在执行命令
    """
    
    # 常见命令模式
    command_patterns = [
        (r'^add\s+', '添加经验'),
        (r'^record\s+', '记录经验'),
        (r'^search\s+', '搜索经验'),
        (r'^list$', '列出所有'),
        (r'^show\s+', '显示详情'),
        (r'^delete\s+', '删除'),
        (r'^update\s+', '更新'),
    ]
    
    query_lower = query.lower().strip()
    
    for pattern, cmd in command_patterns:
        if re.match(pattern, query_lower):
            return {
                "is_command": True,
                "command": cmd,
                "args": re.sub(pattern, '', query_lower)
            }
    
    return {
        "is_command": False,
        "command": None,
        "args": query
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: semantic_search.py <查询>")
        sys.exit(1)
    
    query = sys.argv[1]
    
    # 1. 理解意图
    understanding = understand_query(query)
    
    # 2. 解释命令
    command = interpret_command(query)
    
    # 3. 扩展查询
    expanded = expand_query(query)
    
    # 输出结果
    result = {
        "original_query": query,
        "understanding": understanding,
        "command": command,
        "expanded_keywords": expanded
    }
    
    print(json.dumps(result, ensure_ascii=False, indent=2))

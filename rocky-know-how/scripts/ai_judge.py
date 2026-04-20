#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI判断模块 - v3.0
判断内容是否值得记录，以及应该归类到哪种知识类型
"""

import json
import sys
import subprocess

LM_STUDIO_URL = "http://localhost:1234/v1/chat/completions"
LM_STUDIO_MODEL = "local-model"

def call_llm(prompt, system="你是一个专业的知识管理助手。"):
    """调用本地LM Studio进行判断"""
    payload = {
        "model": LM_STUDIO_MODEL,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.3,
        "max_tokens": 500
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
    except Exception as e:
        print(f"LLM调用失败: {e}", file=sys.stderr)
    
    return None

def judge_content(content, context=""):
    """
    判断内容是否值得记录，以及知识类型
    
    返回:
    {
        "worthy": true/false,
        "type": "experience|decision|api|project|contact|other",
        "summary": "内容摘要",
        "tags": ["tag1", "tag2"],
        "reason": "判断理由",
        "links": ["相关经验ID列表"]
    }
    """
    
    system_prompt = """你是一个专业的知识管理助手。
根据用户提供的对话内容，判断是否值得记录到知识库。

知识类型：
- experience: 技术经验、踩坑记录、解决方案
- decision: 重大决策、方案选择、架构决定
- api: API接口、技术文档
- project: 项目相关、里程碑、任务
- contact: 联系人、人物信息
- other: 不值得记录的内容

输出格式（JSON）：
{
    "worthy": true/false,
    "type": "experience|decision|api|project|contact|other",
    "summary": "50字以内的内容摘要",
    "tags": ["标签1", "标签2"],
    "reason": "判断理由（20字以内）",
    "confidence": 0.0-1.0
}

注意：
- 只有真正有价值的经验才worthy=true
- 简单的问候、寒暄不需要记录
- 重复的问题如果已有解决方案，worthy=false
"""
    
    user_prompt = f"""
对话内容：{content}
上下文：{context}

请判断：
"""
    
    response = call_llm(user_prompt, system_prompt)
    
    if not response:
        # 默认值：保守判断
        return {
            "worthy": False,
            "type": "other",
            "summary": content[:50],
            "tags": [],
            "reason": "LLM不可用，默认不记录",
            "confidence": 0.0
        }
    
    try:
        # 解析JSON响应
        result = json.loads(response)
        return result
    except:
        return {
            "worthy": False,
            "type": "other", 
            "summary": content[:50],
            "tags": [],
            "reason": "解析失败，默认不记录",
            "confidence": 0.0
        }

def extract_decision(content):
    """
    专门提取决策信息
    
    返回:
    {
        "problem": "决策问题",
        "options": ["选项1", "选项2"],
        "decision": "最终选择",
        "reason": "选择原因"
    }
    """
    
    system_prompt = """你是一个专业的决策分析师。
从对话内容中提取决策信息。

输出格式（JSON）：
{
    "problem": "需要决策的问题（50字以内）",
    "options": ["选项1", "选项2"],
    "decision": "最终决策（20字以内）",
    "reason": "决策原因（50字以内）"
}

如果没有明确的决策，返回null。
"""
    
    user_prompt = f"对话内容：{content}\n\n请提取决策信息："
    
    response = call_llm(user_prompt, system_prompt)
    
    if not response:
        return None
    
    try:
        result = json.loads(response)
        if result.get("problem"):
            return result
    except:
        pass
    
    return None

def find_related_experiences(content, existing_experiences):
    """
    找到与当前内容相关的已有经验
    
    返回: 相关经验ID列表
    """
    
    if not existing_experiences:
        return []
    
    # 构建相关经验的摘要列表
    exp_summaries = []
    for exp_id, exp in existing_experiences.items():
        summary = f"{exp_id}: {exp.get('problem', '')[:50]}"
        exp_summaries.append(summary)
    
    system_prompt = """你是一个专业的知识分析师。
给定新内容和已有经验列表，找出与新内容相关的已有经验。

输出格式（JSON）：
{
    "related": ["EXP-ID-1", "EXP-ID-2"],  // 相关经验ID列表，最多3个
    "relationship": "与已有经验的关系说明（30字以内）"
}

注意：
- 只返回真正相关的经验
- 如果没有相关经验，返回空列表
"""
    
    exp_list = "\n".join(exp_summaries[:20])  # 限制数量
    user_prompt = f"新内容：{content[:200]}\n\n已有经验：\n{exp_list}\n\n请找出相关的已有经验："
    
    response = call_llm(user_prompt, system_prompt)
    
    if not response:
        return []
    
    try:
        result = json.loads(response)
        related = result.get("related", [])
        if isinstance(related, list):
            return related[:3]  # 最多3个
    except:
        pass
    
    return []

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: ai_judge.py <内容>")
        sys.exit(1)
    
    content = sys.argv[1]
    context = sys.argv[2] if len(sys.argv) > 2 else ""
    
    result = judge_content(content, context)
    print(json.dumps(result, ensure_ascii=False, indent=2))

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LRU 淘汰：当经验超过 maxEntries 时，自动清理最久没用到的
"""

import json
import sys
import os
from datetime import datetime

def lru_cleanup(cache_file, max_entries=1000, keep_min=50):
    """
    LRU 淘汰
    - 保留最近使用最多的经验
    - 删除长期未使用的经验
    - 至少保留 keep_min 条
    """
    with open(cache_file, 'r') as f:
        cache = json.load(f)
    
    entries = cache.get('entries', {})
    current_count = len(entries)
    
    if current_count <= max_entries:
        return current_count, 0
    
    # 计算需要删除的数量
    to_remove = current_count - max_entries
    
    # 按 lastUsed 排序（最久没用排在前面），然后按 useCount 排序
    # useCount 越少且 lastUsed 越旧，越容易被删除
    candidates = []
    for exp_id, entry in entries.items():
        use_count = entry.get('useCount', 0)
        last_used = entry.get('lastUsed', 0)
        # 综合评分：(useCount * 1000 - lastUsed) 越小越先删除
        score = use_count * 1000000 - last_used
        candidates.append((score, exp_id, entry))
    
    # 按评分排序
    candidates.sort(key=lambda x: x[0])
    
    # 删除最久没用且使用次数最少的
    removed = []
    for score, exp_id, entry in candidates[:to_remove]:
        del entries[exp_id]
        removed.append(exp_id)
    
    # 更新缓存
    cache['entries'] = entries
    cache['lastUpdate'] = datetime.utcnow().isoformat() + "Z"
    
    with open(cache_file, 'w') as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)
    
    return len(entries), len(removed)

if __name__ == '__main__':
    cache_file = sys.argv[1] if len(sys.argv) > 1 else '/Users/rocky/.openclaw-gateway2/.learnings/experiences.json'
    max_entries = int(sys.argv[2]) if len(sys.argv) > 2 else 1000
    
    remaining, removed = lru_cleanup(cache_file, max_entries)
    print(f"LRU 淘汰完成: 剩余 {remaining} 条，删除 {removed} 条")

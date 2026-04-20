# 📋 更新日志 / Changelog

All notable changes to this project will be documented in this file.

## [3.0] - 2026-04-20

### 🎉 新功能 / New Features
- **AI自动判断** - ai_judge.py 判断内容是否值得记录
- **决策记录** - decision.sh 记录重大决策和原因
- **自动关联** - auto_link.sh 新经验自动关联已有知识
- **语义搜索增强** - semantic_search.py 理解用户查询意图

### 🔧 改进 / Improvements
- 搜索支持意图识别
- 新经验自动关联相关已有知识
- 支持按决策类型筛选

### 📦 新增脚本
- `ai_judge.py` - AI判断模块
- `decision.sh` - 决策记录管理
- `auto_link.sh` - 自动关联知识
- `semantic_search.py` - 语义搜索增强

---

## [2.5] - 2026-04-20

### 🎉 新功能 / New Features
- **Hybrid搜索** - 向量搜索(40%) + BM25关键词搜索(60%)
- **纯Python实现** - 跨平台兼容，Windows/Linux/Mac全部支持

### 🔧 改进 / Improvements
- 向量搜索支持语义匹配
- BM25支持中英文混合分词
- 简化代码，去除不必要的C扩展

### 📦 脚本更新
- `_hybrid_search.py` - Hybrid搜索核心
- `_vector.sh` - 向量计算脚本
- `_lru_cleanup.py` - LRU缓存清理

---

## [2.0.0] - 2026-04-20

### 🎉 新功能 / New Features
- **智能缓存系统** - experiences.json 支持 1000 条经验毫秒级搜索
- **评分与淘汰机制** - 基于使用次数和新鲜度的评分公式
- **版本控制** - 每个经验保留 v1/v2... 多版本，可回退
- **自动提取** - auto-extract.sh 从 pending 记录自动提取经验
- **重建缓存** - rebuild-cache.sh 从 experiences.md 重建缓存

### 🔧 改进 / Improvements
- search.sh 支持 --tag、--area 过滤
- 搜索结果按 score 排序
- 更详细的缓存状态显示

### 🐛 修复 / Bug Fixes
- 移除硬编码路径，改为动态获取 OPENCLAW_STATE_DIR
- 修复 Python import 语句位置错误

---

## [1.3.6] - 2026-04-06

### 🎉 新功能 / New Features
- 多网关实例支持
- 动态获取 OPENCLAW_STATE_DIR

---

## [1.3.5] - 2026-04-01

### 🔧 改进 / Improvements
- record.sh 去重逻辑优化
- search.sh 搜索算法改进

---

## [1.3.0] - 2026-03-25

### 🎉 新功能 / New Features
- 支持 --tag、--area 过滤
- 支持 --global 跨 workspace 搜索
- stats.sh 统计面板

---

## [1.0.0] - 2026-03-20

### 🎉 初始版本 / Initial Release
- 基础搜索功能
- 手动记录功能
- Hook 注入提醒

---

_格式参考 [Keep a Changelog](https://keepachangelog.com/)_

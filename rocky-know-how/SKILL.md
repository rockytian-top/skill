---
name: rocky-know-how
slug: rocky-know-how
version: 3.0.0
homepage: https://clawhub.ai/skills/rocky-know-how
description: "Learning knowledge skill v3.0.0 — Full Auto-Closed-Loop experience system. 4-event Hook integration (bootstrap/compaction/reset), LLM dual-judgment, triple-layer storage (HOT/WARM/COLD), auto-promotion/demotion. Tested & verified: deepseek-v4, glm-5.1, minimax-m2.7. Safety: regex injection prevention, path traversal filtering, concurrent write lock."

metadata: {"openclaw":{"emoji":"📚","requires":{"bins":["bash"]},"os":["darwin","linux"]}}
---

# rocky-know-how v3.0.0

**Experience & Knowledge Auto-Learning System for OpenClaw Agents**

> 让 AI Agent 从失败中学习，在成功后自动记录，形成经验闭环。

---

## 🎯 When to Use / 适用场景

| Scenario 场景 | Action 操作 |
|---------------|-------------|
| Failed 2+ times 失败≥2次 | `bash scripts/search.sh "关键词"` |
| Solved after failures 解决后 | `bash scripts/record.sh "问题" "踩坑" "方案" "预防" "tags" "area"` |
| Auto on compaction 压缩时 | **Fully automatic** — Hook extracts context → LLM judges → writes |
| Auto on reset 重置时 | **Fully automatic** — Hook saves pending context |
| Tag used 3x/7days 晋升 | `bash scripts/promote.sh` |
| Tag unused 30days 降级 | `bash scripts/demote.sh` |

---

## 🏗️ Architecture / 架构

### Triple-Layer Storage / 三层存储

```
~/.openclaw/.learnings/
├── experiences.md    ← Main data (v1 compatible, all experiences)
├── memory.md         ← HOT layer (≤100 lines, always loaded)
├── domains/          ← WARM layer (by area: infra, code, wx...)
│   ├── infra.md
│   ├── code.md
│   └── global.md
├── projects/         ← WARM layer (by project)
├── archive/          ← COLD layer (90+ days)
├── drafts/           ← Auto-generated drafts (LLM judged)
├── pending/          ← Session context (before processing)
└── corrections.md    ← Correction log (auto-dedup)
```

### 4-Event Hook Integration / 四事件驱动

| Event 事件 | Trigger 触发 | Function 功能 |
|-----------|-------------|---------------|
| `agent:bootstrap` | Agent startup 启动 | Inject experience reminder into systemPrompt |
| `before_compaction` | Before context compression 压缩前 | Extract task/tools/errors → save to pending/ + auto-search |
| `after_compaction` | After compression 压缩后 | **Core: LLM dual-judge → draft → create/append → archive** |
| `before_reset` | Before session reset 重置前 | Save context as pending (fallback) |

---

## 🔄 Full Auto-Closed-Loop / 全自动闭环

```
Agent Session (对话中)
    │
    ▼
before_compaction (handler.js:978)
    ├─ extractContextFromMessages() → task, tools, errors
    ├─ savePendingLearnings() → pending/*.json
    └─ autoSearch() → inject related experiences
    │
    ▼
after_compaction (handler.js:1014)
    ├─ resolveProviderInfo() → get LLM provider (with OAuth support)
    │
    ├─ processPendingItem() (handler.js:678)
    │   │
    │   ├─ No provider → Keyword fallback
    │   │   ├─ Similar found → append-record.sh
    │   │   └─ No similar → record.sh
    │   │
    │   └─ Has provider → LLM Dual-Judgment
    │       ├─ callLLMJudge() → worth=true?
    │       │   └─ Yes → writeDraftWithJudge()
    │       └─ decideCreateOrAppend()
    │           ├─ append → append-record.sh
    │           └─ create → record.sh
    │
    ├─ runAutoReview() → background audit
    ├─ Archive pending → pending/archive/
    └─ Cleanup temp files
    │
    ▼
before_reset (handler.js:1095)
    └─ savePendingLearnings() → fallback save
```

---

## 🛡️ Safety & Security / 安全机制

| Mechanism 机制 | Implementation 实现 |
|---------------|-------------------|
| Regex injection prevention 正则注入防护 | `escape_grep()` sed escaping |
| Path traversal filtering 路径穿越过滤 | `replace(/[^a-zA-Z0-9_-]/g, '')` |
| Concurrent write lock 并发写锁 | `.write_lock/` directory atomic lock |
| Tag dedup promotion Tag去重晋升 | record.sh dedup + promote.sh threshold |
| Graceful degradation 降级容错 | LLM → keyword → write fallback chain |

---

## 📊 Scripts Reference / 脚本说明

| Script 脚本 | Lines 行数 | Function 功能 |
|------------|:----------:|--------------|
| handler.js | 1,110 | Core hook handler (4 events, LLM integration) |
| search.sh | 539 | Search experiences (keyword / preview / all) |
| record.sh | 476 | Write new experience (with dedup & lock) |
| demote.sh | 371 | Demote HOT tags to WARM |
| compact.sh | 348 | Compress layers when exceeding limits |
| clean.sh | 247 | Remove test/invalid entries |
| vectors.sh | 232 | Vector search via LM Studio embeddings |
| promote.sh | 185 | Promote WARM tags to HOT (≥3x/7days) |
| import.sh | 172 | Import experiences from other sources |
| archive.sh | 167 | Archive old experiences to COLD |
| install.sh | 161 | Install skill to workspace |
| stats.sh | 153 | Show statistics dashboard |
| auto-review.sh | 136 | Auto-review pending drafts |
| append-record.sh | 100 | Append solution to existing experience |
| summarize-drafts.sh | 80 | Summarize and process drafts |
| update-record.sh | 77 | Update existing experience |
| common.sh | 41 | Shared utility functions |
| uninstall.sh | 37 | Remove skill |
| **Total 共计** | **4,632** | |

---

## ✅ Verified Testing / 测试验证

### Models Tested / 已测试模型

| Model 模型 | Provider | Forward Test 正向 | Reverse Test 逆向 | Status |
|-----------|----------|:-----------------:|:-----------------:|:------:|
| deepseek-v4 | deepseek (api-key) | ✅ Pass | ✅ Pass (144/150) | Verified |
| glm-5.1 | zai (api-key) | ✅ Pass | ✅ Pass (146/150) | Verified |
| MiniMax-M2.7-highspeed | minimax-portal (OAuth) | ✅ Pass | ✅ Pass (146/150) | Verified |

### Test Coverage / 测试覆盖

| Test 测试 | Result 结果 |
|----------|:----------:|
| agent:bootstrap → systemPrompt injection | ✅ 12→952 chars |
| before_compaction → pending save | ✅ task/tools/errors extracted |
| after_compaction → LLM dual-judge → write | ✅ EXP auto-created |
| before_reset → fallback save | ✅ pending saved |
| record.sh write + search | ✅ Write & find |
| auto-review.sh process draft | ✅ Draft → archive |
| compact.sh dry-run | ✅ All layers healthy |
| promote.sh tag promotion | ✅ Threshold check |
| stats.sh dashboard | ✅ Full panel |
| 5 safety mechanisms | ✅ All present |

---

## 🚀 Installation / 安装

```bash
# Clone
git clone https://gitee.com/rocky_tian/skill.git
cd skill/rocky-know-how

# Install
bash scripts/install.sh

# Verify
bash scripts/stats.sh
```

---

## 📈 Key Advantages / 核心优势

1. **Zero-config auto-learning** — Hook events automatically capture experience, no manual trigger needed
2. **LLM dual-judgment** — First judges if worth saving, then decides create vs append
3. **Triple degradation** — LLM → keyword → write, never loses data
4. **Multi-provider** — Supports OpenAI, Anthropic, OAuth providers (zai/stepfun/minimax)
5. **Production proven** — 45+ real experiences, 2.6MB data, stable operation
6. **Safety first** — 5 security mechanisms (regex injection, path traversal, write lock, etc.)

---

_Version: 3.0.0 | Tested: 2026-04-24 | License: MIT_

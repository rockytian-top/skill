# rocky-know-how 发布清单

**版本**: v3.0.0
**仓库**: https://gitee.com/rocky_tian/skill

---

## 三平台发布格式

### 1. Gitee / GitHub (Git仓库)

直接 `git push`，包含完整文件：

```
rocky-know-how/
├── SKILL.md           # 技能说明（Frontmatter格式）
├── _meta.json         # ⚠️ 版本号必须更新！
├── VERSION            # 版本文件
├── README.md          # 中文说明
├── README_EN.md       # 英文说明
├── scripts/           # 18个脚本（4,632行代码）
│   ├── search.sh (539行)
│   ├── record.sh (476行)
│   ├── demote.sh (371行)
│   ├── compact.sh (348行)
│   ├── clean.sh (247行)
│   ├── vectors.sh (232行)
│   ├── promote.sh (185行)
│   ├── import.sh (172行)
│   ├── archive.sh (167行)
│   ├── install.sh (161行)
│   ├── stats.sh (153行)
│   ├── auto-review.sh (136行)
│   ├── append-record.sh (100行)
│   ├── summarize-drafts.sh (80行)
│   ├── update-record.sh (77行)
│   ├── common.sh (41行)
│   ├── uninstall.sh (37行)
│   └── handler.js (1110行核心Hook)
└── hooks/
    └── openclaw/
        ├── HOOK.md
        └── handler.js
```

---

## 版本更新检查清单

每次发布前检查：

| 文件 | 字段 | 要求 |
|------|------|------|
| SKILL.md | `version` | v3.0.0 |
| _meta.json | `version` | v3.0.0 |
| VERSION | 内容 | 3.0.0 |
| handler.js | `@version` | 3.0.0 |
| HOOK.md | description | v3.0.0 |

---

## 当前状态 (v3.0.0)

### 文件清理 ✅
- [x] 删除 search.sh.bak
- [x] 删除陈旧文档：CHANGELOG.md, HEARTBEAT.md, boundaries.md, corrections.md, heartbeat-rules.md, heartbeat-state.md, learning.md, memory-template.md, memory.md, operations.md, reflections.md, scaling.md, setup.md
- [x] 删除旧版 hooks/handler.js（289行旧版）
- [x] 保留核心文件：SKILL.md, README, scripts, hooks/openclaw

### 代码同步 ✅
- [x] handler.js: 1110行（最新v3.0.0）
- [x] HOOK.md: v3.0.0
- [x] 4个新脚本：append-record.sh, auto-review.sh, summarize-drafts.sh, update-record.sh
- [x] 12个更新脚本：全部同步最新

### 文档更新 ✅
- [x] SKILL.md: v3.0.0 中英文
- [x] README.md: v3.0.0 中文
- [x] README_EN.md: v3.0.0 英文
- [x] _meta.json: version = 3.0.0
- [x] VERSION: 3.0.0

### 三大模型验证 ✅
| 模型 | 正向测试 | 逆向测试 |
|------|:--------:|:--------:|
| deepseek-v4 | ✅ | 144/150 |
| glm-5.1 | ✅ | 146/150 |
| minimax-m2.7 | ✅ | 146/150 |

### 推送状态 ✅
- [x] Gitee: https://gitee.com/rocky_tian/skill - 已推送
- [x] GitHub: https://github.com/rocky-tian/skill - 已推送
- [x] ClawHub: https://clawhub.ai/skills/rocky-know-how - 自动从GitHub读取

### Git Tag ✅
- [x] git tag v3.0.0
- [x] git push origin v3.0.0
- [x] git push github v3.0.0

---

_最后更新: 2026-04-24 19:15 Asia/Shanghai_

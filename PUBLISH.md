# rocky-know-how 发布清单

**版本**: v2.7.1
**仓库**: https://gitee.com/rocky_tian/skill

---

## 三平台发布格式

### 1. Gitee / GitHub (Git仓库)

直接 `git push`，包含完整文件：

```
rocky-know-how/
├── SKILL.md           # 技能说明（Frontmatter格式）
├── _meta.json         # ⚠️ 版本号必须更新！
├── README.md          # 中文说明
├── README_EN.md       # 英文说明
├── CHANGELOG.md       # 变更日志
├── scripts/           # 所有脚本
│   ├── search.sh
│   ├── record.sh
│   ├── stats.sh
│   ├── promote.sh
│   ├── demote.sh
│   ├── compact.sh
│   ├── clean.sh
│   ├── archive.sh
│   ├── import.sh
│   ├── install.sh
│   └── uninstall.sh
├── hooks/
│   └── handler.js
└── *.md              # 其他文档
```

**发布命令**:
```bash
git add -A
git commit -m "v2.7.1: 更新说明"
git tag v2.7.1 -m "v2.7.1"
git push origin main
git push origin v2.7.1
git push github main
git push github v2.7.1
```

---

### 2. ClawHub (技能市场)

从 GitHub 读取，**必须包含**：

```
rocky-know-how/
├── SKILL.md           # ✅ Frontmatter格式（name/slug/version/description）
├── _meta.json         # ⚠️ version字段必须与SKILL.md一致！
├── README.md          # 中文说明
├── scripts/           # 可执行脚本
├── hooks/             # 钩子（可选）
└── *.md               # 文档
```

**⚠️ 关键检查点**:

1. **SKILL.md** 必须包含:
```yaml
---
name: rocky-know-how
slug: rocky-know-how
version: 2.7.1
description: "技能描述"
---
```

2. **_meta.json** 版本必须一致:
```json
{
  "version": "2.7.1"
}
```

3. **scripts/** 必须有执行权限:
```bash
chmod +x scripts/*.sh
```

---

## 版本更新检查清单

每次发布前检查：

| 文件 | 字段 | 要求 |
|------|------|------|
| SKILL.md | `version` | v2.7.1 |
| _meta.json | `version` | v2.7.1 |
| CHANGELOG.md | 最新版本 | v2.7.1 |
| git tag | tag名 | v2.7.1 |

---

## 当前状态 (v2.7.1)

- [x] SKILL.md: version = 2.7.1
- [x] _meta.json: version = 2.7.1
- [x] CHANGELOG.md: v2.7.1
- [x] git tag: v2.7.1
- [x] Gitee: 已推送
- [x] GitHub: 已推送
- [ ] ClawHub: 等待自动更新（刷新页面）


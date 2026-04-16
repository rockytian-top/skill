# rocky-know-how — OpenClaw 经验诀窍技能

**版本**: 1.2.0 | **类型**: OpenClaw 技能 + Hook | **许可**: MIT

## 介绍

失败≥2次搜经验诀窍，解决后写入。写入时同步到原生 memory，**原生 memory_search 自动能搜到**。

## 核心逻辑

```
接到任务 → 正常执行
    ↓
失败≥2次 → 搜经验诀窍
    ├── 有答案 → 按答案执行
    └── 没答案 → 继续尝试直到成功
    ↓
成功后 → 写入经验诀窍 + 同步到 memory/*.md
    ↓
同Tag≥3次 → 晋升为铁律
```

## 存储

全局共享: `~/.openclaw/.learnings/experiences.md`（所有 agent 通用）

## 工具脚本

| 脚本 | 用途 |
|------|------|
| `search.sh "关键词"` | 搜经验诀窍 |
| `record.sh "问题" "踩坑" "方案" "预防" "tags"` | 写入+同步 |
| `stats.sh` | 统计面板 |
| `promote.sh` | Tag晋升检查 |
| `archive.sh [--days N]` | 归档旧条目 |

## 安装

```bash
# GitHub
git clone https://github.com/rockytian-top/openclaw-rocky-skills.git
cd openclaw-rocky-skills
bash scripts/install.sh

# 国内镜像
git clone https://gitee.com/rocky_tian/skill.git
```

## Hook 配置

在 `openclaw.json` 中添加 hooks 配置，参见 `hooks/openclaw/HOOK.md`

## 兼容性

- ✅ Node.js 18+（CommonJS）
- ✅ macOS / Linux

## License

MIT

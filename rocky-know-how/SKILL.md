# 🎯 Skill Metadata

## 基本信息 / Basic Info

| 属性 | 值 |
|------|-----|
| 名称 | rocky-know-how |
| 版本 | 2.5 |
| 类型 | skill |
| Emoji | 📚 |

## 事件监听 / Event Listeners

| 事件 | 说明 |
|------|------|
| `agent:bootstrap` | Agent 启动时注入使用提醒 |
| `agent:shutdown` | Agent 关闭时记录任务结果 |

## 文件结构 / File Structure

```
rocky-know-how/
├── SKILL.md          # 本文件
├── README.md         # 技能文档
├── CHANGELOG.md     # 更新日志
├── _meta.json       # 元数据
├── hooks/
│   └── openclaw/
│       ├── HOOK.md   # Hook 配置说明
│       └── handler.js # Hook 处理器
└── scripts/
    ├── install.sh      # 安装脚本
    ├── uninstall.sh    # 卸载脚本
    ├── search.sh       # 搜索脚本
    ├── record.sh       # 记录脚本
    ├── auto-extract.sh # 自动提取脚本
    ├── rebuild-cache.sh # 重建缓存脚本
    ├── stats.sh        # 统计脚本
    ├── promote.sh      # 晋升脚本
    ├── import.sh       # 导入脚本
    ├── archive.sh      # 归档脚本
    └── clean.sh        # 清理脚本
```

## 依赖 / Dependencies

- Node.js 16+
- Bash 4+
- OpenClaw Gateway

## 安装后大小 / Installed Size

- 技能代码：~50KB
- 缓存（空）：~1KB
- 缓存（1000条经验）：~600KB

---

_元数据版本: 2.5_
_最后更新: 2026-04-20_

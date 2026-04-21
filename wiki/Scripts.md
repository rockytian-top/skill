# 脚本说明

## 核心脚本

| 脚本 | 用途 |
|------|------|
| `search.sh` | 搜索经验诀窍 |
| `record.sh` | 写入经验诀窍 |
| `promote.sh` | 自动晋升（Tag≥3次/HOT） |
| `demote.sh` | 降级（30天未用→WARM） |
| `compact.sh` | 压缩存储 |
| `clean.sh` | 清理测试条目 |
| `stats.sh` | 统计面板 |
| `import.sh` | 从 memory/*.md 导入 |

## search.sh 用法

```bash
# 关键词搜索（空格自动拆分）
search.sh "SSH 连不上"

# 按标签搜索
search.sh --tag "nginx"

# 按领域搜索
search.sh --domain infra

# 按项目搜索
search.sh --project wx.newstt

# 查看全部
search.sh --all

# 摘要模式
search.sh --preview "关键词"
```

## record.sh 用法

```bash
# 全局经验
record.sh "问题" "踩坑" "方案" "预防" "tags" infra

# 领域经验
record.sh --namespace domain "问题" "踩坑" "方案" "预防" "tags" infra

# 项目经验
record.sh --namespace project "问题" "踩坑" "方案" "预防" "tags" wx.newstt

# 预览模式（不写入）
record.sh --dry-run "问题" "踩坑" "方案" "预防" "tags" infra
```

## 安装后脚本路径

安装后所有脚本在 `~/.openclaw/.learnings/scripts/`。

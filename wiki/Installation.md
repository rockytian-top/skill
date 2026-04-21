# 安装指南

## 环境要求

- macOS / Linux / Windows (Git Bash)
- bash 3.x+
- 磁盘空间：≥10MB

## 安装方式

### 方式1：ClawHub（推荐）

```bash
openclaw skills install rocky-know-how
```

### 方式2：手动安装

```bash
git clone https://github.com/rockytian-top/skill.git
cd skill/rocky-know-how
bash scripts/install.sh
```

## 安装后验证

install.sh 会自动配置 Hook（添加到 openclaw.json 的 extraDirs），无需手动配置。

验证安装成功：
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/stats.sh
```

## 卸载

```bash
cd skill/rocky-know-how
bash scripts/uninstall.sh
# 注意：保留 ~/.openclaw/.learnings/ 数据
```

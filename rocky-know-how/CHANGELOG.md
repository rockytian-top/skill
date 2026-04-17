# Changelog

## [1.3.4] - 2026-04-18

### Security
- install.sh: 移除 python3 执行和 gateway restart，改为纯文件操作 + 手动配置提示 / Removed python3 execution and gateway restart, pure file ops + manual config
- uninstall.sh: 移除配置文件修改，改为手动提示 / Removed config file modification, manual instructions

### Changed
- install.sh 不再自动修改 openclaw.json，输出配置说明让用户手动添加 / No longer auto-modifies openclaw.json, prints instructions

## [1.3.3] - 2026-04-17

### Added
- README 增加详细介绍：这是什么、工作原理、条目示例 / Added detailed introduction, workflow, entry example
- 合并中英文为单个 README / Merged CN/EN into single README

## [1.3.2] - 2026-04-17

### Fixed
- tag 精确匹配：用逗号包裹防止 `app` 匹配到 `apple` / Exact tag matching with comma delimiter
- record.sh 去重逻辑：修复 grep -B0 无效参数 / Fixed dedup logic
- promote.sh awk：用 while+getline 替代固定循环 / Rewritten with while+getline
- archive.sh 布尔模式：避免子 shell 字符串问题 / Fixed boolean mode
- clean.sh --reindex：保留原始创建日期 / Preserve original dates
- install.sh 安全：python3 用 sys.argv 传参 / Safer python3 invocation

## [1.3.0] - 2026-04-17

### Added
- search.sh: 相关度评分排序 / Relevance scoring
- search.sh: --tag / --area / --since / --preview 筛选 / Filters
- import.sh: 从 memory/*.md 批量导入 / Batch import
- archive.sh: --auto 静默模式 / Silent auto mode
- Dreaming 整合标记 / Dreaming integration markers
- 跨 workspace 动态路径 / Cross-workspace dynamic paths

## [1.2.0] - 2026-04-16

### Changed
- macOS bash 3.x 兼容性修复 / macOS bash 3.x compatibility

# Changelog

## [1.3.6] - 2026-04-18

### Changed
- **支持多网关实例**: 所有脚本和 handler.js 动态获取 `OPENCLAW_STATE_DIR`，不再硬编码 `~/.openclaw/`
- 网关1 (`~/.openclaw`) 和网关2 (`~/.openclaw-gateway2`) 完全独立，各自有各自的 `.learnings/` 数据
- 所有文件版本号统一到 1.3.6（SKILL.md, HOOK.md, handler.js, _meta.json, README）

## [1.3.5] - 2026-04-18

### Fixed
- 根目录 README 版本号与实际版本同步
- CHANGELOG.md 完整更新
- ClawHub origin.json 版本同步

## [1.3.4] - 2026-04-18

### Security
- install.sh: 移除 python3 执行和 gateway restart，改为纯文件操作 + 手动配置提示
- uninstall.sh: 移除配置文件修改，改为手动提示

## [1.3.3] - 2026-04-17

### Added
- README 增加详细介绍：这是什么、工作原理、条目示例
- 合并中英文为单个 README

## [1.3.2] - 2026-04-17

### Fixed
- tag 精确匹配、去重逻辑、promote awk、archive 布尔模式、reindex 保留日期、install 安全

## [1.3.0] - 2026-04-17

### Added
- 相关度评分排序、--tag/--area/--since/--preview 筛选
- import.sh 批量导入、archive --auto、Dreaming 整合、跨 workspace 动态路径

## [1.2.0] - 2026-04-16

### Changed
- macOS bash 3.x 兼容性修复

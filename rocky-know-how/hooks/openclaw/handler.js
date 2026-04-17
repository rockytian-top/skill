/**
 * rocky-know-how Hook for OpenClaw v1.3.0
 *
 * Agent 启动时注入经验诀窍技能提醒。
 * 动态获取工作区路径，适配所有用户环境。
 * 共享路径：~/.openclaw/.learnings/
 */

const { existsSync } = require('fs');
const { join } = require('path');

/**
 * 从 sessionKey 提取 agent ID 并构造工作区路径
 */
function getWorkspace(sessionKey, env) {
  if (env.OPENCLAW_WORKSPACE) {
    return env.OPENCLAW_WORKSPACE;
  }
  if (sessionKey && typeof sessionKey === 'string') {
    const parts = sessionKey.split(':');
    if (parts.length >= 2 && parts[0] === 'agent') {
      const home = env.HOME || process.env.HOME || '~';
      return `${home}/.openclaw/workspace-${parts[1]}`;
    }
  }
  const home = env.HOME || process.env.HOME || '~';
  return `${home}/.openclaw/workspace`;
}

/**
 * 动态定位 scripts 目录
 * 支持多种安装方式和跨 workspace 共享
 */
function findScriptsDir(workspace) {
  const candidates = [
    // 标准安装: workspace/skills/rocky-know-how/scripts
    join(workspace, 'skills', 'rocky-know-how', 'scripts'),
    // 嵌套安装: workspace/skills/rocky-know-how/skills/rocky-know-how/scripts
    join(workspace, 'skills', 'rocky-know-how', 'skills', 'rocky-know-how', 'scripts'),
    // 顶层安装: workspace/scripts
    join(workspace, 'scripts'),
  ];

  // 跨 workspace：检查 shared 目录
  const home = process.env.HOME || '~';
  candidates.push(
    // shared workspace
    join(home, '.openclaw', 'workspace', 'skills', 'rocky-know-how', 'scripts'),
    // 全局安装
    join(home, '.openclaw', 'skills', 'rocky-know-how', 'scripts'),
  );

  for (const dir of candidates) {
    if (existsSync(join(dir, 'search.sh'))) {
      return dir;
    }
  }
  // 回退
  return join(workspace, 'skills', 'rocky-know-how', 'scripts');
}

/**
 * 检测经验诀窍数据是否存在
 */
function hasExperienceData(home) {
  return existsSync(join(home, '.openclaw', '.learnings', 'experiences.md'));
}

const handler = async (event) => {
  if (!event || typeof event !== 'object') return;
  if (event.type !== 'agent' || event.action !== 'bootstrap') return;
  if (!event.context || typeof event.context !== 'object') return;

  // 跳过子 agent 避免重复注入
  const sessionKey = event.sessionKey || '';
  if (sessionKey.includes(':subagent:')) return;

  // 动态获取路径
  const workspace = getWorkspace(sessionKey, process.env);
  const scriptsDir = findScriptsDir(workspace);
  const home = process.env.HOME || '~';
  const hasData = hasExperienceData(home);

  const dataStatus = hasData ? '有数据' : '暂无数据（首次使用 record.sh 创建）';

  const REMINDER = `
## 📚 经验诀窍提醒 (rocky-know-how) v1.3.0

你有一个经验诀窍技能。当前状态：${dataStatus}

**失败≥2次时** → 执行搜经验诀窍：
\`\`\`bash
bash ${scriptsDir}/search.sh "关键词1" "关键词2"
\`\`\`
命中 → 读"正确方案"和"预防"，按答案执行。
没命中 → 继续自己排查。

**失败≥2次后成功** → 执行写入经验诀窍：
\`\`\`bash
bash ${scriptsDir}/record.sh "问题一句话" "踩坑过程" "正确方案" "预防措施" "tag1,tag2" "area"
\`\`\`
area 可选: frontend|backend|infra|tests|docs|config (默认: infra)
加 --dry-run 先预览不写入。

**搜索增强**：
- \`${scriptsDir}/search.sh --tag "tag1,tag2"\` — 按标签搜索（AND）
- \`${scriptsDir}/search.sh --area infra\` — 按领域搜索
- \`${scriptsDir}/search.sh --preview "关键词"\` — 摘要模式
- \`${scriptsDir}/search.sh --all\` — 查看全部

**其他命令**：
- \`${scriptsDir}/stats.sh\` — 统计面板
- \`${scriptsDir}/promote.sh\` — Tag晋升检查
- \`${scriptsDir}/import.sh --dry-run\` — 从 memory 导入历史教训
- \`${scriptsDir}/archive.sh --auto\` — 自动归档旧条目

**重要**: 经验诀窍存储在 ~/.openclaw/.learnings/（全局共享），所有 agent 通用。
`.trim();

  // 注入虚拟文件
  if (Array.isArray(event.context.bootstrapFiles)) {
    event.context.bootstrapFiles.push({
      path: 'ROCKY_KNOW_HOW_REMINDER.md',
      content: REMINDER,
      virtual: true,
    });
  }
};

module.exports = handler;
module.exports.default = handler;

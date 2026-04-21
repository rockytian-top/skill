/**
 * rocky-know-how Hook for OpenClaw
 *
 * Agent 启动时注入经验诀窍技能提醒。
 * 动态获取工作区路径，适配所有用户环境。
 * 共享路径：~/.openclaw/.learnings/
 *
 * @version 1.2.0
 */

const { existsSync } = require('fs');
const { join } = require('path');

/**
 * 从 sessionKey 提取 agent ID 并构造工作区路径
 * sessionKey 格式: agent:my-agent:main 或 agent:my-agent:subagent:xxx
 */
function getWorkspace(sessionKey, env) {
  // 1. 优先使用环境变量
  if (env.OPENCLAW_WORKSPACE) {
    return env.OPENCLAW_WORKSPACE;
  }
  // 2. 从 sessionKey 推导 (格式: agent:{agentId}:main)
  if (sessionKey && typeof sessionKey === 'string') {
    const parts = sessionKey.split(':');
    if (parts.length >= 2 && parts[0] === 'agent') {
      const home = env.HOME || process.env.HOME || '~';
      return `${home}/.openclaw/workspace-${parts[1]}`;
    }
  }
  // 3. 回退到默认工作区
  const home = env.HOME || process.env.HOME || '~';
  return `${home}/.openclaw/workspace`;
}

/**
 * 动态定位 scripts 目录
 * 支持多种安装方式：skills/ 子目录、直接克隆、symbolic link
 */
function findScriptsDir(sessionKey, env) {
  const home = env.HOME || process.env.HOME || '~';
  const workspace = getWorkspace(sessionKey, env);
  const candidates = [
    // 标准安装: workspace/skills/rocky-know-how/skills/rocky-know-how/scripts
    join(workspace, 'skills', 'rocky-know-how', 'skills', 'rocky-know-how', 'scripts'),
    // 直接克隆: workspace/skills/rocky-know-how/scripts
    join(workspace, 'skills', 'rocky-know-how', 'scripts'),
    // 顶层安装: workspace/scripts
    join(workspace, 'scripts'),
    // ClawHub 安装: ~/.openclaw/workspace-{agentId}/skills/rocky-know-how/scripts
    sessionKey ? join(home, '.openclaw', 'workspace-' + sessionKey.split(':')[1], 'skills', 'rocky-know-how', 'scripts') : null,
    // shared-skills 安装: ~/.openclaw/shared-skills/rocky-know-how/scripts
    join(home, '.openclaw', 'shared-skills', 'rocky-know-how', 'scripts'),
  ];

  for (const dir of candidates) {
    if (dir && existsSync(join(dir, 'search.sh'))) {
      return dir;
    }
  }
  // 回退：假设在 skills/rocky-know-how 标准路径下
  return join(workspace, 'skills', 'rocky-know-how', 'skills', 'rocky-know-how', 'scripts');
}

const handler = async (event) => {
  if (!event || typeof event !== 'object') return;
  if (event.type !== 'agent' || event.action !== 'bootstrap') return;
  if (!event.context || typeof event.context !== 'object') return;

  // 跳过子 agent 避免重复注入
  const sessionKey = event.sessionKey || '';
  if (sessionKey.includes(':subagent:')) return;

  // 动态获取工作区路径
  const workspace = getWorkspace(sessionKey, process.env);
  const scriptsDir = findScriptsDir(sessionKey, process.env);

  const REMINDER = `
## 📚 经验诀窍提醒 (rocky-know-how) v1.2.0

你有一个经验诀窍技能。使用规则：

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

**其他命令**：
- \`${scriptsDir}/search.sh --all\` — 查看全部
- \`${scriptsDir}/search.sh --preview "关键词"\` — 摘要模式
- \`${scriptsDir}/stats.sh\` — 统计面板
- \`${scriptsDir}/promote.sh\` — Tag晋升检查

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

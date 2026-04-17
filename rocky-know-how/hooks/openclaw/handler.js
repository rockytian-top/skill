/**
 * rocky-know-how Hook for OpenClaw v1.3.6
 *
 * Agent 启动时注入经验诀窍技能提醒。
 * 动态获取工作区路径，适配所有用户环境。
 * 支持多网关实例（通过 OPENCLAW_STATE_DIR 区分）。
 */

const { existsSync } = require('fs');
const { join } = require('path');

/**
 * 获取状态目录（适配多网关实例）
 */
function getStateDir(env) {
  if (env.OPENCLAW_STATE_DIR) {
    return env.OPENCLAW_STATE_DIR;
  }
  const home = env.HOME || process.env.HOME || '~';
  return `${home}/.openclaw`;
}

/**
 * 从 sessionKey 提取 agent ID 并构造工作区路径
 */
function getWorkspace(sessionKey, env) {
  if (env.OPENCLAW_WORKSPACE) {
    return env.OPENCLAW_WORKSPACE;
  }
  const stateDir = getStateDir(env);
  if (sessionKey && typeof sessionKey === 'string') {
    const parts = sessionKey.split(':');
    if (parts.length >= 2 && parts[0] === 'agent') {
      return `${stateDir}/workspace-${parts[1]}`;
    }
  }
  return `${stateDir}/workspace`;
}

/**
 * 动态定位 scripts 目录
 */
function findScriptsDir(workspace, stateDir) {
  const candidates = [
    join(workspace, 'skills', 'rocky-know-how', 'scripts'),
    join(workspace, 'skills', 'rocky-know-how', 'skills', 'rocky-know-how', 'scripts'),
    join(workspace, 'scripts'),
    join(stateDir, 'workspace', 'skills', 'rocky-know-how', 'scripts'),
    join(stateDir, 'skills', 'rocky-know-how', 'scripts'),
  ];

  for (const dir of candidates) {
    if (existsSync(join(dir, 'search.sh'))) {
      return dir;
    }
  }
  return join(workspace, 'skills', 'rocky-know-how', 'scripts');
}

/**
 * 检测经验诀窍数据是否存在
 */
function hasExperienceData(stateDir) {
  return existsSync(join(stateDir, '.learnings', 'experiences.md'));
}

const handler = async (event) => {
  if (!event || typeof event !== 'object') return;
  if (event.type !== 'agent' || event.action !== 'bootstrap') return;
  if (!event.context || typeof event.context !== 'object') return;

  const sessionKey = event.sessionKey || '';
  if (sessionKey.includes(':subagent:')) return;

  const env = process.env;
  const stateDir = getStateDir(env);
  const workspace = getWorkspace(sessionKey, env);
  const scriptsDir = findScriptsDir(workspace, stateDir);
  const hasData = hasExperienceData(stateDir);
  const dataStatus = hasData ? '有数据' : '暂无数据（首次使用 record.sh 创建）';

  const REMINDER = `
## 📚 经验诀窍提醒 (rocky-know-how) v1.3.6

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

**重要**: 经验诀窍存储在 ${stateDir}/.learnings/（全局共享），所有 agent 通用。
`.trim();

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

/**
 * rocky-know-how Hook for OpenClaw
 *
 * v2.7.1 - 支持 OpenClaw 2026.4.21 新 Hook
 * - agent/bootstrap: 启动时注入经验诀窍提醒
 * - before_compaction: 压缩前保存任务状态
 * - after_compaction: 压缩后记录会话总结
 * - before_reset: 重置前保存重要信息
 *
 * @version 2.7.1
 */

const { existsSync, readFileSync, writeFileSync, appendFileSync } = require('fs');
const { join } = require('path');

/**
 * 从 sessionKey 提取 agent ID 并构造工作区路径
 */
function getWorkspace(sessionKey, env) {
  const home = env.HOME || process.env.HOME || '~';
  if (env.OPENCLAW_WORKSPACE) return env.OPENCLAW_WORKSPACE;
  if (sessionKey && typeof sessionKey === 'string') {
    const parts = sessionKey.split(':');
    if (parts.length >= 2 && parts[0] === 'agent') {
      return `${home}/.openclaw/workspace-${parts[1]}`;
    }
  }
  return `${home}/.openclaw/workspace`;
}

/**
 * 动态定位 scripts 目录
 */
function findScriptsDir(sessionKey, env) {
  const home = env.HOME || process.env.HOME || '~';
  const workspace = getWorkspace(sessionKey, env);
  const candidates = [
    join(workspace, 'skills', 'rocky-know-how', 'scripts'),
    join(workspace, 'scripts'),
    sessionKey ? join(home, '.openclaw', 'workspace-' + sessionKey.split(':')[1], 'skills', 'rocky-know-how', 'scripts') : null,
    join(home, '.openclaw', 'skills', 'rocky-know-how', 'scripts'),
    join(home, '.openclaw', 'shared-skills', 'rocky-know-how', 'scripts'),
  ];
  for (const dir of candidates) {
    if (dir && existsSync(join(dir, 'search.sh'))) return dir;
  }
  // P7 fix: 删除错误的嵌套 fallback，使用合理的 home 路径兜底
  return join(home, '.openclaw', 'skills', 'rocky-know-how', 'scripts');
}

/**
 * 获取共享学习数据目录
 */
function getLearningsDir(env) {
  const home = env.HOME || process.env.HOME || '~';
  return `${home}/.openclaw/.learnings`;
}

/**
 * 生成提醒文本（用于注入 systemPrompt）
 */
function generateReminder(scriptsDir) {
  return `
## 📚 经验诀窍提醒 (rocky-know-how) v2.7.1

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
`;
}

/**
 * 提取 messages 中的关键信息用于总结
 */
function extractContextFromMessages(messages) {
  if (!Array.isArray(messages)) return { task: '', tools: [], errors: [] };
  
  const taskParts = [];
  const errors = [];
  const tools = new Set();
  
  for (const msg of messages) {
    if (!msg || typeof msg !== 'object') continue;
    
    // 提取 user message 作为任务线索
    if (msg.role === 'user' && msg.content) {
      const content = typeof msg.content === 'string' ? msg.content : 
        (Array.isArray(msg.content) ? msg.content.map(c => c.text || c.content || '').join(' ') : '');
      if (content && content.length < 200) {
        taskParts.push(content.slice(0, 100));
      }
    }
    
    // 提取 tool_use 中的工具名称
    if (msg.role === 'assistant' && Array.isArray(msg.content)) {
      for (const block of msg.content) {
        if (block.type === 'tool_use' && block.name) {
          tools.add(block.name);
        }
      }
    }
    
    // 提取 tool result 中的错误
    if (msg.role === 'tool' && msg.content) {
      const content = typeof msg.content === 'string' ? msg.content : 
        (Array.isArray(msg.content) ? msg.content.map(c => c.text || '').join(' ') : '');
      if (content && (content.includes('error') || content.includes('Error') || content.includes('failed'))) {
        errors.push(content.slice(0, 150));
      }
    }
  }
  
  return {
    task: taskParts.slice(-3).join(' | '),
    tools: Array.from(tools),
    errors: errors.slice(-5)
  };
}

/**
 * 保存 compaction 前状态到临时文件
 */
function saveCompactionState(sessionKey, env, messages) {
  const learningsDir = getLearningsDir(env);
  const stateFile = join(learningsDir, '.compaction-state.tmp');
  
  const { task, tools, errors } = extractContextFromMessages(messages);
  
  const state = {
    sessionKey,
    savedAt: new Date().toISOString(),
    task,
    tools,
    errors,
    messageCount: Array.isArray(messages) ? messages.length : 0
  };
  
  try {
    writeFileSync(stateFile, JSON.stringify(state, null, 2), 'utf8');
  } catch (e) {
    // 静默失败，不影响主流程
  }
}

/**
 * 记录会话总结到经验库
 */
function recordSessionSummary(sessionKey, env, summary) {
  const scriptsDir = findScriptsDir(sessionKey, env);
  const learningsDir = getLearningsDir(env);
  const summaryFile = join(learningsDir, 'session-summaries.md');
  
  const timestamp = new Date().toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai' });
  const agentId = sessionKey ? sessionKey.split(':')[1] || 'unknown' : 'unknown';
  
  // 生成总结内容
  const content = `## ${timestamp} | ${agentId} | 会话总结

**任务**: ${summary.task || '未知'}
**工具**: ${summary.tools?.length ? summary.tools.join(', ') : '无'}
**消息数**: ${summary.messageCount || 0}
**压缩原因**: ${summary.reason || '未知'}

${summary.errors?.length ? `**遇到的问题**: ${summary.errors.join('; ')}` : ''}

---
`;
  
  try {
    appendFileSync(summaryFile, content, 'utf8');
  } catch (e) {
    // 静默失败
  }
}

// ============================================================
// 主 Handler - 统一处理所有 Hook 事件
// ============================================================
const handler = async (event) => {
  if (!event || typeof event !== 'object') return;
  
  const sessionKey = event.sessionKey || '';
  const env = process.env;
  
  // 跳过子 agent
  if (sessionKey.includes(':subagent:')) return;
  
  const eventType = event.type;
  const eventAction = event.action;
  
  // ============================================================
  // 1. agent/bootstrap - 启动时注入经验提醒
  // ============================================================
  if (eventType === 'agent' && eventAction === 'bootstrap') {
    if (!event.context || typeof event.context !== 'object') return;
    
    const scriptsDir = findScriptsDir(sessionKey, env);
    const reminder = generateReminder(scriptsDir);
    
    if (event.context.systemPrompt !== undefined) {
      event.context.systemPrompt += reminder;
    } else if (Array.isArray(event.context.messages)) {
      event.context.messages.push({ role: 'system', content: reminder });
    }
    return;
  }
  
  // ============================================================
  // 2. before_compaction - 压缩前保存任务状态
  // ============================================================
  if (event.type === 'before_compaction') {
    const messages = event.messages || event.context?.messages || [];
    saveCompactionState(sessionKey, env, messages);
    return;
  }
  
  // ============================================================
  // 3. after_compaction - 压缩后记录会话总结
  // ============================================================
  if (event.type === 'after_compaction') {
    const learningsDir = getLearningsDir(env);
    const stateFile = join(learningsDir, '.compaction-state.tmp');
    
    // 读取保存的状态
    let savedState = null;
    try {
      if (existsSync(stateFile)) {
        savedState = JSON.parse(readFileSync(stateFile, 'utf8'));
      }
    } catch (e) {
      // 忽略
    }
    
    const summary = {
      task: savedState?.task || event.task || '会话压缩',
      tools: savedState?.tools || [],
      errors: savedState?.errors || [],
      messageCount: savedState?.messageCount || 0,
      reason: event.reason || 'context_overflow',
      sessionKey
    };
    
    recordSessionSummary(sessionKey, env, summary);
    
    // 清理临时文件
    try {
      if (existsSync(stateFile)) {
        require('fs').unlinkSync(stateFile);
      }
    } catch (e) {
      // 忽略
    }
    return;
  }
  
  // ============================================================
  // 4. before_reset - 重置前保存重要信息
  // ============================================================
  if (event.type === 'before_reset') {
    const messages = event.messages || event.context?.messages || [];
    saveCompactionState(sessionKey, env, messages);
    return;
  }
};

module.exports = { handler };

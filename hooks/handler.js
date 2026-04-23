/**
 * rocky-know-how Hook for OpenClaw
 *
 * v2.8.14 - before_reset 全自动草稿审核集成
 * - agent/bootstrap: 启动时注入经验诀窍提醒
 * - before_compaction: 压缩前保存任务状态
 * - after_compaction: 压缩后记录会话总结
 * - before_reset: 生成草稿 → 自动审核 → 写入经验
 *
 * @version 2.8.14
 */

const { existsSync, readFileSync, writeFileSync, appendFileSync, unlinkSync, mkdirSync } = require('fs');
const { join } = require('path');
const { execSync } = require('child_process');

/**
 * 从 sessionKey 提取 agent ID 并构造工作区路径
 */
function getWorkspace(sessionKey, env) {
  const openclawDir = env.OPENCLAW_STATE_DIR || `${env.HOME || '~'}/.openclaw`;
  if (env.OPENCLAW_WORKSPACE) return env.OPENCLAW_WORKSPACE;
  if (sessionKey && typeof sessionKey === 'string') {
    const parts = sessionKey.split(':');
    if (parts.length >= 2 && parts[0] === 'agent') {
      return `${openclawDir}/workspace-${parts[1]}`;
    }
  }
  return `${openclawDir}/workspace`;
}

/**
 * 动态定位 scripts 目录
 */
function findScriptsDir(sessionKey, env) {
  const openclawDir = env.OPENCLAW_STATE_DIR || `${env.HOME || '~'}/.openclaw`;
  const workspace = getWorkspace(sessionKey, env);
  // 安全: 验证 sessionKey 提取的 agentId 不含路径穿越字符
  const agentId = sessionKey && sessionKey.includes(':')
    ? sessionKey.split(':')[1].replace(/[^a-zA-Z0-9_-]/g, '')
    : '';
  const candidates = [
    join(workspace, 'skills', 'rocky-know-how', 'scripts'),
    join(workspace, 'scripts'),
    agentId ? join(openclawDir, 'workspace-' + agentId, 'skills', 'rocky-know-how', 'scripts') : null,
    join(openclawDir, 'skills', 'rocky-know-how', 'scripts'),
    join(openclawDir, 'shared-skills', 'rocky-know-how', 'scripts'),
  ];
  for (const dir of candidates) {
    if (dir && existsSync(join(dir, 'search.sh'))) return dir;
  }
  // fallback: 使用 openclawDir 而非硬编码 home
  return join(openclawDir, 'skills', 'rocky-know-how', 'scripts');
}

/**
 * 获取共享学习数据目录
 */
function getLearningsDir(env) {
  const openclawDir = env.OPENCLAW_STATE_DIR || `${env.HOME || '~'}/.openclaw`;
  return `${openclawDir}/.learnings`;
}

/**
 * 执行 auto-review.sh 全自动审核
 */
function runAutoReview(scriptsDir, learningsDir) {
  try {
    const autoReviewScript = join(scriptsDir, 'auto-review.sh');
    if (!existsSync(autoReviewScript)) {
      console.log('[rocky-know-how] auto-review.sh not found, skipping');
      return;
    }
    
    // 执行 auto-review.sh
    execSync(`bash "${autoReviewScript}"`, {
      cwd: learningsDir,
      stdio: 'pipe',
      timeout: 30000
    });
    console.log('[rocky-know-how] auto-review.sh completed');
  } catch (e) {
    console.log('[rocky-know-how] auto-review.sh failed:', e.message);
  }
}

/**
 * 生成草稿文件
 */
function generateDraft(sessionKey, env, messages) {
  const learningsDir = getLearningsDir(env);
  const draftsDir = join(learningsDir, 'drafts');
  
  // 确保 drafts 目录存在
  if (!existsSync(draftsDir)) {
    mkdirSync(draftsDir, { recursive: true });
  }
  
  const { task, tools, errors } = extractContextFromMessages(messages);
  
  // 只有"有任务 + 有错误"才生成草稿
  if (!task || errors.length === 0) {
    console.log('[rocky-know-how] No task or errors, skipping draft generation');
    return null;
  }
  
  const timestamp = Date.now();
  const draftId = `draft-${timestamp}-${sessionKey.replace(/[^a-zA-Z0-9]/g, '')}`;
  const draftFile = join(draftsDir, `${draftId}.json`);
  
  const draft = {
    id: draftId,
    createdAt: new Date().toISOString(),
    sessionKey,
    shouldCreate: true,
    problem: task,
    tried: errors.join('; '),
    solution: "待补充",
    tags: tools.length > 0 ? tools.slice(0, 5) : ['unknown'],
    area: inferArea(task),
    status: 'pending_review'
  };
  
  try {
    writeFileSync(draftFile, JSON.stringify(draft, null, 2), 'utf8');
    console.log(`[rocky-know-how] Draft generated: ${draftId}`);
    return draftId;
  } catch (e) {
    console.log('[rocky-know-how] Failed to generate draft:', e.message);
    return null;
  }
}

/**
 * 从任务推断领域
 */
function inferArea(task) {
  if (!task) return 'global';
  const lower = task.toLowerCase();
  if (/nginx|apache|web|server|mysql|redis|mongodb|docker|k8s|kubernetes/i.test(lower)) return 'infra';
  if (/php|java|python|code|git|merge|compile|build/i.test(lower)) return 'code';
  if (/wechat|weixin|wx|公众号|小程序/i.test(lower)) return 'wx.newstt';
  if (/test|测试|qa/i.test(lower)) return 'test';
  return 'global';
}

/**
 * 生成提醒文本（用于注入 systemPrompt）
 */
function generateReminder(scriptsDir) {
  return `
## 📚 经验诀窍提醒 (rocky-know-how) v2.8.3

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
 * 自动搜索相关经验并返回结果
 */
function autoSearch(scriptsDir, messages) {
  try {
    const searchScript = join(scriptsDir, 'search.sh');
    if (!existsSync(searchScript)) return null;
    
    // 从 messages 提取关键词
    const keywords = [];
    for (const msg of messages) {
      if (msg.role === 'user' && msg.content) {
        const content = typeof msg.content === 'string' ? msg.content : '';
        // 提取前10个词作为关键词
        const words = content.slice(0, 200).split(/\s+/).slice(0, 5);
        keywords.push(...words.filter(w => w.length > 3));
      }
    }
    
    if (keywords.length === 0) return null;
    
    // 去重，取前3个关键词
    const unique = [...new Set(keywords)].slice(0, 3);
    const query = unique.join(' ');
    
    // 执行搜索
    const result = execSync(`bash "${searchScript}" ${query} 2>/dev/null | head -50`, {
      encoding: 'utf8',
      timeout: 10000
    });
    
    if (result && result.trim()) {
      return `\n\n## 🔍 自动搜索相关经验\n${result}\n`;
    }
  } catch (e) {
    // 忽略搜索错误
  }
  return null;
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
  // 2. before_compaction - 压缩前保存任务状态 + 自动搜索
  // ============================================================
  if (event.type === 'before_compaction') {
    const messages = event.messages || event.context?.messages || [];
    
    // 保存状态
    saveCompactionState(sessionKey, env, messages);
    
    // 自动搜索相关经验并注入上下文
    const scriptsDir = findScriptsDir(sessionKey, env);
    const searchResult = autoSearch(scriptsDir, messages);
    if (searchResult && event.context) {
      // 注入到 systemPrompt 或 messages
      if (event.context.systemPrompt !== undefined) {
        event.context.systemPrompt += searchResult;
      } else if (Array.isArray(event.context.messages)) {
        event.context.messages.push({ role: 'system', content: searchResult });
      }
    }
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
  // 4. before_reset - 重置前生成草稿 + 自动审核
  // ============================================================
  if (event.type === 'before_reset') {
    const messages = event.messages || event.context?.messages || [];
    
    // 生成草稿
    const draftId = generateDraft(sessionKey, env, messages);
    
    // 保存状态
    saveCompactionState(sessionKey, env, messages);
    
    // 如果生成了草稿，自动调用 auto-review.sh
    if (draftId) {
      const scriptsDir = findScriptsDir(sessionKey, env);
      const learningsDir = getLearningsDir(env);
      runAutoReview(scriptsDir, learningsDir);
    }
    
    return;
  }
};

module.exports = { handler };

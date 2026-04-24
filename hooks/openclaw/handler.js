/**
 * rocky-know-how Hook for OpenClaw
 *
 * v2.9.1 - 直接处理模式
 * - before_compaction: 保存内容到 pending/ 待处理队列
 * - after_compaction: 直接调用 LLM 判断 + 处理
 * - 不触发新 agent,避免队列等待
 *
 * @version 2.9.2
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
function findScriptsDir(sessionKey, env, requiredFile = 'search.sh') {
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
    if (dir && existsSync(join(dir, requiredFile))) return dir;
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
 * 从 LLM API 响应中提取 assistant 消息
 * 支持 OpenAI completions 格式和 Anthropic messages 格式
 * @param {object} parsed - JSON.parse 后的响应
 * @returns {string} assistant 消息内容
 */
function extractAssistantMessage(parsed) {
  // OpenAI format: choices[0].message.content
  if (parsed.choices?.[0]?.message?.content) {
    return parsed.choices[0].message.content;
  }
  // Anthropic messages format: content[].text
  if (parsed.content && Array.isArray(parsed.content)) {
    const textBlock = parsed.content.find(block => block.type === 'text');
    if (textBlock?.text) {
      return textBlock.text;
    }
  }
  return '';
}

/**
 * 从 event context 或 agent 配置解析 provider 信息
 * @param {object} event - hook event 对象
 * @param {object} ctx - hook ctx 对象（包含 agentId/sessionKey）
 * @returns {object|null} provider 信息
 */
function resolveProviderInfo(event, ctx) {
  const context = event?.context || {};
  let providerId = context.modelProviderId;
  let modelId = context.modelId;

  // 尝试从 agent 配置反查 provider（hook context 不传递 modelProviderId 时）
  if (!providerId && ctx?.agentId) {
    try {
      const openclawConfig = JSON.parse(readFileSync(join(process.env.HOME || '~', '.openclaw', 'openclaw.json'), 'utf8'));
      const agents = openclawConfig?.agents?.list || [];
      const agent = agents.find(a => a.id === ctx.agentId);
      if (agent?.model) {
        const [pId, mId] = agent.model.split('/');
        providerId = providerId || pId;
        modelId = modelId || mId;
      }
    } catch (e) {
      // 忽略，继续尝试其他方式
    }
  }

  if (!providerId) {
    console.log('[rocky-know-how] resolveProviderInfo: no providerId found, skipping');
    return null;
  }

  try {
    const openclawConfig = JSON.parse(readFileSync(join(process.env.HOME || '~', '.openclaw', 'openclaw.json'), 'utf8'));
    const providers = openclawConfig?.models?.providers || {};
    const provider = providers[providerId];

    if (!provider) {
      console.log(`[rocky-know-how] resolveProviderInfo: provider ${providerId} not found in config`);
      return null;
    }

    if (!provider.baseUrl) {
      console.log(`[rocky-know-how] resolveProviderInfo: provider ${providerId} has no baseUrl`);
      return null;
    }

    // 根据 api 类型确定路径
    let apiPath = '/chat/completions';
    if (provider.api === 'anthropic-messages') {
      apiPath = '/v1/messages';
    }

    const apiKey = provider.apiKey || '';

    // OAuth provider (无 apiKey): 尝试从 auth-profiles.json 读取 token
    if (provider.authHeader && !apiKey) {
      try {
        const authProfilesPath = join(process.env.HOME || '~', '.openclaw', 'agents', 'main', 'agent', 'auth-profiles.json');
        if (existsSync(authProfilesPath)) {
          const authStore = JSON.parse(readFileSync(authProfilesPath, 'utf8'));
          const profileId = `${providerId}:default`;
          const profile = authStore?.profiles?.[profileId];
          if (profile?.access) {
            const token = profile.access;
            console.log(`[rocky-know-how] resolveProviderInfo: ${providerId} using OAuth token from auth-profiles.json`);
            const apiUrl = `${provider.baseUrl}${apiPath}`;
            const model = modelId || provider.model || '';
            return { provider, providerId, apiUrl, apiKey: token, model };
          }
        }
      } catch (e) {
        console.log(`[rocky-know-how] resolveProviderInfo: failed to read OAuth token: ${e.message}`);
      }
      console.log(`[rocky-know-how] resolveProviderInfo: ${providerId} is OAuth (no apiKey), skipping LLM`);
      return null;
    }

    const apiUrl = `${provider.baseUrl}${apiPath}`;
    const model = modelId || provider.model || '';

    return { provider, providerId, apiUrl, apiKey, model };
  } catch (e) {
    console.log(`[rocky-know-how] resolveProviderInfo failed: ${e.message}`);
    return null;
  }
}

/**
 * 执行 auto-review.sh 全自动审核
 */
function runAutoReview(scriptsDir, learningsDir) {
  try {
    // 优先使用全局目录的 auto-review.sh
    const globalScriptsDir = '/Users/rocky/.openclaw/skills/rocky-know-how/scripts';
    const autoReviewScript = existsSync(join(globalScriptsDir, 'auto-review.sh'))
      ? join(globalScriptsDir, 'auto-review.sh')
      : join(scriptsDir, 'auto-review.sh');

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
 * 调用模型判断内容是否值得写入
 * @param {string} content - 对话内容或草稿内容
 * @param {string} type - "draft" 或 "formal"
 * @param {object} providerInfo - resolveProviderInfo() 返回的 provider 信息
 * @returns {object} { worth: boolean, reason: string, summary?: string, tags?: string[] }
 */
function callLLMJudge(content, type, providerInfo) {
  if (!providerInfo?.apiUrl) {
    console.log('[rocky-know-how] callLLMJudge: no provider configured, skipping');
    return { worth: false, reason: '无模型配置' };
  }

  const { apiUrl, apiKey, model } = providerInfo;

  let systemPrompt, userPrompt;

  if (type === 'draft') {
    systemPrompt = `你是一个经验诀窍判断助手。判断以下对话内容是否值得写入草稿经验。

判断标准:
- 有实际操作(工具调用) + 有问题或解决方案 → worth
- 只有闲聊、无关内容 → not worth

回复格式(仅输出JSON,不要其他内容):
{
  "worth": true或false,
  "reason": "判断理由(20字内)",
  "summary": "提取的问题/解决方案摘要(50字内)",
  "tags": ["tag1", "tag2"]
}`;
    userPrompt = `对话内容:
${content}`;
  } else {
    systemPrompt = `你是一个经验诀窍判断助手。判断并优化以下草稿内容。

任务:
1. 判断草稿是否值得写入正式经验
2. 如果值得,优化和增强解决方案,使其更完整、更实用

判断标准:
- 有具体问题 + 可优化 → worth
- 草稿质量低、重复、不完整 → not worth

优化要求:
- 补充遗漏的关键步骤
- 修正不准确的描述
- 增加预防措施和最佳实践
- 使解决方案可直接复用

回复格式(仅输出JSON,不要其他内容):
{
  "worth": true或false,
  "reason": "判断理由(20字内)",
  "solution": "优化后的完整解决方案(如worth=true则必填)",
  "prevention": "预防措施和最佳实践(如worth=true则必填)"
}`;
    userPrompt = `草稿内容:
${content}`;
  }

  try {
    const payload = {
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      temperature: 0.1,
      max_tokens: 800
    };
    if (model) payload.model = model;

    const result = execSync(`curl -s -X POST "${apiUrl}" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${apiKey}" \
      -d '${JSON.stringify(payload).replace(/'/g, "'\\''")}' \
      --max-time 30`, {
      encoding: 'utf8',
      timeout: 35000
    });

    const parsed = JSON.parse(result);
    const assistantMsg = extractAssistantMessage(parsed);

    // 解析 JSON 响应
    const jsonMatch = assistantMsg.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
  } catch (e) {
    console.log(`[rocky-know-how] LLM judge failed: ${e.message}`);
  }

  // 默认返回不worth,避免误写
  return { worth: false, reason: 'LLM调用失败', llmFailed: true };
}

/**
 * 用 LLM 判断草稿应该新增还是追加到已有经验
 * @param {object} draft - 草稿对象
 * @param {object[]} similarExperiences - 相似经验列表
 * @param {object} providerInfo - resolveProviderInfo() 返回的 provider 信息
 * @returns {object} { action: "create" | "append", targetId?: string, reason: string, optimizedSolution?: string, optimizedPrevention?: string }
 */
function decideCreateOrAppend(draft, similarExperiences, providerInfo) {
  if (!providerInfo?.apiUrl) {
    // 无配置，降级到关键词判断
    if (similarExperiences && similarExperiences.length > 0) {
      return { action: 'append', targetId: similarExperiences[0].id, reason: '无LLM配置，降级到关键词判断' };
    }
    return { action: 'create', reason: '无LLM配置且无相似经验' };
  }

  const { apiUrl, apiKey, model } = providerInfo;

  // 构造相似经验上下文
  let similarCtx = '无相似经验';
  if (similarExperiences && similarExperiences.length > 0) {
    similarCtx = similarExperiences.slice(0, 3).map(exp =>
      `【经验 ${exp.id}】\n问题: ${exp.problem}\n方案: ${exp.solution}\n标签: ${(exp.tags || []).join(', ')}`
    ).join('\n\n');
  }

  const systemPrompt = `你是一个经验诀窍审核助手。判断草稿应该"新增经验"还是"追加到已有经验"。

判断标准:
- 草稿与已有经验问题本质相同/高度相似 → 追加到已有（补充新解决方案）
- 草稿问题独特，无类似经验 → 新增经验
- 已有经验解决方案已包含草稿方案 → 追加（补充另一种方式）
- 已有经验标签/领域相同但问题不同 → 新增经验

优化要求（追加时）:
- 补充遗漏的关键步骤
- 修正不准确的描述
- 给出更完整的预防措施

回复格式（仅输出JSON）:
{
  "action": "create"或"append",
  "targetId": "EXP-XXX（append时必填）",
  "reason": "判断理由（30字内）",
  "optimizedSolution": "优化后的完整解决方案（append时必填）",
  "optimizedPrevention": "优化后的预防措施（append时必填）"
}`;

  const userPrompt = `草稿内容:
问题: ${draft.problem || '无'}
踩坑过程: ${draft.tried || '无'}
解决方案: ${draft.solution || '待补充'}
标签: ${(draft.tags || []).join(', ')}

相似经验:
${similarCtx}`;

  try {
    const payload = {
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      temperature: 0.1,
      max_tokens: 600
    };
    if (model) payload.model = model;

    const result = execSync(`curl -s -X POST "${apiUrl}" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${apiKey}" \
      -d '${JSON.stringify(payload).replace(/'/g, "'\\''")}' \
      --max-time 30`, {
      encoding: 'utf8',
      timeout: 35000
    });

    const parsed = JSON.parse(result);
    const assistantMsg = extractAssistantMessage(parsed);
    const jsonMatch = assistantMsg.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
  } catch (e) {
    console.log(`[rocky-know-how] decideCreateOrAppend LLM failed: ${e.message}`);
  }

  // LLM 失败，降级到关键词
  if (similarExperiences && similarExperiences.length > 0) {
    return { action: 'append', targetId: similarExperiences[0].id, reason: 'LLM失败，降级关键词', llmFailed: true };
  }
  return { action: 'create', reason: 'LLM失败且无相似经验', llmFailed: true };
}

/**
 * 写入草稿文件的通用函数(用于 before_compaction 模型判断后)
 */
function writeDraftWithJudge(learningsDir, sessionKey, problem, tried, tags) {
  const draftsDir = join(learningsDir, 'drafts');

  if (!existsSync(draftsDir)) {
    mkdirSync(draftsDir, { recursive: true });
  }

  const timestamp = Date.now();
  const draftId = `draft-${timestamp}-${sessionKey.replace(/[^a-zA-Z0-9]/g, '')}`;
  const draftFile = join(draftsDir, `${draftId}.json`);

  const draft = {
    id: draftId,
    createdAt: new Date().toISOString(),
    sessionKey,
    problem,
    tried,
    solution: "待补充",
    tags: tags && tags.length > 0 ? tags : ['unknown'],
    area: inferArea(problem),
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
 * 搜索相似经验并读取完整内容
 * @param {string} scriptsDir - scripts 目录
 * @param {string} keywords - 搜索关键词
 * @returns {object[]} 相似经验列表 [{id, problem, solution, tags, area}, ...]
 */
function searchSimilarExperiences(scriptsDir, keywords) {
  try {
    const searchScript = join(scriptsDir, 'search.sh');
    if (!existsSync(searchScript)) return [];

    const result = execSync(`bash "${searchScript}" ${keywords} 2>/dev/null | grep -oE 'EXP-[0-9]{8}-[0-9]{3}' | head -5`, {
      encoding: 'utf8',
      timeout: 10000
    });

    const ids = (result || '').trim().split('\n').filter(id => id.startsWith('EXP-'));
    if (ids.length === 0) return [];

    // 读取 experiences.md 提取相似经验内容
    const experiencesFile = join(getLearningsDir(process.env), 'experiences.md');
    if (!existsSync(experiencesFile)) return [];

    const content = readFileSync(experiencesFile, 'utf8');
    const experiences = [];

    for (const id of ids) {
      // 匹配经验条目: ## [EXP-YYYYMMDD-NNN] 标题\n\n内容
      const regex = new RegExp(`## \\\\[${id}\\\\] [^\\\\n]*\\\\n\\\\n([\\\\s\\\\S]*?)(?=\\\\n## \\\\[EXP-|\\\\z)`, 'i');
      const match = content.match(regex);
      if (match) {
        const block = match[1];
        const problemMatch = block.match(/\*\*问题\*\*:\s*(.+)/i) || block.match(/### 问题\s*\n(.+)/i);
        const solutionMatch = block.match(/\*\*正确方案\*\*:\s*(.+)/i) || block.match(/### 正确方案\s*\n([\s\S]+?)(?=###|$)/i);
        const tagsMatch = block.match(/\*\*Tags\*\*:\s*(.+)/i);

        experiences.push({
          id,
          problem: problemMatch ? problemMatch[1].trim() : '',
          solution: solutionMatch ? (solutionMatch[1] || solutionMatch[0]).trim() : '',
          tags: tagsMatch ? tagsMatch[1].split(',').map(t => t.trim()) : []
        });
      }
    }
    return experiences;
  } catch (e) {
    console.log(`[rocky-know-how] searchSimilarExperiences failed: ${e.message}`);
    return [];
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
 * 生成提醒文本(用于注入 systemPrompt)
 */
function generateReminder(scriptsDir) {
  return `
## 📚 经验诀窍提醒 (rocky-know-how) v2.8.3

你有一个经验诀窍技能。使用规则:

**失败≥2次时** → 执行搜经验诀窍:
\`\`\`bash
bash ${scriptsDir}/search.sh "关键词1" "关键词2"
\`\`\`
命中 → 读"正确方案"和"预防",按答案执行。
没命中 → 继续自己排查。

**失败≥2次后成功** → 执行写入经验诀窍:
\`\`\`bash
bash ${scriptsDir}/record.sh "问题一句话" "踩坑过程" "正确方案" "预防措施" "tag1,tag2" "area"
\`\`\`
area 可选: frontend|backend|infra|tests|docs|config (默认: infra)

**其他命令**:
- \`${scriptsDir}/search.sh --all\` - 查看全部
- \`${scriptsDir}/search.sh --preview "关键词"\` - 摘要模式
- \`${scriptsDir}/stats.sh\` - 统计面板
- \`${scriptsDir}/promote.sh\` - Tag晋升检查

**重要**: 经验诀窍存储在 ~/.openclaw/.learnings/(全局共享),所有 agent 通用。
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

    // 去重,取前3个关键词
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
 * 保存待处理内容到 pending/ 目录
 */
function savePendingLearnings(sessionKey, env, messages) {
  const learningsDir = getLearningsDir(env);
  const pendingDir = join(learningsDir, 'pending');

  if (!existsSync(pendingDir)) {
    mkdirSync(pendingDir, { recursive: true });
  }

  const { task, tools, errors } = extractContextFromMessages(messages);

  const pendingItem = {
    id: `pending-${Date.now()}`,
    sessionKey,
    savedAt: new Date().toISOString(),
    task,
    tools,
    errors,
    messageCount: Array.isArray(messages) ? messages.length : 0,
    status: 'pending'
  };

  const pendingFile = join(pendingDir, `${pendingItem.id}.json`);

  try {
    writeFileSync(pendingFile, JSON.stringify(pendingItem, null, 2), 'utf8');
    console.log(`[rocky-know-how] Saved pending learnings: ${pendingItem.id}`);
    return pendingItem.id;
  } catch (e) {
    console.log(`[rocky-know-how] Failed to save pending learnings: ${e.message}`);
    return null;
  }
}

/**
 * 处理单个待处理项:LLM判断 + 生成草稿/归档
 * @param {string} pendingFile
 * @param {string} scriptsDir
 * @param {string} learningsDir
 * @param {object} providerInfo - resolveProviderInfo() 返回的 provider 信息
 */
function processPendingItem(pendingFile, scriptsDir, learningsDir, providerInfo) {
  try {
    const content = readFileSync(pendingFile, 'utf8');
    const pending = JSON.parse(content);

    console.log(`[rocky-know-how] Processing pending: ${pending.id}`);

    // 无 LLM provider（OAuth 等）：降级到关键词判断
    if (!providerInfo) {
      const keywords = (pending.tools || []).slice(0, 3).join(' ');
      const similarExperiences = searchSimilarExperiences(scriptsDir, keywords);
      console.log(`[rocky-know-how] Keyword fallback: found ${similarExperiences.length} similar`);

      if (similarExperiences.length > 0) {
        // 追加到第一个相似经验
        const targetId = similarExperiences[0].id;
        const solution = (pending.errors || []).join('; ') || '待补充';
        try {
          execSync(`bash "${join(scriptsDir, 'append-record.sh')}" "${targetId}" "${solution.replace(/"/g, '\\"')}" "${(pending.tools || []).join(',')}"`, {
            cwd: learningsDir, stdio: 'pipe', timeout: 15000
          });
          console.log(`[rocky-know-how] Appended to ${targetId} (keyword)`);
        } catch (e) {
          console.log(`[rocky-know-how] append-record.sh failed: ${e.message}`);
        }
      } else {
        // 新增经验
        try {
          execSync(`bash "${join(scriptsDir, 'record.sh')}" "${(pending.task || '会话总结').replace(/"/g, '\\"')}" "${((pending.errors || []).join('; ') || '无').replace(/"/g, '\\"')}" "待补充" "No similar problems" "${(pending.tools || []).join(',')}" "global"`, {
            cwd: learningsDir, stdio: 'pipe', timeout: 15000
          });
          console.log(`[rocky-know-how] Created new experience (keyword)`);
        } catch (e) {
          console.log(`[rocky-know-how] record.sh failed: ${e.message}`);
        }
      }

      // 归档 pending
      const archiveDir = join(learningsDir, 'pending', 'archive');
      if (!existsSync(archiveDir)) mkdirSync(archiveDir, { recursive: true });
      require('fs').renameSync(pendingFile, join(archiveDir, `${pending.id}.json`));
      return;
    }

    // 构建判断内容
    const summary = `任务: ${pending.task || '无'}
工具: ${(pending.tools || []).join(', ') || '无'}
错误: ${(pending.errors || []).join('; ') || '无'}`;

    // LLM 判断是否值得写入
    const judgeResult = callLLMJudge(summary, 'draft', providerInfo);
    console.log(`[rocky-know-how] LLM judge: worth=${judgeResult.worth}, reason=${judgeResult.reason}`);

    // LLM 调用失败，降级到关键词匹配
    if (judgeResult.llmFailed) {
      console.log(`[rocky-know-how] LLM failed, falling back to keyword matching`);
      const keywords = (pending.tools || []).slice(0, 3).join(' ');
      const similarExperiences = searchSimilarExperiences(scriptsDir, keywords);
      console.log(`[rocky-know-how] Keyword fallback: found ${similarExperiences.length} similar`);

      if (similarExperiences.length > 0) {
        const targetId = similarExperiences[0].id;
        const solution = (pending.errors || []).join('; ') || '待补充';
        try {
          execSync(`bash "${join(scriptsDir, 'append-record.sh')}" "${targetId}" "${solution.replace(/"/g, '\\"')}" "${(pending.tools || []).join(',')}"`, {
            cwd: learningsDir, stdio: 'pipe', timeout: 15000
          });
          console.log(`[rocky-know-how] Appended to ${targetId} (keyword fallback)`);
        } catch (e) {
          console.log(`[rocky-know-how] append-record.sh failed: ${e.message}`);
        }
      } else {
        try {
          execSync(`bash "${join(scriptsDir, 'record.sh')}" "${(pending.task || '会话总结').replace(/"/g, '\\"')}" "${((pending.errors || []).join('; ') || '无').replace(/"/g, '\\"')}" "待补充" "No similar problems" "${(pending.tools || []).join(',')}" "global"`, {
            cwd: learningsDir, stdio: 'pipe', timeout: 15000
          });
          console.log(`[rocky-know-how] Created new experience (keyword fallback)`);
        } catch (e) {
          console.log(`[rocky-know-how] record.sh failed: ${e.message}`);
        }
      }

      // 归档 pending
      const archiveDir = join(learningsDir, 'pending', 'archive');
      if (!existsSync(archiveDir)) mkdirSync(archiveDir, { recursive: true });
      require('fs').renameSync(pendingFile, join(archiveDir, `${pending.id}.json`));
      return;
    }

    if (judgeResult.worth) {
      // 生成草稿
      const problem = judgeResult.summary || pending.task || '会话总结';
      const draftId = writeDraftWithJudge(learningsDir, `pending:${pending.id}`, problem, (pending.errors || []).join('; ') || '无', judgeResult.tags || pending.tools || []);

      if (draftId) {
        // 读取草稿内容用于 LLM 判断
        const draftFile = join(learningsDir, 'drafts', `${draftId}.json`);
        let draftContent = { problem: problem, tried: (pending.errors || []).join('; ') || '无', solution: '待补充', tags: judgeResult.tags || pending.tools || [] };
        try {
          if (existsSync(draftFile)) {
            draftContent = JSON.parse(readFileSync(draftFile, 'utf8'));
          }
        } catch (e) { /* use defaults */ }

        // 搜索相似经验
        const keywords = (judgeResult.tags || pending.tools || []).slice(0, 3).join(' ');
        const similarExperiences = searchSimilarExperiences(scriptsDir, keywords);
        console.log(`[rocky-know-how] Found ${similarExperiences.length} similar experiences`);

        // LLM 判断: 新增还是追加
        const decision = decideCreateOrAppend(draftContent, similarExperiences, providerInfo);
        console.log(`[rocky-know-how] LLM decision: ${decision.action} ${decision.targetId || ''} - ${decision.reason}`);

        // LLM 调用失败，降级到关键词
        if (decision.llmFailed) {
          console.log(`[rocky-know-how] decideCreateOrAppend LLM failed, keyword fallback`);
          if (similarExperiences.length > 0) {
            const targetId = similarExperiences[0].id;
            const solution = draftContent.solution || (pending.errors || []).join('; ') || '待补充';
            try {
              execSync(`bash "${join(scriptsDir, 'append-record.sh')}" "${targetId}" "${solution.replace(/"/g, '\\"')}" "${(draftContent.tags || []).join(',')}"`, {
                cwd: learningsDir, stdio: 'pipe', timeout: 15000
              });
              console.log(`[rocky-know-how] Appended to ${targetId} (keyword fallback)`);
            } catch (e) {
              console.log(`[rocky-know-how] append-record.sh failed: ${e.message}`);
            }
          } else {
            try {
              execSync(`bash "${join(scriptsDir, 'record.sh')}" "${problem.replace(/"/g, '\\"')}" "${((pending.errors || []).join('; ') || '无').replace(/"/g, '\\"')}" "待补充" "No similar problems" "${(draftContent.tags || []).join(',')}" "global"`, {
                cwd: learningsDir, stdio: 'pipe', timeout: 15000
              });
              console.log(`[rocky-know-how] Created new experience (keyword fallback)`);
            } catch (e) {
              console.log(`[rocky-know-how] record.sh failed: ${e.message}`);
            }
          }
          // 归档 draft
          if (draftId && existsSync(draftFile)) {
            const draftArchiveDir = join(learningsDir, 'drafts', 'archive');
            if (!existsSync(draftArchiveDir)) mkdirSync(draftArchiveDir, { recursive: true });
            require('fs').renameSync(draftFile, join(draftArchiveDir, `${draftId}.json`));
          }
          return;
        }

        if (decision.action === 'append' && decision.targetId) {
          // 追加到已有经验
          const solution = decision.optimizedSolution || draftContent.solution || '待补充';
          try {
            execSync(`bash "${join(scriptsDir, 'append-record.sh')}" "${decision.targetId}" "${solution.replace(/"/g, '\\"')}" "${(draftContent.tags || []).join(',')}"`, {
              cwd: learningsDir, stdio: 'pipe', timeout: 15000
            });
            console.log(`[rocky-know-how] Appended to ${decision.targetId}`);
          } catch (e) {
            console.log(`[rocky-know-how] append-record.sh failed: ${e.message}`);
          }
        } else {
          // 新增经验
          const solution = decision.optimizedSolution || draftContent.solution || '待补充';
          const prevention = decision.optimizedPrevention || 'No similar problems';
          try {
            execSync(`bash "${join(scriptsDir, 'record.sh')}" "${problem.replace(/"/g, '\\"')}" "${((pending.errors || []).join('; ') || '无').replace(/"/g, '\\"')}" "${solution.replace(/"/g, '\\"')}" "${prevention.replace(/"/g, '\\"')}" "${(draftContent.tags || []).join(',')}" "${draftContent.area || 'global'}"`, {
              cwd: learningsDir, stdio: 'pipe', timeout: 15000
            });
            console.log(`[rocky-know-how] Created new experience`);
          } catch (e) {
            console.log(`[rocky-know-how] record.sh failed: ${e.message}`);
          }
        }
        // 归档 draft 文件
        if (draftId && existsSync(draftFile)) {
          const draftArchiveDir = join(learningsDir, 'drafts', 'archive');
          if (!existsSync(draftArchiveDir)) {
            mkdirSync(draftArchiveDir, { recursive: true });
          }
          require('fs').renameSync(draftFile, join(draftArchiveDir, `${draftId}.json`));
        }
      }
      // 归档 pending 文件（无论是否生成草稿成功）
      const archiveDir = join(learningsDir, 'pending', 'archive');
      if (!existsSync(archiveDir)) {
        mkdirSync(archiveDir, { recursive: true });
      }
      const archiveFile = join(archiveDir, `${pending.id}.json`);
      require('fs').renameSync(pendingFile, archiveFile);
    } else {
      console.log(`[rocky-know-how] Pending ${pending.id} not worth saving, archiving`);
      // 归档到 pending/archive/
      const archiveDir = join(learningsDir, 'pending', 'archive');
      if (!existsSync(archiveDir)) {
        mkdirSync(archiveDir, { recursive: true });
      }
      const archiveFile = join(archiveDir, `${pending.id}.json`);
      require('fs').renameSync(pendingFile, archiveFile);
    }

    return true;
  } catch (e) {
    console.log(`[rocky-know-how] Failed to process pending: ${e.message}`);
    return false;
  }
}

/**
 * 保存 compaction 前状态到临时文件(兼容旧逻辑)
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
    // 静默失败,不影响主流程
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
const handler = async (event, ctx) => {
  if (!event || typeof event !== 'object') return;

  const sessionKey = event.sessionKey || ctx?.sessionKey || '';
  const env = process.env;
  const agentId = ctx?.agentId || '';

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
  // 2. before_compaction - 压缩前:保存内容到待处理队列
  // ============================================================
  if (event.type === 'before_compaction') {
    const messages = event.messages || event.context?.messages || [];
    const scriptsDir = findScriptsDir(sessionKey, env);

    // 保存状态(供 after_compaction 使用)
    saveCompactionState(sessionKey, env, messages);

    // 自动搜索相关经验并注入上下文
    const searchResult = autoSearch(scriptsDir, messages);
    if (searchResult && event.context) {
      if (event.context.systemPrompt !== undefined) {
        event.context.systemPrompt += searchResult;
      } else if (Array.isArray(event.context.messages)) {
        event.context.messages.push({ role: 'system', content: searchResult });
      }
    }

    // 【核心】保存到待处理队列(不做判断,让 Agent 后续处理)
    const pendingId = savePendingLearnings(sessionKey, env, messages);
    if (pendingId) {
      const learningsDir = getLearningsDir(env);
      const markerFile = join(learningsDir, '.pending-marker.tmp');
      try {
        writeFileSync(markerFile, pendingId, 'utf8');
        console.log(`[rocky-know-how] before_compaction: pending ${pendingId} saved`);
      } catch (e) {
        // 忽略
      }
    }

    return;
  }

  // ============================================================
  // 3. after_compaction - 压缩后:直接处理待处理内容
  // ============================================================
  if (event.type === 'after_compaction') {
    const learningsDir = getLearningsDir(env);
    const scriptsDir = findScriptsDir(sessionKey, env);
    const stateFile = join(learningsDir, '.compaction-state.tmp');
    const pendingMarkerFile = join(learningsDir, '.pending-marker.tmp');

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

    // 记录会话总结
    recordSessionSummary(sessionKey, env, summary);

    // 【核心】直接处理待处理内容
    try {
      // 检查 pending 目录
      const pendingDir = join(learningsDir, 'pending');
      if (!existsSync(pendingDir)) {
        console.log(`[rocky-know-how] after_compaction: no pending learnings dir`);
        return;
      }

      const files = require('fs').readdirSync(pendingDir).filter(f => f.endsWith('.json'));

      if (files.length === 0) {
        console.log(`[rocky-know-how] after_compaction: no pending learnings`);
        return;
      }

      console.log(`[rocky-know-how] after_compaction: found ${files.length} pending learnings, processing directly`);

      // 从 event context 或 agent 配置解析当前 agent 的 provider
      const providerInfo = resolveProviderInfo(event, { agentId });
      if (providerInfo) {
        console.log(`[rocky-know-how] using provider: ${providerInfo.providerId} (${providerInfo.providerId}@${providerInfo.model})`);
      } else {
        console.log('[rocky-know-how] no API-key provider, falling back to keyword matching');
      }

      // 逐个处理
      for (const file of files) {
        const pendingFile = join(pendingDir, file);
        processPendingItem(pendingFile, scriptsDir, learningsDir, providerInfo);
      }

    } catch (e) {
      console.log(`[rocky-know-how] after_compaction error: ${e.message}`);
    }

    // 清理临时文件
    try {
      if (existsSync(stateFile)) {
        require('fs').unlinkSync(stateFile);
      }
      if (existsSync(pendingMarkerFile)) {
        require('fs').unlinkSync(pendingMarkerFile);
      }
    } catch (e) {
      // 忽略
    }
    return;
  }

  // ============================================================
  // 4. before_reset - 重置前:保存内容到待处理队列
  // ============================================================
  if (event.type === 'before_reset') {
    const messages = event.messages || event.context?.messages || [];

    // 保存到待处理队列
    const pendingId = savePendingLearnings(sessionKey, env, messages);
    if (pendingId) {
      console.log(`[rocky-know-how] before_reset: pending ${pendingId} saved`);
    }

    return;
  }
};

module.exports = { handler };

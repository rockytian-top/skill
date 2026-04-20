/**
 * rocky-know-how Hook v5.0
 * 
 * 核心思路：AI驱动 + 用户引导 + 持续学习
 * 
 * 流程：
 * 1. 分析用户需求
 * 2. 加载/生成脚本
 * 3. 根据用户情况调整
 * 4. 执行并观察反馈
 * 5. 记录偏好，优化脚本
 */

const { existsSync, readFileSync, writeFileSync, appendFileSync, mkdirSync, execSync } = require('fs');
const { join } = require('path');
const { exec } = require('child_process');

// 状态目录
const getStateDir = (env) => env.OPENCLAW_STATE_DIR || `${env.HOME}/.openclaw`;
const STATE_DIR = getStateDir(process.env);

// 路径
const PROFILES_DIR = join(STATE_DIR, '.learnings', 'user-profiles');
const SCRIPTS_DIR = join(STATE_DIR, '.learnings', 'scripts');
const EXPERIENCES_FILE = join(STATE_DIR, '.learnings', 'experiences.json');
const LOG_FILE = '/tmp/rocky-know-how-hook.log';

// 确保目录存在
mkdirSync(PROFILES_DIR, { recursive: true });

/**
 * 调试日志
 */
function debugLog(msg) {
  const timestamp = new Date().toISOString();
  appendFileSync(LOG_FILE, `${timestamp} ${msg}\n`);
}

/**
 * 获取用户画像
 */
function getUserProfile(userId) {
  const profileFile = join(PROFILES_DIR, `${userId}.json`);
  if (existsSync(profileFile)) {
    try {
      return JSON.parse(readFileSync(profileFile, 'utf8'));
    } catch (e) {
      return null;
    }
  }
  return null;
}

/**
 * 保存用户画像
 */
function saveUserProfile(profile) {
  profile.updatedAt = new Date().toISOString();
  const profileFile = join(PROFILES_DIR, `${profile.userId}.json`);
  writeFileSync(profileFile, JSON.stringify(profile, null, 2));
}

/**
 * 分析用户意图和偏好
 */
function analyzeUserNeeds(message, history, profile) {
  // 构建分析prompt
  const historyText = history.map(m => `${m.role}: ${m.content}`).join('\n');
  const profileText = profile ? JSON.stringify(profile.preferences, null, 2) : '无';
  
  const prompt = `用户消息: "${message}"

对话历史:
${historyText}

用户偏好:
${profileText}

请分析：
1. 用户想要做什么？（意图）
2. 用户有什么偏好？（根据对话判断）
3. 需要什么类型的脚本？

请用JSON格式回复：
{
  "intent": "...",
  "preferences": {...},
  "scriptType": "backup|deploy|monitor|search|...",
  "confidence": 0.0-1.0
}`;

  return callLLM(prompt);
}

/**
 * 调用LLM
 */
function callLLM(prompt) {
  try {
    const payload = {
      model: "lingshu-7b",
      messages: [
        { role: "system", content: "你是一个专业的需求分析助手。根据用户消息和对话历史，分析用户意图和偏好。" },
        { role: "user", content: prompt }
      ],
      temperature: 0.3,
      max_tokens: 500
    };

    const result = execSync(
      `curl -s -X POST "http://localhost:1234/v1/chat/completions" -H "Content-Type: application/json" -d '${JSON.stringify(payload)}'`,
      { encoding: 'utf8', timeout: 30000 }
    );

    const data = JSON.parse(result);
    const content = data.choices?.[0]?.message?.content || '';
    
    // 尝试解析JSON
    try {
      return JSON.parse(content);
    } catch {
      return { intent: content.substring(0, 100), confidence: 0.5 };
    }
  } catch (e) {
    debugLog("LLM_ERROR: " + e.message.substring(0, 50));
    return null;
  }
}

/**
 * 搜索相关脚本
 */
function searchScripts(intent, scriptType) {
  try {
    // 获取所有脚本
    const scripts = execSync(
      `ls -la "${SCRIPTS_DIR}"/*.sh 2>/dev/null || echo ""`,
      { encoding: 'utf8' }
    ).trim();

    if (!scripts) return [];

    const scriptNames = scripts.split('\n')
      .filter(line => line.includes('.sh'))
      .map(line => {
        const match = line.match(/\/(.+)\.sh/);
        return match ? match[1] : null;
      })
      .filter(Boolean);

    // 简单关键词匹配
    const keywords = (intent + ' ' + scriptType).toLowerCase();
    const matched = scriptNames.filter(name => {
      const scriptPath = join(SCRIPTS_DIR, `${name}.sh`);
      const content = readFileSync(scriptPath, 'utf8').toLowerCase();
      return keywords.split(' ').some(k => k.length > 2 && content.includes(k));
    });

    return matched.map(name => ({
      name,
      path: join(SCRIPTS_DIR, `${name}.sh`)
    }));
  } catch (e) {
    return [];
  }
}

/**
 * 根据用户偏好调整脚本
 */
function adjustScript(scriptPath, profile) {
  if (!profile || !existsSync(scriptPath)) return null;

  const scriptContent = readFileSync(scriptPath, 'utf8');
  const prefs = profile.preferences || {};

  let adjusted = scriptContent;

  // 根据偏好调整
  if (prefs.fast && scriptContent.includes('tar') && scriptContent.includes('-z')) {
    // 用户喜欢快速，去掉压缩
    adjusted = adjusted.replace(/-z/g, '--skip-compress');
  }

  if (!prefs.compression && scriptContent.includes('gzip')) {
    // 用户不需要压缩
    adjusted = adjusted.replace(/-z/g, '');
  }

  return adjusted;
}

/**
 * 获取对话历史
 */
async function getHistory(sessionKey, limit = 5) {
  try {
    const result = execSync(
      `curl -s "http://localhost:18790/v1/chat/history?session=${encodeURIComponent(sessionKey)}&limit=${limit}"`,
      { encoding: 'utf8', timeout: 10000 }
    );
    return JSON.parse(result).messages || [];
  } catch (e) {
    return [];
  }
}

/**
 * 主Handler
 */
async function handler(event) {
  // 只处理消息接收事件
  if (event.type !== 'message' || event.action !== 'received') return;

  const message = event.context?.content || '';
  const sessionKey = event.sessionKey || '';
  const userId = sessionKey.split(':').pop() || '';

  debugLog("MESSAGE_RECEIVED: " + message.substring(0, 50));

  // 太短的消息跳过
  if (message.length < 5) return;

  try {
    // 1. 获取对话历史
    const history = await getHistory(sessionKey, 5);
    
    // 2. 获取用户画像
    const profile = getUserProfile(userId);
    
    // 3. 分析用户需求
    const analysis = analyzeUserNeeds(message, history, profile);
    debugLog("ANALYSIS: " + JSON.stringify(analysis || {}).substring(0, 100));
    
    if (!analysis || analysis.confidence < 0.3) {
      debugLog("LOW_CONFIDENCE: skip");
      return;
    }

    // 4. 搜索相关脚本
    const scripts = searchScripts(analysis.intent, analysis.scriptType);
    
    if (scripts.length > 0) {
      // 找到相关脚本
      const script = scripts[0];
      debugLog("SCRIPT_FOUND: " + script.name);
      
      // 5. 根据用户偏好调整脚本
      let adjustedContent = adjustScript(script.path, profile);
      
      // 6. 注入到上下文
      if (adjustedContent && Array.isArray(event.context.bootstrapFiles)) {
        const injection = `# 参考脚本 (${script.name})
\`\`\`bash
${adjustedContent}
\`\`\`

这是相关脚本，你可以根据用户需求决定是否使用或改进。`;

        event.context.bootstrapFiles.push({
          path: 'SCRIPT_REFERENCE.md',
          content: injection,
          virtual: true
        });
        
        debugLog("INJECTED: script reference");
      }
    } else {
      // 没有找到脚本，注入分析结果帮助AI
      if (Array.isArray(event.context.bootstrapFiles)) {
        const intentInjection = `用户意图分析:
- 意图: ${analysis.intent || '未知'}
- 类型: ${analysis.scriptType || '通用'}
- 置信度: ${analysis.confidence || 0}

暂无相关脚本，你可以根据用户需求决定是否创建新脚本。`;

        event.context.bootstrapFiles.push({
          path: 'INTENT_ANALYSIS.md',
          content: intentInjection,
          virtual: true
        });
      }
    }

    // 7. 更新用户画像（根据对话学习）
    if (profile && analysis.preferences) {
      const updated = { ...profile };
      updated.preferences = { ...updated.preferences, ...analysis.preferences };
      
      // 记录常见任务
      if (analysis.intent && !updated.commonTasks.includes(analysis.intent)) {
        updated.commonTasks.push(analysis.intent);
        if (updated.commonTasks.length > 20) {
          updated.commonTasks = updated.commonTasks.slice(-20);
        }
      }
      
      saveUserProfile(updated);
      debugLog("PROFILE_UPDATED");
    }

  } catch (e) {
    debugLog("HANDLER_ERROR: " + e.message.substring(0, 50));
  }
}

module.exports = handler;
module.exports.default = handler;

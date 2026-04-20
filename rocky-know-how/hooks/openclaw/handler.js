/**
 * rocky-know-how Hook v6.0
 * 
 * 完整流程：
 * 1. 识别需求 → 触发学习模式
 * 2. AI引导完善 → 了解用户需求细节
 * 3. 生成脚本 → 用户确认后保存
 * 4. 观察使用 → 记录反馈
 * 5. 主动优化 → 用户确认后改进
 * 6. 持续学习 → 更新用户画像
 */

const { existsSync, readFileSync, writeFileSync, appendFileSync, mkdirSync } = require('fs');
const { join } = require('path');
const { execSync } = require('child_process');

// 状态目录
const getStateDir = (env) => env.OPENCLAW_STATE_DIR || `${env.HOME}/.openclaw`;
const STATE_DIR = getStateDir(process.env);

// 路径
const PROFILES_DIR = join(STATE_DIR, '.learnings', 'user-profiles');
const SCRIPTS_DIR = join(STATE_DIR, '.learnings', 'scripts');
const LOG_FILE = '/tmp/rocky-know-how-hook.log';

mkdirSync(PROFILES_DIR, { recursive: true });
mkdirSync(SCRIPTS_DIR, { recursive: true });

/**
 * 调试日志
 */
function debugLog(msg) {
  const timestamp = new Date().toISOString();
  appendFileSync(LOG_FILE, `${timestamp} ${msg}\n`);
}

/**
 * 需求触发词
 */
const NEED_PATTERNS = /想要|需要|做个|能不能|帮我|能不能帮我/;

/**
 * 问题触发词（用户在说需求细节）
 */
const DETAIL_PATTERNS = /备份|目录|压缩|保留|服务器|日志|查询|检查|部署/;

/**
 * 反馈触发词（用户有意见）
 */
const FEEDBACK_PATTERNS = /太慢了|不对|不行|错了|有问题|改进|优化|修改/;

/**
 * 确认触发词
 */
const CONFIRM_PATTERNS = /可以|好|行|就这么办|确定|没问题/;

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
 * 创建新画像
 */
function createProfile(userId) {
  return {
    userId: userId,
    updatedAt: new Date().toISOString(),
    preferences: {},
    environment: {},
    commonTasks: [],
    scriptFeedback: {},
    pendingIntent: null,      // 待完善的需求
    currentScript: null,      // 当前脚本
  };
}

/**
 * 调用LLM分析
 */
function callLLM(prompt) {
  try {
    const payload = {
      model: "lingshu-7b",
      messages: [
        { role: "system", content: "你是一个专业的需求分析助手。" },
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
    debugLog("LLM_RESPONSE: " + content.substring(0, 100));
    return content;
  } catch (e) {
    debugLog("LLM_ERROR: " + e.message.substring(0, 50));
    return null;
  }
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
 * 注入内容到上下文
 */
function injectContent(event, path, content) {
  if (Array.isArray(event.context.bootstrapFiles)) {
    event.context.bootstrapFiles.push({
      path: path,
      content: content,
      virtual: true
    });
    debugLog("INJECTED: " + path);
  }
}

/**
 * 生成引导问题
 */
function generateGuidingQuestions(analysis) {
  const intent = analysis.intent || '';
  let questions = [];
  
  // 根据意图生成引导问题
  if (intent.includes('备份')) {
    questions = [
      "备份哪些目录或文件？",
      "保留多少天？",
      "需要压缩吗？",
      "备份目标位置是哪里？"
    ];
  } else if (intent.includes('日志') || intent.includes('查询')) {
    questions = [
      "要查询哪个服务/服务器的日志？",
      "查看什么时间段？",
      "需要过滤关键词吗？"
    ];
  } else if (intent.includes('部署')) {
    questions = [
      "部署什么项目？",
      "部署到哪个环境？",
      "有什么特殊配置吗？"
    ];
  } else if (intent.includes('监控') || intent.includes('负载')) {
    questions = [
      "监控哪台服务器？",
      "多久检查一次？",
      "结果要保存或告警吗？"
    ];
  } else {
    questions = [
      "具体要做什么？",
      "有什么特殊要求吗？",
      "在什么环境下运行？"
    ];
  }
  
  return questions;
}

/**
 * 生成脚本
 */
function generateScript(intent, details, userId) {
  const scriptName = `skill-${Date.now()}.sh`;
  const scriptPath = join(SCRIPTS_DIR, scriptName);
  
  // 构建prompt让LLM生成
  const prompt = `用户需求: ${intent}
用户细节: ${details}

请生成一个bash脚本满足用户需求。
要求：
1. 使用set -e
2. 有清晰的步骤说明
3. 根据用户细节定制
4. 只输出脚本内容，不要其他解释`;

  const scriptContent = callLLM(prompt);
  
  if (scriptContent) {
    writeFileSync(scriptPath, scriptContent);
    execSync(`chmod +x "${scriptPath}"`);
    debugLog("SCRIPT_GENERATED: " + scriptName);
    return { name: scriptName, path: scriptPath, content: scriptContent };
  }
  
  return null;
}

/**
 * 主Handler
 */
async function handler(event) {
  if (event.type !== 'message' || event.action !== 'received') return;

  const message = event.context?.content || '';
  const sessionKey = event.sessionKey || '';
  const userId = sessionKey.split(':').pop() || '';

  debugLog("=== MESSAGE: " + message.substring(0, 50));
  debugLog("USER: " + userId);

  if (message.length < 2) return;

  try {
    // 获取用户画像
    let profile = getUserProfile(userId);
    if (!profile) {
      profile = createProfile(userId);
      saveUserProfile(profile);
      debugLog("PROFILE_CREATED");
    }

    // 获取对话历史
    const history = await getHistory(sessionKey, 5);

    // ===== 阶段1: 识别需求触发 =====
    if (NEED_PATTERNS.test(message)) {
      debugLog("PHASE1: 需求触发 detected");
      
      // 分析意图
      const analysisPrompt = `用户说: "${message}"
分析用户想要什么？用JSON格式回复：
{
  "intent": "意图简述",
  "confidence": 0.0-1.0
}`;
      const analysisResult = callLLM(analysisPrompt);
      
      let intent = message;
      let confidence = 0.5;
      try {
        const parsed = JSON.parse(analysisResult || '{}');
        intent = parsed.intent || message;
        confidence = parsed.confidence || 0.5;
      } catch (e) {}

      // 保存待完善需求
      profile.pendingIntent = intent;
      profile.intentConfidence = confidence;
      saveUserProfile(profile);

      // 生成引导问题
      const analysis = { intent };
      const questions = generateGuidingQuestions(analysis);
      const questionsText = questions.map((q, i) => `${i + 1}. ${q}`).join('\n');
      
      const injection = `# 用户需求确认
用户说: "${message}"
识别意图: ${intent}

请帮我向用户确认以下问题：
${questionsText}

等用户回复后，更新需求细节。`;

      injectContent(event, 'NEED_CLARIFICATION.md', injection);
      return;
    }

    // ===== 阶段2: 用户回复细节 =====
    if (DETAIL_PATTERNS.test(message) && profile.pendingIntent) {
      debugLog("PHASE2: 用户回复细节");
      
      // 合并细节到意图
      const combinedIntent = profile.pendingIntent + '。' + message;
      
      // 生成脚本
      const script = generateScript(profile.pendingIntent, message, userId);
      
      if (script) {
        profile.currentScript = {
          name: script.name,
          path: script.path,
          originalIntent: profile.pendingIntent,
          details: message
        };
        saveUserProfile(profile);

        const injection = `# 脚本已生成
${script.content}

请向用户确认：
"脚本已生成，是否可以？需要修改吗？"

等待用户回复：确认/修改`;

        injectContent(event, 'SCRIPT_READY.md', injection);
      }
      return;
    }

    // ===== 阶段3: 用户确认 =====
    if (CONFIRM_PATTERNS.test(message) && profile.currentScript) {
      debugLog("PHASE3: 用户确认脚本");
      
      // 读取脚本内容（不执行）
      const scriptContent = readFileSync(profile.currentScript.path, 'utf8');
      
      // 记录成功
      if (!profile.commonTasks.includes(profile.currentScript.originalIntent)) {
        profile.commonTasks.push(profile.currentScript.originalIntent);
      }
      profile.lastSuccess = new Date().toISOString();
      profile.currentScript.confirmed = true;
      saveUserProfile(profile);

      // 构建注入内容
      const injPath = 'SCRIPT_CONFIRMED.md';
      const injContent = '脚本已确认保存\n' +
        '脚本路径: ' + profile.currentScript.path + '\n\n' +
        '内容:\n```bash\n' + scriptContent + '\n```\n\n' +
        '脚本已保存备用。';
      injectContent(event, injPath, injContent);
      
      // 清理
      profile.currentScript = null;
      profile.pendingIntent = null;
      saveUserProfile(profile);
      debugLog("PHASE3_COMPLETE: script saved");
      return;
    }

    // ===== 阶段4: 用户反馈/抱怨 =====
    if (FEEDBACK_PATTERNS.test(message) && profile.currentScript) {
      debugLog("PHASE4: 用户反馈");
      
      const injection = `# 用户反馈
"${message}"

请询问用户想要如何改进：
"你想怎么改？"

等待用户回复改进意见。`;

      injectContent(event, 'FEEDBACK.md', injection);
      return;
    }

    // ===== 阶段5: 用户说太慢了（特殊优化）=====
    if (message.includes('太慢') && profile.commonTasks.length > 0) {
      debugLog("PHASE5: 优化询问");
      
      // AI主动询问是否优化
      const recentTask = profile.commonTasks[profile.commonTasks.length - 1];
      
      const injection = `# 优化建议
用户说"${message}"

你之前做过: ${recentTask}

主动询问：
"要帮你优化一下吗？比如改用更快的方式？"

等待用户确认。`;

      injectContent(event, 'OPTIMIZE.md', injection);
      return;
    }

    // ===== 正常对话：更新画像 =====
    // 记录常见任务
    if (DETAIL_PATTERNS.test(message) && !profile.commonTasks.includes(message.substring(0, 20))) {
      // 提取关键词作为常见任务
      const keywords = message.match(/[\u4e00-\u9fff]+/g);
      if (keywords && keywords.length > 0) {
        const task = keywords.slice(0, 3).join('');
        if (!profile.commonTasks.includes(task)) {
          profile.commonTasks.push(task);
          saveUserProfile(profile);
          debugLog("TASK_ADDED: " + task);
        }
      }
    }

  } catch (e) {
    debugLog("ERROR: " + e.message.substring(0, 50));
  }
}

module.exports = handler;
module.exports.default = handler;

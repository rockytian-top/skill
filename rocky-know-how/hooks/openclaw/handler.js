/**
 * rocky-know-how Hook for OpenClaw v1.4.0
 *
 * Agent 启动时注入经验诀窍技能提醒。
 * Agent 关闭时自动分析并记录经验教训。
 * 动态获取工作区路径，适配所有用户环境。
 * 支持多网关实例（通过 OPENCLAW_STATE_DIR 区分）。
 */

const { existsSync, appendFileSync, mkdirSync } = require('fs');
const { join } = require('path');
const { execSync } = require('child_process');

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

/**
 * 写入待处理的经验记录（自动模式）
 */
function writePendingLesson(stateDir, sessionKey, agentId, outcome, message) {
  const pendingDir = join(stateDir, '.learnings', 'pending');
  mkdirSync(pendingDir, { recursive: true });
  
  const timestamp = new Date().toISOString();
  const filename = `lesson_${Date.now()}.json`;
  const filepath = join(pendingDir, filename);
  
  const record = {
    id: `PENDING-${Date.now()}`,
    sessionKey,
    agentId,
    timestamp,
    outcome, // 'success' | 'failure' | 'solved_after_failure'
    message: message.substring(0, 500), // 限制长度
    processed: false
  };
  
  try {
    appendFileSync(filepath, JSON.stringify(record, null, 2) + '\n');
  } catch (e) {
    // 静默失败，不打扰主流程
  }
}

/**
 * 分析会话内容并提取经验（基于启发式规则）
 */
function analyzeAndExtractLesson(transcriptPath, stateDir) {
  if (!existsSync(transcriptPath)) return null;
  
  try {
    const content = require('fs').readFileSync(transcriptPath, 'utf8');
    
    // 启发式规则：检测失败后成功模式
    const hasFailure = /失败|错误|不行|重试|排查/.test(content);
    const hasSuccess = /搞定|成功|解决|完成|好了/.test(content);
    const hasFailureCount = (content.match(/失败|错误/g) || []).length;
    
    // 如果有失败但最终成功，提取关键信息
    if (hasFailure && hasSuccess && hasFailureCount >= 2) {
      // 尝试提取问题关键词
      const lines = content.split('\n');
      const problemLines = [];
      const solutionLines = [];
      
      let inUser = false;
      let inAssistant = false;
      
      for (const line of lines) {
        if (line.includes('"role":"user"')) inUser = true;
        if (line.includes('"role":"assistant"')) inAssistant = true;
        
        // 提取包含问题信号的 user 消息
        if (inUser && /排查|问题|错误|失败/.test(line)) {
          const match = line.match(/"content":"([^"]+)"/);
          if (match && match[1].length > 10 && match[1].length < 200) {
            problemLines.push(match[1].substring(0, 100));
          }
        }
        
        // 提取包含解决信号的 assistant 消息
        if (inAssistant && /搞定|成功|解决|完成/.test(line)) {
          const match = line.match(/"content":"([^"]+)"/);
          if (match && match[1].length > 10 && match[1].length < 300) {
            solutionLines.push(match[1].substring(0, 150));
          }
        }
      }
      
      if (problemLines.length > 0 && solutionLines.length > 0) {
        return {
          problem: problemLines[0].replace(/[^\u4e00-\u9fa5a-zA-Z0-9\s]/g, ' ').trim(),
          solution: solutionLines[0].replace(/[^\u4e00-\u9fa5a-zA-Z0-9\s]/g, ' ').trim(),
          source: 'auto-extract'
        };
      }
    }
  } catch (e) {
    // 分析失败，静默忽略
  }
  
  return null;
}

/**
 * 生成经验 ID
 */
function generateExpId(stateDir) {
  const expFile = join(stateDir, '.learnings', 'experiences.md');
  let maxNum = 0;
  
  try {
    if (existsSync(expFile)) {
      const content = require('fs').readFileSync(expFile, 'utf8');
      const matches = content.match(/EXP-(\d{8})-(\d{3})/g);
      if (matches) {
        for (const m of matches) {
          const num = parseInt(m.replace('EXP-', '').replace(/-/g, ''), 10);
          const curNum = parseInt(m.split('-')[2], 10);
          if (curNum > maxNum) maxNum = curNum;
        }
      }
    }
  } catch (e) {
    // 忽略
  }
  
  const date = new Date();
  const dateStr = `${date.getFullYear()}${String(date.getMonth() + 1).padStart(2, '0')}${String(date.getDate()).padStart(2, '0')}`;
  const newNum = maxNum + 1;
  return `EXP-${dateStr}-${String(newNum).padStart(3, '0')}`;
}

/**
 * 写入最终经验到 experiences.md
 */
function writeExperience(stateDir, expId, problem, solution, tags, area) {
  const expFile = join(stateDir, '.learnings', 'experiences.md');
  
  const entry = `## [${expId}] ${problem}

**Area**: ${area}
**Tags**: ${tags}
**Source**: auto (rocky-know-how hook)
**Created**: ${new Date().toISOString()}

### 问题
${problem}

### 解决
${solution}

---
`;
  
  try {
    appendFileSync(expFile, entry);
  } catch (e) {
    // 静默失败
  }
}

const fs = require('fs');
const logFile = '/tmp/rocky-know-how-hook.log';
function debugLog(msg) {
  fs.appendFileSync(logFile, new Date().toISOString() + ' ' + msg + '\n');
}

const handler = async (event) => {
  // 全事件日志（调试用）
  debugLog("EVENT: " + JSON.stringify({type: event.type, action: event.action, sessionKey: event.sessionKey, contextKeys: event.context ? Object.keys(event.context) : []}));
  
  // 跳过非目标事件
  
  if (!event || typeof event !== 'object') return;
  
  const sessionKey = event.sessionKey || '';
  if (sessionKey.includes(':subagent:')) return; // 子agent不记录
  
  const env = process.env;
  const stateDir = getStateDir(env);
  const workspace = getWorkspace(sessionKey, env);
  const scriptsDir = findScriptsDir(workspace, stateDir);
  
  // === AGENT:BOOTSTRAP 事件 ===
  if (event.type === 'before_agent_start') {
    if (!event.context || typeof event.context !== 'object') return;
    
    const hasData = hasExperienceData(stateDir);
    const dataStatus = hasData ? '有数据' : '暂无数据';

    const REMINDER = `
## 📚 经验诀窍技能 (rocky-know-how) v1.4.1

**核心原则：遇到问题 → 搜经验 → 解决 → 记录**

---

### 🔍 失败自动搜（≥2次必须搜）

当任务失败≥2次时，**立即执行**：
\`\`\`bash
bash ${scriptsDir}/search.sh "失败关键词1" "失败关键词2"
\`\`\`
- 找到经验 → 按方案执行
- 没找到 → 继续排查

---

### ✍️ 成功自动记

任务成功后（哪怕第2次才成功），**立即执行**：
\`\`\`bash
bash ${scriptsDir}/record.sh "问题" "失败过程" "解决方案" "预防" "tag1,tag2" "area"
\`\`\`
area: frontend|backend|infra|tests|docs|config

---

### 📊 经验库

- 位置: ${stateDir}/.learnings/
- 查看: search.sh --cache-info

**重要：经验是团队共享的，你的经验可以帮到其他人！**

---

### 🎯 主动询问时机（必须执行！）

**在以下情况，必须主动发送消息询问用户**：

1. **用户说"解决了"、"搞定了"、"搞定了"**
   → 立即发送："需要帮你记录这个经验吗？"

2. **用户说"失败了"、"不行"、"还是报错"**
   → 立即发送："需要记录这个问题吗？下次可以更快解决"

3. **用户描述的问题明显很棘手（花费时间>5分钟）**
   → 发送："这个问题值得记录到经验库，下次遇到就不用手动了，要记录吗？"

4. **每次成功使用经验解决问题后**
   → 发送："这个问题用经验解决了，需要优化经验吗？"

**询问模板**：
- "需要记录到经验库吗？"
- "需要把解决方案记录下来吗？"
- "这个问题值得收藏，下次遇到就不用再排查了，要记录吗？"

**如果用户回复"要"、"是的"、"记录"**：
\`\`\`bash
bash ${scriptsDir}/record.sh "问题描述" "失败过程" "解决方案" "预防措施" "tag1,tag2" "area"
\`\`\`

**核心：主动询问！用户说"要"就记录，不说就不记录。**
`.trim();

    if (Array.isArray(event.context.bootstrapFiles)) {
      event.context.bootstrapFiles.push({
        path: 'ROCKY_KNOW_HOW_REMINDER.md',
        content: REMINDER,
        virtual: true,
      });
    }
  }
  
  // === MESSAGE:RECEIVED 事件 ===
  // 不再自动记录到 pending，只做日志
  if (event.type === 'message' && event.action === 'received') {
    debugLog("MESSAGE_RECEIVED: " + (event.context?.content || '').substring(0, 50));
  }
};

module.exports = handler;
module.exports.default = handler;

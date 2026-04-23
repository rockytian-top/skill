/**
 * rocky-auto-experience Plugin
 *
 * 自动判断并记录对话经验
 * 在 session:compact:before 触发，分析对话内容，判断是否值得记录
 *
 * @version 1.0.0
 */

import fs from 'node:fs/promises';
import path from 'node:path';
import { existsSync } from 'node:fs';

// 经验分析 Prompt
const ANALYSIS_PROMPT = `你是一个经验整理助手。请分析以下对话，判断是否值得记录为经验。

## 判断标准（满足任一即可）
1. Rocky 遇到了技术问题并找到了解决方案
2. 发现/修复了 bug
3. 做了重要决策或配置变更
4. 踩坑并找到了解法
5. 学到了新知识或新技巧

## 输出格式（严格 JSON）
{
  "isWorthRecording": true/false,
  "experience": "如果值得，用30-50字概括核心经验（陈述句，不要问句）",
  "tags": ["相关标签1-3个，如: macos, ssh, nginx"],
  "confidence": 0.0-1.0（置信度）
}

## 对话内容：
{essages}

## 要求
- 严格按 JSON 格式输出，不要有其他内容
- experience 必须是陈述句
- tags 只用英文或拼音
`;

const MIN_MESSAGE_COUNT = 4;  // 至少2轮对话
const MIN_CONFIDENCE = 0.6;   // 置信度阈值

/**
 * 动态定位 scripts 目录
 */
function findScriptsDir(env) {
  const home = env.HOME || process.env.HOME || '~';
  const candidates = [
    path.join(home, '.openclaw', 'skills', 'rocky-know-how', 'scripts'),
    path.join(home, '.openclaw', 'workspace', 'skills', 'rocky-know-how', 'scripts'),
  ];
  for (const dir of candidates) {
    if (existsSync(path.join(dir, 'record.sh'))) {
      return dir;
    }
  }
  return candidates[0];
}

/**
 * 格式化消息为文本
 */
function formatMessages(messages) {
  if (!Array.isArray(messages)) return '';
  
  const parts = [];
  for (const msg of messages) {
    if (!msg || typeof msg !== 'object') continue;
    
    let content = '';
    if (typeof msg.content === 'string') {
      content = msg.content;
    } else if (Array.isArray(msg.content)) {
      content = msg.content.map(c => {
        if (typeof c === 'string') return c;
        if (c?.text) return c.text;
        if (c?.content) return c.content;
        return '';
      }).join(' ');
    }
    
    if (content) {
      const role = msg.role || 'unknown';
      parts.push(`[${role}]: ${content.slice(0, 500)}`);
    }
  }
  
  return parts.join('\n');
}

/**
 * 转义 shell 特殊字符
 */
function escapeShell(str) {
  if (!str) return '';
  return str.replace(/'/g, "'\\''").replace(/"/g, '\\"');
}

/**
 * 写入经验到 experiences.md
 */
async function writeExperience(recordCmd, log) {
  try {
    const { execSync } = await import('node:child_process');
    execSync(recordCmd, { encoding: 'utf8', timeout: 30000 });
    return true;
  } catch (err) {
    log.error('[auto-experience] record.sh 执行失败: ' + err.message);
    return false;
  }
}

/**
 * 主分析函数
 */
async function analyzeAndRecord(event, ctx) {
  const messages = event.messages || [];
  
  // 过滤：至少需要一定数量的消息
  if (messages.length < MIN_MESSAGE_COUNT) {
    ctx.log.debug('[auto-experience] 消息数不足，跳过: ' + messages.length);
    return;
  }
  
  const env = process.env;
  const scriptsDir = findScriptsDir(env);
  const formattedMessages = formatMessages(messages);
  
  if (!formattedMessages) {
    ctx.log.debug('[auto-experience] 无法解析消息内容，跳过');
    return;
  }
  
  try {
    ctx.log.info('[auto-experience] 开始分析对话，消息数: ' + messages.length);
    
    // 调用 LLM 分析
    const prompt = ANALYSIS_PROMPT.replace('{essages}', formattedMessages);
    const result = await ctx.invokeLLM(prompt, {
      timeoutMs: 30000,
      model: ctx.cfg?.models?.[0] || 'minimax'
    });
    
    // 解析 LLM 返回
    let analysis;
    try {
      // 尝试提取 JSON
      const jsonMatch = result.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        analysis = JSON.parse(jsonMatch[0]);
      } else {
        analysis = JSON.parse(result);
      }
    } catch (parseErr) {
      ctx.log.warn('[auto-experience] LLM 返回格式解析失败: ' + parseErr.message);
      ctx.log.debug('[auto-experience] 原始返回: ' + result.slice(0, 200));
      return;
    }
    
    // 检查分析结果
    if (!analysis.isWorthRecording) {
      ctx.log.info('[auto-experience] 对话无经验价值，跳过');
      return;
    }
    
    if (analysis.confidence < MIN_CONFIDENCE) {
      ctx.log.info('[auto-experience] 置信度不足，跳过: ' + analysis.confidence);
      return;
    }
    
    if (!analysis.experience) {
      ctx.log.warn('[auto-experience] 无经验内容，跳过');
      return;
    }
    
    // 写入经验
    const tags = Array.isArray(analysis.tags) ? analysis.tags.join(',') : 'auto';
    const escapedExp = escapeShell(analysis.experience);
    const recordCmd = `bash '${scriptsDir}/record.sh' --auto '${escapedExp}' --tags '${tags}'`;
    
    ctx.log.info('[auto-experience] 写入经验: ' + analysis.experience);
    
    const success = await writeExperience(recordCmd, ctx);
    
    if (success) {
      ctx.log.info('[auto-experience] ✅ 经验已记录，置信度: ' + analysis.confidence);
    }
    
  } catch (err) {
    ctx.log.error('[auto-experience] 分析过程出错: ' + err.message);
    // 不抛出异常，避免阻塞压缩
  }
}

/**
 * 插件激活
 */
async function activate(ctx) {
  ctx.log.info('[auto-experience] 插件启动 v1.0.0');
  
  // 注册 before_compaction hook
  ctx.hooks.on('before_compaction', async (event) => {
    ctx.log.debug('[auto-experience] before_compaction 触发');
    
    try {
      await analyzeAndRecord(event, ctx);
    } catch (err) {
      ctx.log.error('[auto-experience] Hook 执行错误: ' + err.message);
      // 不抛出异常，避免阻塞压缩流程
    }
  });
  
  ctx.log.info('[auto-experience] 已注册 before_compaction hook');
}

module.exports = { activate };

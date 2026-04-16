# OpenClaw Skills

**版本**: 1.2.0 | **类型**: OpenClaw 技能 + Hook | **许可**: MIT

## 技能列表

| 技能 | 版本 | 说明 |
|------|------|------|
| `rocky-know-how` | 1.1.0 | 经验诀窍技能 |
| `rocky-minimax-media` | 1.3.0 | MiniMax 媒体生成插件 |

---

## rocky-minimax-media

> MiniMax 媒体生成插件 - 图片、视频、TTS语音、音乐

### 功能

| 功能 | 模型 | 说明 |
|------|------|------|
| 🖼️ 图片生成 | `image-01` | 交互式输入描述 |
| 🎬 视频生成 | `MiniMax-Hailuo-2.3` / `2.3-Fast` | 可选模型 |
| 🔊 TTS语音 | `speech-2.8-hd` | 3种音色可选 |
| 🎵 音乐生成 | `music-2.6` / `music-2.5` | 可选模型 |

### 安装

```bash
git clone https://gitee.com/rocky_tian/skill.git
cp -r skill/skills/rocky-minimax-media ~/.openclaw/skills/
```

然后添加到 `openclaw.json` 的 `skills.entries`:
```json
"rocky-minimax-media": {
  "enabled": true
}
```

运行安装脚本:
```bash
cd ~/.openclaw/skills/rocky-minimax-media/scripts
./install.sh  # 交互式输入 API Key
```

重启网关:
```bash
openclaw gateway restart
```

### 使用

```bash
./minimax.sh test   # 测试所有API
./minimax.sh image  # 生成图片
./minimax.sh tts    # TTS语音
./minimax.sh video  # 视频生成
./minimax.sh music  # 音乐生成
```

---

## rocky-know-how

> 经验诀窍技能

失败≥2次搜经验诀窍，解决后写入。写入时同步到原生 memory。

### 安装

```bash
git clone https://gitee.com/rocky_tian/skill.git
cp -r skill/skills/rocky-know-how ~/.openclaw/workspace/skills/
```

### Hook 启用

```bash
openclaw hooks enable rocky-know-how
```

### 工具脚本

| 脚本 | 用途 |
|------|------|
| `search.sh "关键词"` | 搜经验诀窍 |
| `record.sh "问题" "踩坑" "方案" "预防" "tags"` | 写入+同步 |
| `stats.sh` | 统计面板 |
| `promote.sh` | Tag晋升检查 |
| `archive.sh [--days N]` | 归档旧条目 |

---

**仓库**: https://gitee.com/rocky_tian/skill

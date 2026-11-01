# grok-bot-voice

Grok Bot skill：任务完成后在用户 **Mac** 外放「滴滴滴」+ 一两句结果摘要。

如果你是收到本仓库链接的 **Grok Bot / AI 助手**：下面整份 README 就是给你的接入说明。先读完再动手；缺少能力时如实说明缺什么，不要声称已经装好或已经自动播报。

单独收到一个链接，**不等于**授权你改用户长期配置。只有用户明确说「安装 / 接入 / 用这个 skill」时，才进入安装流程；用户说「帮我看看」时只评审。

## 你需要具备的能力

1. 读取本仓库（GitHub 或本地 clone）。
2. 在用户目标 **Mac** 上执行本地命令（Grok Bot：对该机的 `machineId` 跑 Shell）。
3. 能把一份 skill 写入该助手的 Skills（Grok Bot：`UpdateSkill` / 用户 Skills 目录），并能写入一条长期偏好/记忆，让任务完成时主动加载本 skill。

没有第 2 条就无法外放；没有第 3 条就只能手动 `@` skill，不能承诺自动播报。

## 仓库结构

| 路径 | 作用 |
|---|---|
| `skills/task-done-voice-announce/SKILL.md` | 何时播、播什么、何时跳过 |
| `scripts/announce.sh` | 合成并播放（stdin 传文本；失败回退 `say`） |
| `scripts/doctor.sh` | 检查 Mac 依赖是否齐全 |

## 安装步骤（给 Bot）

在用户已连接、要外放的那台 Mac 上执行（用户从某台 Mac 发消息时，默认用那台）。

### 1. 拉取仓库

```bash
git clone https://github.com/travelmocca/grok-bot-voice.git
# 或已有 clone：git -C /path/to/grok-bot-voice pull
```

记下仓库根目录，下文称 `$REPO`。

### 2. 安装播放脚本

```bash
mkdir -p ~/.grokbot-tts
cp "$REPO/scripts/announce.sh" ~/.grokbot-tts/announce.sh
cp "$REPO/scripts/doctor.sh" ~/.grokbot-tts/doctor.sh
chmod +x ~/.grokbot-tts/announce.sh ~/.grokbot-tts/doctor.sh
```

重复安装时：**覆盖脚本**，但不要删除用户已有的 `GROKBOT_TTS_VOICE` 等环境配置。

### 3. 依赖

优先：

```bash
python3 -m pip install --user edge-tts
```

`afplay` 为 macOS 自带。`edge-tts` 不可用时，`announce.sh` 会回退到系统 `say`。

可选音色（默认 `zh-CN-YunxiNeural`）：

```bash
export GROKBOT_TTS_VOICE=zh-CN-YunxiNeural
# 写入用户 shell 配置或 launch 环境，按该助手习惯保存即可
```

### 4. 自检

```bash
~/.grokbot-tts/doctor.sh
printf '%s\n' '滴滴滴。这是安装验证播报。' | ~/.grokbot-tts/announce.sh
```

- `doctor.sh` 全 OK，且 `announce.sh` 退出码 0 → **脚本可用**（仍不能证明用户一定听见：静音/输出设备另说）。
- 任一失败 → 向用户报告具体 FAIL 项，停止声称安装成功。

### 5. 写入助手 Skill

把 `$REPO/skills/task-done-voice-announce/SKILL.md` 的正文安装为该助手的 skill（名称可用「任务完成语音播报」）。Grok Bot 可用 `UpdateSkill` 写入同等内容。

### 6. 接入「自动播报」（与「脚本可用」分开）

本仓库**没有**宿主级 hook。Grok Bot 上请写入助手 **profile / 偏好记忆**，大意如下（可按用户口吻微调）：

> 完成委托任务，或敲定会长期生效的偏好/播报规则后：加载「任务完成语音播报」skill，在用户 Mac 外放「滴滴滴」+ 一两句摘要；纯问意见/闲聊不播。播放用 `~/.grokbot-tts/announce.sh`，文本经 stdin 传入。

| 状态 | 含义 |
|---|---|
| 脚本可用 | `doctor` + 试播成功 |
| 自动接入 | 已写入上述偏好/记忆（或用户平台若有真正的完成事件再绑事件） |

不要把「已记住」说成「已实现系统 hook」。没有事件接口时，自动播报依赖助手遵守偏好，可能漏触发——要在回复里诚实说明。

## 何时播（摘要）

详见 Skill。简表：

- **播**：委托任务刚完成；敲定长期偏好/配置结论。
- **不播**：纯问意见、闲聊、中间进度（除非用户明确要求用声音说）。
- **同一结果只播一次**；部分完成或仍等用户确认时不播。
- 聊天里仍要短文字交付；外放只是摘要。

## 播放命令（给 Bot 执行）

在目标 Mac 上：

```bash
printf '%s\n' '滴滴滴。我已经完成了某某事。' | ~/.grokbot-tts/announce.sh
```

不要把用户摘要直接塞进未转义的 shell 双引号拼命令；优先 **stdin**。失败时：文字交付同一摘要，并说明外放失败。

## 向用户汇报模板

安装结束后用类似结构回复用户：

> 已安装任务完成播报。  
> 播放目标：\<Mac 名称 / machineId\>  
> 音色：\<VOICE\>  
> 触发方式：助手偏好记忆（非系统 hook）  
> 验证结果：doctor … / 试播 …  
> 关闭：删掉该偏好，或不再加载该 skill；换音色：设 `GROKBOT_TTS_VOICE`

## 范围

第一版只支持 **用户 Mac 外放**。Bot 若只在服务器上跑、又不能对用户 Mac 执行命令，应说明暂不支持，不要在服务器上播放后声称用户听到了。

<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### 随处开口说，用你的语言——即刻得到干净文本，全程本地运行。

一款快速、私密、开源的 macOS 语音输入应用。按住一个按键说话——
无论是 English、中文、Español、日本語，还是其他 30 多种语言——你的话语都会
以干净、带标点的文本形式落入你正在使用的任何应用中。你的音频永远不会离开
你的 Mac——一切都在本地设备上运行。

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-26%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)
&nbsp;[![Languages](https://img.shields.io/badge/dictation-30%2B%20languages-F2743E)](#languages)
&nbsp;[![License](https://img.shields.io/badge/license-MIT-111111)](../../LICENSE)

[English](../../README.md) ·
**简体中文** ·
[Deutsch](./README.de.md) ·
[Español](./README.es.md) ·
[Français](./README.fr.md) ·
[Italiano](./README.it.md) ·
[日本語](./README.ja.md) ·
[한국어](./README.ko.md) ·
[Nederlands](./README.nl.md) ·
[Polski](./README.pl.md) ·
[Português](./README.pt-BR.md) ·
[Русский](./README.ru.md) ·
[Svenska](./README.sv.md) ·
[Türkçe](./README.tr.md) ·
[Українська](./README.uk.md) ·
[Tiếng Việt](./README.vi.md)

_本翻译尽力保持更新，以英文版 README 为准；欢迎通过 [PR](../../CONTRIBUTING.md) 提交修正。_

</div>

---

> **北极星目标：** 随处开口说，即刻得到干净文本，而你的音频永远不会
> 离开你的 Mac。

## 为什么选择 VoiceType

- 🔒 **隐私即设计。** 音频和转写文本都留在你的 Mac 上。没有账号，没有遥测，没有云端——根本没有需要你去关闭的选项。
- ⚡ **低延迟就是核心功能。** 原生 Swift 加上 Apple 的本地语音模型——从说话到出字的时间就是我们优化的目标。
- 🌍 **说你的语言。** 支持 30 多种语言听写——不只是英语。文本清理理解每种语言的书写习惯（中文的全角标点、口述的「句号」、按语言识别的口头语），应用会自动挑选真正支持你所用语言的引擎，界面本身也提供 16 种语言版本。
- 🎙️ **随处按键即说。** 全局快捷键在任何应用中都有效；清理后的文本会直接插入到光标所在位置。
- ✨ **智能清理。** 添加标点、修正大小写、去除口头语——绝不改动你说的内容。
- 📊 **可视化你的声音。** 简洁的主页仪表盘记录你的字数、语速和连续使用天数，配有完整的活动热力图和一份友好的本地生成使用摘要——全部在你的 Mac 上计算。
- 🧩 **可插拔引擎。** 默认使用 Apple 内置模型，还可选择下载本地升级引擎——NVIDIA Parakeet——并随时切换（一次启用一个）。

## 下载与安装

1. 从最新版本页面 **[⬇ 下载 VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)**。
2. 打开 DMG，把 **VoiceType** 拖入 **「应用程序」** 文件夹。应用已
   **经过 Apple 签名与公证**，双击即可正常启动——无需绕过
   Gatekeeper。
3. 授予 VoiceType 请求的三项权限——**麦克风**、
   **语音识别** 和 **辅助功能**——即可开始使用。

> 需要 **macOS 26** 或更高版本（Apple Silicon）。

**更新是自动的。** VoiceType 会在后台检查新版本
（也可通过 **「检查更新…」** 手动检查），并使用
[Sparkle](https://sparkle-project.org) 原地安装——每次更新都经过加密签名
和验证。无需重新下载。_（自动更新自 v0.1.1 起可用；最初的
v0.1.0 版本需要手动替换一次。）_

## 使用方法

在任何地方按住 **右 Option（⌥）** 键开始说话。屏幕上会出现一个磨砂质感的
胶囊，实时显示声音波形；松开按键后，清理好的文本就会插入到当前聚焦的应用中。
随时打开主窗口即可查看你的 **主页仪表盘**——语速、总字数、活动热力图，以及
你常在哪些应用中听写。按键、语言、引擎和清理方式都可以在 **设置** 中更改。

## 引擎

一切都在本地设备上运行。Apple 的模型内置于 macOS 并被默认选用；你也可以在
侧边栏的 **「模型」** 页面下载其他本地引擎并在它们之间切换（一次只启用一个）。

| 阶段 | 默认（内置） | 可选替代方案（本地运行） |
| --- | --- | --- |
| **转写** | Apple `SpeechTranscriber` | **Parakeet TDT 0.6B V3**（NVIDIA，经由 [FluidAudio](https://github.com/FluidInference/FluidAudio)）· **Whisper Base**（OpenAI，经由 [WhisperKit](https://github.com/argmaxinc/WhisperKit)）——按需下载 |
| **清理** | 内置规则（即时、确定性） | Apple Intelligence（`FoundationModels`）——内置于 macOS，无需下载 |

可下载的模型只需按需获取一次（推理时不连接云端——你的音频依然
不会离开 Mac），并以 CoreML 形式运行在 Apple 神经网络引擎上。
如果你选择的引擎无法运行，VoiceType 会自动回退到可用引擎，并且
始终退化为纯文本输出，而不是直接失败。

> Parakeet 语音模型版权归 NVIDIA 所有，采用
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) 许可。FluidAudio 为
> Apache-2.0。Whisper 为 OpenAI（MIT）；WhisperKit 为 MIT。

<a name="languages"></a>
## 语言

VoiceType 是端到端的多语言应用，而不是「英语加字幕」：

- **支持 30 多种语言听写**——English、中文、Español、Français、Deutsch、
  日本語、한국어、Português、Русский、Tiếng Việt 等。语言由你来选择；
  VoiceType 从不猜测。
- **引擎与你的语言相匹配。** 每个语音模型都声明自己支持的语言
  （Parakeet 仅支持欧洲语言；Nemotron 覆盖包括中文在内的 40 种
  语言区域；Whisper 支持广泛的多语言；Apple 的支持列表来自 macOS）。
  无法处理你所用语言的模型会显示为灰色，VoiceType 会自动切换到
  能够处理的引擎。
- **清理功能懂你的语言。** 每种语言都附带一个小巧、可审阅的
  「语言包」：包括该语言的口头语（嗯/呃、ähm、euh——绝不误删有实际
  含义的词）、标点习惯（中文和日文使用全角的 。，？，口述的
  「句号」「読点」会渲染为相应符号），以及疑问句判断规则。
- **应用本身已本地化** 为 16 种语言，跟随你的 macOS
  系统语言（也支持在「系统设置」中为单个应用单独设置语言）。

没有你的语言，或者某处翻译不准确？添加一种语言被刻意设计得很
轻量——UI 翻译完全不需要写 Swift 代码——详见
[docs/LOCALIZATION.md](../LOCALIZATION.md)。

<a name="privacy"></a>
## 隐私

音频和转写文本只留在你的 Mac 上，没有例外——根本不存在云端路径。
不会向设备外记录任何日志，音频也从不写入磁盘。就连那份友好的使用
摘要也只基于聚合计数生成——绝不涉及你的转写文本内容。这是本项目的
宪法级不变量，而不是将来可能更改的某个设置项。

## 从源码构建

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## 参与贡献

欢迎贡献。请先阅读[贡献指南](../../CONTRIBUTING.md)，
了解开发要求、隐私方面的期望以及 Pull Request 规范。
想让 VoiceType 支持你的语言？[docs/LOCALIZATION.md](../LOCALIZATION.md)
提供了完整清单——UI 翻译完全不需要写 Swift 代码，而为新语言提升
听写质量也只需一个有完善文档说明的文件。
所有参与者都应遵守[行为准则](../../CODE_OF_CONDUCT.md)。
如发现安全漏洞，请按照我们
[安全策略](../../SECURITY.md)中的私密报告流程处理。

## 架构

原生 **Swift 6 / SwiftUI** Dock 应用（macOS 26），带主页仪表盘。全局
按住即说快捷键 · AVAudioEngine 麦克风采集 · 可插拔的本地
转写引擎 · 可插拔的清理引擎 · 粘贴/辅助功能文本注入 · 一个
悬浮录音 HUD。核心库（`VoiceTypeKit`）纯净且有单元测试覆盖；应用
目标包含系统引擎和 UI。详情见 [`CLAUDE.md`](../../CLAUDE.md)，
并通过 `specs/` 持续演进。

## 许可证

[MIT](../../LICENSE) © 2026 Michael Li。

应用捆绑的第三方组件和本地模型保留各自的
许可证——参见 [`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md)（同时
也随应用包一起分发）。

## 这个仓库如何运作

VoiceType 是一个独立的产品仓库，日常由一个智能体运营（**外层
循环**：分类 → 审查 → 合并/上报），人类则通过编辑 `specs/`
提供**品味**。本地开发时它链接 [`@aros/*`](../../../agent-repo-os) 框架。
运营规则见 [`CLAUDE.md`](../../CLAUDE.md)。

## 仓库结构

```
VoiceType/
├── CLAUDE.md          # 智能体的运营规则
├── Package.swift      # SwiftPM：VoiceTypeKit（核心）+ VoiceType（应用）
├── Sources/
│   ├── VoiceTypeKit/  # 纯净、有测试的核心：协议、管线、清理、解析器
│   └── VoiceType/     # 应用：快捷键、音频、引擎、文本注入、仪表盘 UI
├── Tests/             # VoiceTypeKit 单元测试
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── specs/             # 人类的操作面——产品方向（智能体不编辑）
└── README.md
```

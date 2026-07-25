<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### 33言語で音声入力。すぐにきれいなテキストへ。すべてデバイス上で。

高速でプライベートな、オープンソースの macOS 音声入力アプリ。キーを押しながら
話すだけ——日本語、English、中文、Español、العربية、हिन्दी、Tiếng Việt、
そのほか26言語で——話した言葉が、いま使っているアプリにきれいな句読点付きの
テキストとして入力されます。

**端から端まで多言語対応**。音声モデルはあなたの言語に合わせて選ばれ、整形処理は
その言語の句読点とフィラーを理解し、アプリ自身の UI も16言語で提供されます。
そのすべてが**デバイス上**で動作します——どの言語でも、音声が Mac の外に出ることは
ありません。

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)
&nbsp;[![Dictation languages](https://img.shields.io/badge/dictation-33%20languages-F2743E)](../LANGUAGES.md)
&nbsp;[![Interface languages](https://img.shields.io/badge/interface-16%20languages-F2743E)](../LANGUAGES.md#interface-languages)
&nbsp;[![License](https://img.shields.io/badge/license-MIT-111111)](../../LICENSE)

[English](../../README.md) ·
[简体中文](./README.zh-Hans.md) ·
[Deutsch](./README.de.md) ·
[Español](./README.es.md) ·
[Français](./README.fr.md) ·
[Italiano](./README.it.md) ·
**日本語** ·
[한국어](./README.ko.md) ·
[Nederlands](./README.nl.md) ·
[Polski](./README.pl.md) ·
[Português](./README.pt-BR.md) ·
[Русский](./README.ru.md) ·
[Svenska](./README.sv.md) ·
[Türkçe](./README.tr.md) ·
[Українська](./README.uk.md) ·
[Tiếng Việt](./README.vi.md)

_この翻訳はベストエフォートで提供されています。正式な内容は英語版 README を参照してください。修正の提案は[プルリクエスト](../../CONTRIBUTING.md)で歓迎します。_

</div>

---

> **North star:** どこでも話すだけで、きれいなテキストが瞬時に得られる。音声が Mac の
> 外に出ることはありません。

## VoiceType を選ぶ理由

- 🌍 **字幕付きの英語ではなく、端から端まで多言語対応。** [33言語](../LANGUAGES.md)で音声入力できます。VoiceType はあなたの言語を実際にサポートする音声モデルを選び、*その言語*の慣習——中文の全角句読点、音声の「句号」、言語ごとのフィラー——に従って整形し、UI 自体も16言語で提供します。
- 🔒 **どの言語でもプライベート。** 音声も文字起こしも Mac の中に留まります。アカウントなし、テレメトリなし、クラウドなし——「難しい言語だけサーバーに送る」という経路そのものが存在しないので、オフにする設定もありません。
- ⚡ **低遅延こそが機能です。** ネイティブ Swift とデバイス上の音声モデル——話してから文字になるまでの時間を最適化しています。
- 🎙️ **どこでもプレストゥトーク。** グローバルホットキーはどのアプリでも動作し、整えられたテキストはカーソル位置にそのまま挿入されます。
- ✨ **スマートなクリーンアップ。** 句読点、大文字化、フィラー語の除去——あなたの言葉そのものは決して変えません。
- 📊 **あなたの声を可視化。** 落ち着いたホームダッシュボードが単語数、ペース、連続利用日数を記録し、アクティビティヒートマップとオンデバイス生成の親しみやすい利用サマリーを表示——すべて Mac 上で計算されます。
- 🧩 **差し替え可能なエンジン。** 標準では Apple の内蔵モデル。さらに任意でローカルの強化エンジン——NVIDIA Parakeet、NVIDIA Nemotron、OpenAI Whisper——をダウンロードして切り替えられます（同時に有効なのは1つ）。

## ダウンロードとインストール

1. 最新リリースから **[⬇ VoiceType.dmg をダウンロード](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)**します。
2. DMG を開き、**VoiceType** を**「アプリケーション」**フォルダにドラッグします。
   アプリは **Apple により署名・公証済み**なので、通常のダブルクリックでそのまま起動
   します——Gatekeeper の回避手順は不要です。
3. VoiceType が求める 3 つの権限——**マイク**、**音声認識**、**アクセシビリティ**——を
   許可すれば準備完了です。

> **macOS 14** 以降（Apple Silicon）が必要です。

**アップデートは自動です。** VoiceType はバックグラウンドで（または**「アップデートを確認…」**
からオンデマンドで）新バージョンを確認し、[Sparkle](https://sparkle-project.org) により
その場でインストールします——すべてのアップデートは暗号署名され検証されます。再ダウン
ロードは不要です。_（自動アップデートは v0.1.1 以降で動作します。最初のビルドである
v0.1.0 のみ、一度手動で置き換える必要があります。）_

## 使い方

どこでも **右 Option（⌥）** を押しながら話し始めてください。すりガラス風のピルが現れ、
聞き取り中はライブ波形を表示します。キーを離すと、整えられたテキストがフォーカス中の
アプリに挿入されます。ウインドウはいつでも開いて**ホームダッシュボード**を確認できます
——ペース、合計、アクティビティヒートマップ、どこで音声入力したか。キー、言語、エンジン、
クリーンアップは**「設定」**で変更できます。

## エンジン

すべてオンデバイスで動作します。Apple のモデルは macOS に内蔵されておりデフォルトで
選択されています。サイドバーの**「モデル」**ページから他のローカルエンジンをダウンロード
して切り替えられます（同時に有効なのは 1 つ）。

| エンジン | 言語数 | 備考 |
| --- | --- | --- |
| **Apple Speech**（標準） | macOS により異なる | 内蔵、ダウンロード不要。macOS 26 以降は `SpeechTranscriber`、macOS 14–15 ではデバイス上の `SFSpeechRecognizer` |
| **Parakeet TDT 0.6B V3** | **25** — ヨーロッパ言語のみ | NVIDIA、[FluidAudio](https://github.com/FluidInference/FluidAudio) 経由。最速。CJK 非対応 |
| **Nemotron 3.5 ASR 0.6B** | CJK・アラビア語・ヒンディー語を含む **40ロケール** | NVIDIA、FluidAudio 経由。多言語の主力 |
| **Whisper Base** | **99** | OpenAI、[WhisperKit](https://github.com/argmaxinc/WhisperKit) 経由。最も広いカバー範囲 |

整形処理は内蔵ルール（即時・決定論的）が標準です。Apple Intelligence
（`FoundationModels`、macOS 26 以降）は macOS に組み込まれた任意のアップグレードで、
ダウンロードは不要です。言語とエンジンの完全な対応表は
[**docs/LANGUAGES.md**](../LANGUAGES.md) にあります。

ダウンロード可能なモデルは、必要になったとき一度だけ取得され（推論時にクラウドは使わ
れず、音声は変わらず Mac の外に出ません）、Apple Neural Engine 上で CoreML として動作
します。選択したエンジンが動作できない場合、VoiceType は利用可能なエンジンに自動的に
フォールバックし、失敗する代わりに常にプレーンテキストへ段階的に切り替えます。

> Parakeet 音声モデルは © NVIDIA、
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) でライセンスされています。
> FluidAudio は Apache-2.0、Whisper は OpenAI（MIT）、WhisperKit は MIT です。

<a name="languages"></a>
## 言語

多くの音声入力アプリは英語向けに作られ、あとから翻訳されます。VoiceType は
どの言語も一級市民として扱います——ここが私たちのいちばんのこだわりです。

音声入力**33言語** · 手書きの整形ルールを持つ**16言語** · UI 翻訳済み**16言語** ·
クラウドを必要とする言語は**0**。

アラビア語 · ブルガリア語 · 简体中文 · クロアチア語 · チェコ語 · デンマーク語 ·
Nederlands · English · エストニア語 · フィンランド語 · Français · Deutsch ·
ギリシャ語 · हिन्दी · ハンガリー語 · Italiano · 日本語 · 한국어 · ラトビア語 ·
リトアニア語 · マルタ語 · Norsk · Polski · Português · ルーマニア語 · Русский ·
スロバキア語 · スロベニア語 · Español · Svenska · Türkçe · Українська · Tiếng Việt

ここでいう「多言語対応」の中身：

- **言語を選ぶのはあなた。VoiceType は推測しません。** 自動判定は外れたときに
  もっともらしい誤りを生むため、提供していません。
- **エンジンは言語に合わせて選ばれます。** 各音声モデルは対応言語を宣言しています
  （Parakeet はヨーロッパ言語のみ、Nemotron は中国語を含む40ロケール、Whisper は
  99言語、Apple の一覧は macOS から取得）。あなたの言語を扱えないモデルはグレー表示に
  なり、VoiceType は扱えるエンジンへ切り替えます。
- **整形処理は言語を理解します。** 16言語には小さく確認しやすい「言語パック」が
  付属します。その言語のフィラー（嗯/呃、ähm、euh——意味を持つ語は決して含めません）、
  句読点の慣習（中国語と日本語は全角の。，？、音声の「句号」「読点」を記号として
  出力）、疑問文の判定ルールです。それ以外の言語も、忠実な文字起こしと中立的な整形が
  行われます。
- **UI は16言語にローカライズ**され、macOS のシステム言語に従います。音声入力の言語
  とは独立しているので、日本語 UI のままポルトガル語で音声入力できます。
- **水増しではなく厳選。** Whisper の99言語を明日にでも並べることはできますが、
  私たちはエンジンが本当に得意な言語だけを提供し、それをテストで担保しています。

📖 **[言語対応表・品質ティア・既知の課題はこちら →](../LANGUAGES.md)**

あなたの言語がない、または翻訳がおかしい？ 言語の追加は意図的に小さく保たれています
——UI の翻訳に Swift は一切不要です——[docs/LOCALIZATION.md](../LOCALIZATION.md) を
ご覧ください。機械生成された言語パックは、とりわけネイティブスピーカーの目を必要と
しています。

## プライバシー

音声と文字起こしは Mac の中に留まります。例外はありません——クラウドへの経路は存在
しません。デバイス外にログが送られることはなく、音声がディスクに書き込まれることも
ありません。親しみやすい利用サマリーでさえ、集計された数値のみから作られます——
文字起こしの本文は決して使いません。これはプロジェクトの憲法的な不変条件であり、
後から変わりうる設定ではありません。

## ソースからビルド

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## コントリビューション

コントリビューションを歓迎します。開発要件、プライバシーに関する期待事項、プル
リクエストのガイダンスについては[コントリビューションガイド](../../CONTRIBUTING.md)を
お読みください。VoiceType をあなたの言語で使いたいですか？
[docs/LOCALIZATION.md](../LOCALIZATION.md) にチェックリストがあります——UI の翻訳に
Swift は一切不要で、新しい言語の音声入力品質はドキュメント完備のファイル 1 つ分の
作業です。
すべての参加者には[行動規範](../../CODE_OF_CONDUCT.md)の遵守をお願いしています。
脆弱性については、[セキュリティポリシー](../../SECURITY.md)にある非公開の報告手順に
従ってください。

## アーキテクチャ

ネイティブ **Swift 6 / SwiftUI** の Dock アプリ（macOS 14）で、ホームダッシュボードを
備えています。グローバルなプッシュトゥトークホットキー · AVAudioEngine によるマイク
キャプチャ · プラガブルなオンデバイス文字起こし · プラガブルなクリーンアップ ·
ペースト／アクセシビリティによるテキスト挿入 · フローティングの録音 HUD。コア
（`VoiceTypeKit`）は純粋でユニットテスト済み、アプリターゲットがシステムエンジンと
UI を保持します。詳細は [`CLAUDE.md`](../../CLAUDE.md) にあり、`specs/` を通じて
進化します。

## ライセンス

[MIT](../../LICENSE) © 2026 Michael Li.

アプリに同梱されるサードパーティコンポーネントとオンデバイスモデルは、それぞれの
ライセンスを保持します——[`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md)
を参照してください（アプリバンドル内にも同梱されています）。

## このリポジトリの運営方法

VoiceType はスタンドアロンのプロダクトリポジトリで、日々の運営はエージェントが担い
（**アウターループ**：トリアージ → レビュー → マージ／エスカレーション）、人間は
`specs/` を編集することで**テイスト**を与えます。ローカル開発時には
[`@aros/*`](../../../agent-repo-os) フレームワークをリンクします。運用ルールは
[`CLAUDE.md`](../../CLAUDE.md) を参照してください。

## リポジトリ構成

```
VoiceType/
├── CLAUDE.md          # エージェントの運用ルール
├── Package.swift      # SwiftPM: VoiceTypeKit（コア）+ VoiceType（アプリ）
├── Sources/
│   ├── VoiceTypeKit/  # 純粋でテスト済みのコア：プロトコル、パイプライン、クリーンアップ、リゾルバ
│   └── VoiceType/     # アプリ：ホットキー、オーディオ、エンジン、テキスト挿入、ダッシュボード UI
├── Tests/             # VoiceTypeKit ユニットテスト
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── docs/              # LANGUAGES.md（言語対応表）· LOCALIZATION.md · readme/
├── specs/             # 人間の担当領域——プロダクトの方向性（エージェントは編集しない）
└── README.md
```

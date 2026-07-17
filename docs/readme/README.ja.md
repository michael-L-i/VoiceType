<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### どこでも、あなたの言語で話すだけ——きれいなテキストを瞬時に、すべてオンデバイスで。

高速でプライベートな、オープンソースの macOS 用音声入力アプリです。キーを押しながら
話すだけ——English、中文、Español、日本語など 30 以上の言語に対応——使用中のどのアプリ
にも、句読点の整ったきれいなテキストとして入力されます。音声が Mac の外に出ることは
ありません——すべてオンデバイスで動作します。

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)
&nbsp;[![Languages](https://img.shields.io/badge/dictation-30%2B%20languages-F2743E)](#languages)
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

- 🔒 **設計段階からプライベート。** 音声も文字起こしも Mac の中に留まります。アカウント不要、テレメトリなし、クラウドなし——オプトアウトするものが最初から存在しません。
- ⚡ **低レイテンシこそが機能。** ネイティブ Swift と Apple のオンデバイス音声モデルにより、話してからテキストになるまでの時間を最優先で最適化しています。
- 🌍 **あなたの言語を話します。** 30 以上の言語で音声入力が可能——英語だけではありません。クリーンアップは各言語の慣習を理解し（中文の全角句読点、話し言葉の「句号」、言語ごとのフィラー語）、アプリはその言語を実際にサポートするエンジンを選択し、UI 自体も 16 言語に対応しています。
- 🎙️ **どこでもプレストゥトーク。** グローバルホットキーはどのアプリでも動作し、整えられたテキストはカーソル位置にそのまま挿入されます。
- ✨ **スマートなクリーンアップ。** 句読点、大文字化、フィラー語の除去——あなたの言葉そのものは決して変えません。
- 📊 **あなたの声を可視化。** 落ち着いたホームダッシュボードが単語数、ペース、連続利用日数を記録し、アクティビティヒートマップとオンデバイス生成の親しみやすい利用サマリーを表示——すべて Mac 上で計算されます。
- 🧩 **プラガブルなエンジン。** デフォルトは Apple の内蔵モデル。オプションのオンデバイスアップグレードとして NVIDIA Parakeet をダウンロードし、切り替えて使えます（同時に有効なのは 1 つ）。

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

| ステージ | デフォルト（内蔵） | オプションの代替（オンデバイス） |
| --- | --- | --- |
| **文字起こし** | Apple `Speech` | **Parakeet TDT 0.6B V3**（NVIDIA、[FluidAudio](https://github.com/FluidInference/FluidAudio) 経由）· **Whisper Base**（OpenAI、[WhisperKit](https://github.com/argmaxinc/WhisperKit) 経由）——オンデマンドでダウンロード |
| **クリーンアップ** | 内蔵ルール（即時・決定的） | Apple Intelligence（`FoundationModels`, macOS 26+）——macOS に内蔵、ダウンロード不要 |

ダウンロード可能なモデルは、必要になったとき一度だけ取得され（推論時にクラウドは使わ
れず、音声は変わらず Mac の外に出ません）、Apple Neural Engine 上で CoreML として動作
します。選択したエンジンが動作できない場合、VoiceType は利用可能なエンジンに自動的に
フォールバックし、失敗する代わりに常にプレーンテキストへ段階的に切り替えます。

> Parakeet 音声モデルは © NVIDIA、
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) でライセンスされています。
> FluidAudio は Apache-2.0、Whisper は OpenAI（MIT）、WhisperKit は MIT です。

<a name="languages"></a>
## 言語

VoiceType は端から端まで多言語対応です。「字幕付きの英語アプリ」ではありません：

- **30 以上の言語で音声入力**——English、中文、Español、Français、Deutsch、日本語、
  한국어、Português、Русский、Tiếng Việt など。言語はあなたが選びます。VoiceType が
  推測することはありません。
- **エンジンは言語に合わせて選ばれます。** 各音声モデルは対応言語を宣言しています
  （Parakeet はヨーロッパ言語のみ、Nemotron は中国語を含む 40 ロケール、Whisper は
  幅広い多言語対応、Apple のリストは macOS 由来）。あなたの言語を扱えないモデルは
  グレー表示になり、VoiceType は扱えるものに切り替えます。
- **クリーンアップは言語を理解しています。** 各言語には小さくレビュー可能な「言語
  パック」が付属します：フィラー語（嗯/呃、ähm、euh——意味を持つ語は決して対象に
  しません）、句読点の慣習（中国語・日本語の全角「。，？」、話し言葉の「句号/読点」を
  記号として出力）、疑問文のヒューリスティクスです。
- **アプリ自体もローカライズ済み**で、16 言語に対応し、macOS のシステム言語に従います
  （システム設定でのアプリごとの言語指定も有効です）。

あなたの言語がない、または翻訳がおかしい場合は？ 言語の追加は意図的に小さな作業に
なっています——UI の翻訳に Swift は一切不要です。詳しくは
[docs/LOCALIZATION.md](../LOCALIZATION.md) をご覧ください。

<a name="privacy"></a>
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
├── specs/             # 人間の担当領域——プロダクトの方向性（エージェントは編集しない）
└── README.md
```

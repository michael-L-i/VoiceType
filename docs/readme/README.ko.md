<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### 어디서나 내 언어로 말하면 — 깔끔한 텍스트가 즉시, 모두 온디바이스로.

빠르고 프라이빗한 macOS용 오픈 소스 음성 받아쓰기 앱입니다. 키를 누른 채
말하기만 하면 — English, 中文, Español, 日本語 등 30개 이상의 언어로 —
사용 중인 어떤 앱에든 문장 부호가 정리된 깔끔한 텍스트로 입력됩니다.
오디오는 절대 Mac 밖으로 나가지 않으며, 모든 것이 온디바이스에서 실행됩니다.

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
[日本語](./README.ja.md) ·
**한국어** ·
[Nederlands](./README.nl.md) ·
[Polski](./README.pl.md) ·
[Português](./README.pt-BR.md) ·
[Русский](./README.ru.md) ·
[Svenska](./README.sv.md) ·
[Türkçe](./README.tr.md) ·
[Українська](./README.uk.md) ·
[Tiếng Việt](./README.vi.md)

_이 문서는 최선을 다해 번역한 것으로, 영어 README가 공식 문서입니다. 수정 제안은 [PR](../../CONTRIBUTING.md)로 환영합니다._

</div>

---

> **북극성:** 어디서나 말하면 즉시 깔끔한 텍스트를 얻고, 오디오는 절대
> Mac 밖으로 나가지 않습니다.

## 왜 VoiceType인가

- 🔒 **설계부터 프라이빗합니다.** 오디오와 받아쓰기 기록은 Mac에만 남습니다. 계정도, 원격 측정도, 클라우드도 없습니다 — 애초에 해제할 옵션 자체가 없습니다.
- ⚡ **지연 시간이 곧 기능입니다.** Apple의 온디바이스 음성 모델과 네이티브 Swift로 만들어져, 말이 텍스트가 되기까지의 시간을 최우선으로 최적화합니다.
- 🌍 **당신의 언어를 말합니다.** 영어뿐 아니라 30개 이상의 언어로 받아쓰기할 수 있습니다. 정리 기능은 각 언어의 관습(전각 中文 문장 부호, 말로 하는 句号, 언어별 군말)을 이해하고, 앱은 사용 언어를 실제로 지원하는 엔진을 선택하며, UI 자체도 16개 언어로 제공됩니다.
- 🎙️ **어디서나 눌러서 말하기.** 전역 단축키가 모든 앱에서 동작하며, 정리된 텍스트는 커서가 있는 바로 그 자리에 삽입됩니다.
- ✨ **스마트한 정리.** 문장 부호, 대문자 처리, 군말 제거 — 단, 당신이 한 말은 절대 바꾸지 않습니다.
- 📊 **내 목소리를 한눈에.** 차분한 홈 대시보드가 단어 수, 말하는 속도, 연속 사용 일수를 보여 주고, 전체 활동 히트맵과 친근한 온디바이스 사용 요약까지 제공합니다 — 모두 Mac에서 계산됩니다.
- 🧩 **교체 가능한 엔진.** 기본은 Apple 내장 모델이며, 선택적으로 온디바이스 업그레이드 모델 — NVIDIA Parakeet — 을 다운로드해 한 번에 하나씩 전환해 사용할 수 있습니다.

## 다운로드 및 설치

1. 최신 릴리스에서 **[⬇ VoiceType.dmg 다운로드](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)**.
2. DMG를 열고 **VoiceType**을 **응용 프로그램** 폴더로 드래그합니다. 앱은
   **Apple의 서명 및 공증을 받았기** 때문에 일반적인 더블 클릭으로 바로
   실행됩니다 — Gatekeeper 우회가 필요 없습니다.
3. VoiceType이 요청하는 세 가지 권한 — **마이크**, **음성 인식**,
   **손쉬운 사용** — 을 허용하면 준비 완료입니다.

> **macOS 14** 이상(Apple Silicon)이 필요합니다.

**업데이트는 자동입니다.** VoiceType은 백그라운드에서(또는 **업데이트 확인…**
메뉴로 수동으로) 새 버전을 확인하고 [Sparkle](https://sparkle-project.org)로
제자리에서 설치합니다 — 모든 업데이트는 암호학적으로 서명되고 검증됩니다.
다시 다운로드할 필요가 없습니다. _(자동 업데이트는 v0.1.1부터 동작하며, 최초
빌드인 v0.1.0만 한 번 수동으로 교체해야 합니다.)_

## 사용 방법

어디서든 **오른쪽 Option(⌥)** 키를 누른 채 말을 시작하세요. 듣는 동안 실시간
파형을 보여 주는 반투명 알약 모양 표시가 나타나고, 키를 놓으면 정리된 텍스트가
포커스된 앱에 삽입됩니다. 언제든 윈도우를 열면 **홈 대시보드**에서 말하는
속도, 누적 통계, 활동 히트맵, 어디서 받아쓰기했는지 볼 수 있습니다. 키,
언어, 엔진, 정리 방식은 **설정**에서 변경합니다.

## 엔진

모든 것이 온디바이스에서 실행됩니다. Apple 모델은 macOS에 내장되어 있고
기본으로 선택됩니다. 사이드바의 **모델** 페이지에서 다른 로컬 엔진을
다운로드해 전환할 수 있습니다(한 번에 하나만 활성화됩니다).

| 단계 | 기본(내장) | 선택적 대안(온디바이스) |
| --- | --- | --- |
| **음성 인식** | Apple `Speech` | **Parakeet TDT 0.6B V3** (NVIDIA, [FluidAudio](https://github.com/FluidInference/FluidAudio) 사용) · **Whisper Base** (OpenAI, [WhisperKit](https://github.com/argmaxinc/WhisperKit) 사용) — 필요 시 다운로드 |
| **정리** | 내장 규칙(즉시, 결정론적) | Apple Intelligence(`FoundationModels`, macOS 26+) — macOS 내장, 다운로드 불필요 |

다운로드형 모델은 필요할 때 한 번만 받아 오며(추론 시점에는 클라우드가 전혀
없습니다 — 오디오는 여전히 Mac을 떠나지 않습니다) Apple Neural Engine에서
CoreML로 실행됩니다. 선택한 엔진을 실행할 수 없으면 VoiceType이 자동으로
사용 가능한 엔진으로 대체하며, 실패하는 대신 항상 원본 텍스트로 우아하게
동작을 이어 갑니다.

> Parakeet 음성 모델은 © NVIDIA이며
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) 라이선스입니다.
> FluidAudio는 Apache-2.0입니다. Whisper는 OpenAI(MIT), WhisperKit은 MIT입니다.

<a name="languages"></a>
## 언어

VoiceType은 처음부터 끝까지 다국어입니다. 영어 앱에 자막만 붙인 것이 아닙니다:

- **30개 이상의 언어로 받아쓰기** — English, 中文, Español, Français,
  Deutsch, 日本語, 한국어, Português, Русский, Tiếng Việt 등. 언어는
  사용자가 직접 선택하며, VoiceType은 절대 추측하지 않습니다.
- **엔진이 언어에 맞게 매칭됩니다.** 각 음성 모델은 지원 언어를 선언합니다
  (Parakeet은 유럽 언어 전용, Nemotron은 중국어를 포함한 40개 로케일,
  Whisper는 폭넓은 다국어 지원, Apple의 목록은 macOS에서 가져옵니다).
  사용 언어를 처리할 수 없는 모델은 흐리게 표시되고, VoiceType은 지원 가능한
  엔진으로 전환합니다.
- **정리 기능이 언어를 압니다.** 각 언어에는 작고 검토 가능한 "언어 팩"이
  포함됩니다: 군말(嗯/呃, ähm, euh — 의미를 담은 단어는 절대 아님), 문장
  부호 관습(중국어·일본어의 전각 。，？, 말로 한 句号/読点을 부호로 변환),
  그리고 의문문 판별 휴리스틱입니다.
- **앱 자체도 현지화되어** 16개 언어로 제공되며, macOS 시스템 언어를
  따릅니다(시스템 설정의 앱별 언어 재정의도 지원합니다).

사용하는 언어가 없거나 번역이 어색한가요? 언어 추가는 의도적으로 작게
설계되어 있습니다 — UI 번역에는 Swift 코드가 전혀 필요 없습니다.
[docs/LOCALIZATION.md](../LOCALIZATION.md)를 참고하세요.

<a name="privacy"></a>
## 개인정보 보호

오디오와 받아쓰기 기록은 Mac에만 남습니다. 그것이 전부입니다 — 클라우드 경로
자체가 없습니다. 어떤 것도 기기 밖으로 기록되지 않으며, 오디오는 디스크에
저장되지 않습니다. 친근한 사용 요약조차 집계된 수치로만 만들어질 뿐, 받아쓴
텍스트는 절대 사용하지 않습니다. 이것은 나중에 바꿀 수도 있는 설정이 아니라
프로젝트의 헌법적 불변 조건입니다.

## 소스에서 빌드하기

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## 기여하기

기여를 환영합니다. 개발 요구 사항, 개인정보 보호 기준, Pull Request 안내는
[기여 가이드](../../CONTRIBUTING.md)를 읽어 주세요.
VoiceType을 당신의 언어로 만들고 싶다면
[docs/LOCALIZATION.md](../LOCALIZATION.md)에 체크리스트가 있습니다 — UI
번역에는 Swift가 전혀 필요 없고, 새 언어의 받아쓰기 품질은 잘 문서화된 파일
하나로 해결됩니다.
모든 참여자는 [행동 강령](../../CODE_OF_CONDUCT.md)을 따라야 합니다.
취약점은 [보안 정책](../../SECURITY.md)의 비공개 신고 절차를 따라 주세요.

## 아키텍처

홈 대시보드를 갖춘 네이티브 **Swift 6 / SwiftUI** Dock 앱(macOS 14)입니다.
전역 눌러서 말하기 단축키 · AVAudioEngine 마이크 캡처 · 교체 가능한
온디바이스 음성 인식 · 교체 가능한 정리 엔진 · 붙여넣기/손쉬운 사용 기반
텍스트 삽입 · 떠 있는 녹음 HUD. 코어(`VoiceTypeKit`)는 순수하며 유닛
테스트가 되어 있고, 앱 타깃이 시스템 엔진과 UI를 담당합니다. 자세한 내용은
[`CLAUDE.md`](../../CLAUDE.md)에 있으며 `specs/`를 통해 발전합니다.

## 라이선스

[MIT](../../LICENSE) © 2026 Michael Li.

앱에 번들된 서드파티 구성 요소와 온디바이스 모델은 각자의 라이선스를
유지합니다 — [`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md)를
참고하세요(앱 번들 안에도 포함되어 있습니다).

## 이 저장소의 운영 방식

VoiceType은 에이전트가 일상 운영을 맡는(**아우터 루프**: 분류 → 리뷰 →
병합/에스컬레이션) 독립 제품 저장소이며, 사람은 `specs/`를 편집해 **감각**을
제공합니다. 로컬 개발 중에는 [`@aros/*`](../../../agent-repo-os) 프레임워크를
링크합니다. 운영 규칙은 [`CLAUDE.md`](../../CLAUDE.md)를 참고하세요.

## 저장소 구조

```
VoiceType/
├── CLAUDE.md          # 에이전트의 운영 규칙
├── Package.swift      # SwiftPM: VoiceTypeKit(코어) + VoiceType(앱)
├── Sources/
│   ├── VoiceTypeKit/  # 순수하고 테스트된 코어: 프로토콜, 파이프라인, 정리, 리졸버
│   └── VoiceType/     # 앱: 단축키, 오디오, 엔진, 텍스트 삽입, 대시보드 UI
├── Tests/             # VoiceTypeKit 유닛 테스트
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── specs/             # 사람의 영역 — 제품 방향(에이전트는 편집하지 않음)
└── README.md
```

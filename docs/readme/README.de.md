<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Sprich überall, in deiner Sprache — sauberer Text sofort, alles direkt auf dem Gerät.

Eine schnelle, private Open-Source-Diktier-App für macOS. Halte eine Taste
gedrückt, sprich — auf Deutsch, English, 中文, Español, 日本語 oder in über 30
weiteren Sprachen — und deine Worte landen als sauberer, korrekt interpunktierter
Text in der App, die du gerade benutzt. Dein Audio verlässt niemals deinen Mac —
alles läuft direkt auf dem Gerät.

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-26%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)
&nbsp;[![Languages](https://img.shields.io/badge/dictation-30%2B%20languages-F2743E)](#languages)
&nbsp;[![License](https://img.shields.io/badge/license-MIT-111111)](../../LICENSE)

[English](../../README.md) ·
[简体中文](./README.zh-Hans.md) ·
**Deutsch** ·
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

_Diese Übersetzung ist nach bestem Wissen erstellt; maßgeblich ist das englische
README. Korrekturen sind per PR willkommen — siehe
[Beitragsleitfaden](../../CONTRIBUTING.md)._

</div>

---

> **Leitstern:** Sprich überall, erhalte sofort sauberen Text — und dein Audio
> verlässt niemals deinen Mac.

## Warum VoiceType

- 🔒 **Privat von Grund auf.** Audio und Transkripte bleiben auf deinem Mac. Kein Account, keine Telemetrie, keine Cloud — es gibt nichts, das du abbestellen müsstest.
- ⚡ **Latenz ist das Feature.** Natives Swift mit Apples Sprachmodell direkt auf dem Gerät — die Zeit bis zum fertigen Text ist das, was wir optimieren.
- 🌍 **Spricht deine Sprache.** Diktiere in über 30 Sprachen — nicht nur auf Englisch. Die Textbereinigung kennt die Konventionen jeder Sprache (vollbreite 中文-Interpunktion, gesprochenes 句号, sprachspezifische Füllwörter), die App wählt eine Engine, die deine Sprache wirklich unterstützt, und die Oberfläche selbst gibt es in 16 Sprachen.
- 🎙️ **Push-to-Talk überall.** Ein globaler Kurzbefehl funktioniert in jeder App; der bereinigte Text wird genau dort eingefügt, wo dein Cursor steht.
- ✨ **Smarte Bereinigung.** Interpunktion, Groß-/Kleinschreibung und das Entfernen von Füllwörtern — ohne jemals deine Worte zu verändern.
- 📊 **Deine Stimme, visualisiert.** Ein ruhiges Home-Dashboard zeigt deine Wörter, dein Tempo und deine Tagesserien, mit einer vollständigen Aktivitäts-Heatmap und einer freundlichen, auf dem Gerät erzeugten Nutzungszusammenfassung — alles direkt auf deinem Mac berechnet.
- 🧩 **Austauschbare Engines.** Standardmäßig Apples integriertes Modell, mit einem optionalen On-Device-Upgrade — NVIDIA Parakeet — das du herunterladen und aktivieren kannst, eines nach dem anderen.

## Laden & installieren

1. **[⬇ VoiceType.dmg laden](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** aus dem neuesten Release.
2. Öffne das DMG und ziehe **VoiceType** in deinen **Programme**-Ordner. Die App
   ist **von Apple signiert und beglaubigt** und startet daher mit einem ganz
   normalen Doppelklick — kein Gatekeeper-Umweg nötig.
3. Erteile die drei Berechtigungen, nach denen VoiceType fragt — **Mikrofon**,
   **Spracherkennung** und **Bedienungshilfen** — und du bist startklar.

> Erfordert **macOS 26** oder neuer (Apple Silicon).

**Updates laufen automatisch.** VoiceType sucht im Hintergrund nach neuen
Versionen (und auf Wunsch über **Nach Updates suchen …**) und installiert sie
direkt an Ort und Stelle mit [Sparkle](https://sparkle-project.org) — jedes
Update ist kryptografisch signiert und wird verifiziert. Kein erneutes
Herunterladen nötig. _(Die automatische Aktualisierung funktioniert ab v0.1.1;
nur der allererste Build, v0.1.0, muss einmal von Hand ersetzt werden.)_

## So benutzt du es

Halte überall die **rechte Wahltaste (⌥)** gedrückt und fang an zu sprechen. Eine
milchglasartige Pille erscheint und zeigt eine Live-Wellenform, während zugehört
wird; lass die Taste los, und dein bereinigter Text wird in die aktive App
eingefügt. Öffne jederzeit das Fenster für dein **Home-Dashboard** — dein Tempo,
deine Gesamtwerte, die Aktivitäts-Heatmap und wo du diktierst. Taste, Sprache,
Engines und Bereinigung änderst du in den **Einstellungen**.

## Engines

Alles läuft direkt auf dem Gerät. Apples Modell ist in macOS integriert und
standardmäßig ausgewählt; weitere lokale Engines kannst du auf der Seite
**Modelle** in der Seitenleiste laden und zwischen ihnen wechseln (es ist immer
genau eine aktiv).

| Stufe | Standard (integriert) | Optionale Alternativen (auf dem Gerät) |
| --- | --- | --- |
| **Transkription** | Apple `SpeechTranscriber` | **Parakeet TDT 0.6B V3** (NVIDIA, über [FluidAudio](https://github.com/FluidInference/FluidAudio)) · **Whisper Base** (OpenAI, über [WhisperKit](https://github.com/argmaxinc/WhisperKit)) — Download bei Bedarf |
| **Bereinigung** | Integrierte Regeln (sofort, deterministisch) | Apple Intelligence (`FoundationModels`) — in macOS integriert, kein Download |

Ladbare Modelle werden einmalig bei Bedarf geholt (keine Cloud zur Laufzeit —
dein Audio verlässt den Mac weiterhin nie) und laufen als CoreML auf der Apple
Neural Engine. Kann deine Auswahl nicht laufen, weicht VoiceType automatisch auf
eine verfügbare Engine aus — und liefert im Zweifel lieber unbearbeiteten Text,
statt zu scheitern.

> Das Parakeet-Sprachmodell ist © NVIDIA, lizenziert unter
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio steht
> unter Apache-2.0. Whisper ist von OpenAI (MIT); WhisperKit ist MIT.

<a name="languages"></a>
## Sprachen

VoiceType ist durchgehend mehrsprachig — nicht Englisch mit Untertiteln:

- **Diktiere in über 30 Sprachen** — Deutsch, English, 中文, Español, Français,
  日本語, 한국어, Português, Русский, Tiếng Việt und mehr. Du wählst die
  Sprache; VoiceType rät niemals.
- **Engines werden zu deiner Sprache passend gewählt.** Jedes Sprachmodell gibt
  an, was es unterstützt (Parakeet ist rein europäisch; Nemotron deckt 40
  Locales ab, darunter Chinesisch; Whisper ist breit mehrsprachig; Apples Liste
  kommt von macOS). Modelle, die deine Sprache nicht beherrschen, werden
  ausgegraut, und VoiceType wechselt zu einem, das sie kann.
- **Die Bereinigung kennt die Sprache.** Jede Sprache bringt ein kleines,
  überprüfbares „Sprachpaket" mit: ihre Füllwörter (嗯/呃, ähm, euh — nie Wörter,
  die Bedeutung tragen), ihre Interpunktionskonventionen (vollbreite 。，？ für
  Chinesisch und Japanisch, gesprochene 句号/読点 als Satzzeichen gesetzt) und
  ihre Frage-Heuristiken.
- **Die App selbst ist lokalisiert** — in 16 Sprachen, entsprechend deiner
  macOS-Systemsprache (die App-spezifische Sprachwahl in den Systemeinstellungen
  funktioniert ebenfalls).

Fehlt deine Sprache, oder stimmt eine Übersetzung nicht? Eine Sprache
hinzuzufügen ist bewusst klein gehalten — eine UI-Übersetzung braucht gar kein
Swift — siehe [docs/LOCALIZATION.md](../LOCALIZATION.md).

<a name="privacy"></a>
## Datenschutz

Audio und Transkripte bleiben auf deinem Mac, Punkt — es gibt keinen Cloud-Pfad.
Nichts wird außerhalb des Geräts protokolliert, und Audio wird nie auf die
Festplatte geschrieben. Selbst die freundliche Nutzungszusammenfassung entsteht
ausschließlich aus aggregierten Zählwerten — niemals aus deinem Transkripttext.
Das ist eine konstitutionelle Invariante des Projekts, keine Einstellung, die wir
später ändern könnten.

## Aus dem Quellcode bauen

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## Mitwirken

Beiträge sind willkommen. Bitte lies den
[Beitragsleitfaden](../../CONTRIBUTING.md) zu Entwicklungsanforderungen,
Datenschutz-Erwartungen und Hinweisen für Pull Requests.
Du willst VoiceType in deiner Sprache? [docs/LOCALIZATION.md](../LOCALIZATION.md)
enthält die Checkliste — eine UI-Übersetzung braucht gar kein Swift, und die
Diktierqualität für eine neue Sprache ist eine einzige, gut dokumentierte Datei.
Von allen Beteiligten wird erwartet, dass sie den
[Verhaltenskodex](../../CODE_OF_CONDUCT.md) einhalten.
Für Sicherheitslücken folge bitte dem vertraulichen Meldeprozess in unserer
[Sicherheitsrichtlinie](../../SECURITY.md).

## Architektur

Native **Swift 6 / SwiftUI**-Dock-App (macOS 26) mit Home-Dashboard. Globaler
Push-to-Talk-Kurzbefehl · Mikrofonaufnahme über AVAudioEngine · austauschbare
On-Device-Transkription · austauschbare Bereinigung · Texteinfügung per
Einsetzen/Bedienungshilfen · ein schwebendes Aufnahme-HUD. Der Kern
(`VoiceTypeKit`) ist pur und unit-getestet; das App-Target enthält die
System-Engines und die UI. Details stehen in [`CLAUDE.md`](../../CLAUDE.md) und
entwickeln sich über `specs/` weiter.

## Lizenz

[MIT](../../LICENSE) © 2026 Michael Li.

Mit der App gebündelte Drittanbieter-Komponenten und On-Device-Modelle behalten
ihre eigenen Lizenzen — siehe
[`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md) (liegt auch im
App-Bundle bei).

## Wie dieses Repo betrieben wird

VoiceType ist ein eigenständiges Produkt-Repo, das im Alltag von einem Agenten
betrieben wird (die **äußere Schleife**: Triage → Review → Merge/Eskalation),
während ein Mensch den **Geschmack** beisteuert, indem er `specs/` bearbeitet.
Während der lokalen Entwicklung ist das [`@aros/*`](../../../agent-repo-os)-Framework
verlinkt. Die Betriebsregeln stehen in [`CLAUDE.md`](../../CLAUDE.md).

## Repo-Aufbau

```
VoiceType/
├── CLAUDE.md          # Betriebsregeln für den Agenten
├── Package.swift      # SwiftPM: VoiceTypeKit (Kern) + VoiceType (App)
├── Sources/
│   ├── VoiceTypeKit/  # purer, getesteter Kern: Protokolle, Pipeline, Bereinigung, Resolver
│   └── VoiceType/     # App: Hotkey, Audio, Engines, Texteinfügung, Dashboard-UI
├── Tests/             # Unit-Tests für VoiceTypeKit
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · Entitlements · AppIcon
├── specs/             # die Oberfläche des Menschen — Produktrichtung (der Agent bearbeitet sie nicht)
└── README.md
```

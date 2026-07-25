<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Diktieren in 33 Sprachen. Sauberer Text sofort. Vollständig auf dem Gerät.

Eine schnelle, private, quelloffene Sprachdiktier-App für macOS. Taste gedrückt
halten, sprechen — auf Deutsch, English, 中文, Español, 日本語, العربية, हिन्दी,
Tiếng Việt oder in 26 weiteren Sprachen — und deine Worte landen als sauberer,
interpunktierter Text in der App, die du gerade benutzt.

Mehrsprachig **von Anfang bis Ende**: Das Sprachmodell wird auf deine Sprache
abgestimmt, die Bereinigung kennt Zeichensetzung und Füllwörter deiner Sprache,
und die Oberfläche der App gibt es in 16 Sprachen. Alles davon läuft **auf dem
Gerät** — dein Audio verlässt deinen Mac nie, in keiner Sprache.

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

- 🌍 **Durchgängig mehrsprachig, nicht Englisch mit Untertiteln.** Diktiere in [33 Sprachen](../LANGUAGES.md). VoiceType wählt ein Sprachmodell, das deine Sprache wirklich beherrscht, bereinigt nach den Konventionen *dieser* Sprache — Vollbreiten-Zeichensetzung im 中文, gesprochenes 句号, sprachspezifische Füllwörter — und liefert seine eigene Oberfläche in 16 Sprachen.
- 🔒 **Privat in jeder Sprache.** Audio und Transkripte bleiben auf deinem Mac. Kein Konto, keine Telemetrie, keine Cloud — es gibt gar keinen Weg „schwierige Sprachen an einen Server schicken“, den man abschalten müsste.
- ⚡ **Latenz ist das Feature.** Natives Swift mit Sprachmodellen auf dem Gerät — wir optimieren die Zeit bis zum Text.
- 🎙️ **Push-to-Talk überall.** Ein globaler Kurzbefehl funktioniert in jeder App; der bereinigte Text wird genau dort eingefügt, wo dein Cursor steht.
- ✨ **Smarte Bereinigung.** Interpunktion, Groß-/Kleinschreibung und das Entfernen von Füllwörtern — ohne jemals deine Worte zu verändern.
- 📊 **Deine Stimme, visualisiert.** Ein ruhiges Home-Dashboard zeigt deine Wörter, dein Tempo und deine Tagesserien, mit einer vollständigen Aktivitäts-Heatmap und einer freundlichen, auf dem Gerät erzeugten Nutzungszusammenfassung — alles direkt auf deinem Mac berechnet.
- 🧩 **Austauschbare Engines.** Standardmäßig Apples eingebautes Modell, dazu optionale lokale Upgrades — NVIDIA Parakeet, NVIDIA Nemotron, OpenAI Whisper — die du herunterladen und zwischen denen du wechseln kannst (immer eines aktiv).

## Laden & installieren

1. **[⬇ VoiceType.dmg laden](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** aus dem neuesten Release.
2. Öffne das DMG und ziehe **VoiceType** in deinen **Programme**-Ordner. Die App
   ist **von Apple signiert und beglaubigt** und startet daher mit einem ganz
   normalen Doppelklick — kein Gatekeeper-Umweg nötig.
3. Erteile die drei Berechtigungen, nach denen VoiceType fragt — **Mikrofon**,
   **Spracherkennung** und **Bedienungshilfen** — und du bist startklar.

> Erfordert **macOS 14** oder neuer (Apple Silicon).

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

| Engine | Sprachen | Hinweise |
| --- | --- | --- |
| **Apple Speech** (Standard) | Je nach macOS | Eingebaut, kein Download. `SpeechTranscriber` ab macOS 26, `SFSpeechRecognizer` auf dem Gerät unter macOS 14–15 |
| **Parakeet TDT 0.6B V3** | **25** — nur europäisch | NVIDIA, via [FluidAudio](https://github.com/FluidInference/FluidAudio). Am schnellsten; kein CJK |
| **Nemotron 3.5 ASR 0.6B** | **40 Locales** inkl. CJK, Arabisch, Hindi | NVIDIA, via FluidAudio. Das mehrsprachige Arbeitspferd |
| **Whisper Base** | **99** | OpenAI, via [WhisperKit](https://github.com/argmaxinc/WhisperKit). Größte Abdeckung |

Für die Bereinigung sind die eingebauten Regeln (sofort, deterministisch) der
Standard; Apple Intelligence (`FoundationModels`, macOS 26+) ist ein optionales
Upgrade, das in macOS steckt und nichts zum Herunterladen braucht. Die vollständige
Sprach-Engine-Matrix steht in [**docs/LANGUAGES.md**](../LANGUAGES.md).

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

Die meisten Diktier-Apps werden für Englisch gebaut und danach übersetzt. VoiceType
behandelt jede Sprache als erstklassigen Fall — das ist uns am wichtigsten.

**33 Sprachen** zum Diktieren · **16** mit handgeschriebenen Bereinigungsregeln ·
**16** mit übersetzter Oberfläche · **0**, die die Cloud brauchen.

Arabisch · Bulgarisch · 简体中文 · Kroatisch · Tschechisch · Dänisch · Nederlands ·
English · Estnisch · Finnisch · Français · Deutsch · Griechisch · हिन्दी ·
Ungarisch · Italiano · 日本語 · 한국어 · Lettisch · Litauisch · Maltesisch · Norsk ·
Polski · Português · Rumänisch · Русский · Slowakisch · Slowenisch · Español ·
Svenska · Türkçe · Українська · Tiếng Việt

Was „mehrsprachig“ hier konkret bedeutet:

- **Du wählst die Sprache; VoiceType rät nie.** Automatische Erkennung produziert
  selbstbewussten Unsinn, wenn sie danebenliegt — deshalb gibt es sie nicht.
- **Engines passen zu deiner Sprache.** Jedes Sprachmodell deklariert, was es kann
  (Parakeet nur europäisch; Nemotron deckt 40 Locales inklusive Chinesisch ab;
  Whisper deckt 99 ab; Apples Liste kommt von macOS). Modelle, die deine Sprache
  nicht beherrschen, werden ausgegraut, und VoiceType wechselt zu einem, das es kann.
- **Die Bereinigung kennt die Sprache.** 16 Sprachen bringen ein kleines,
  nachprüfbares „Sprachpaket“ mit: ihre Füllwörter (嗯/呃, ähm, euh — nie Wörter mit
  Bedeutung), ihre Zeichensetzungskonventionen (Vollbreiten-。，？ für Chinesisch und
  Japanisch, gesprochenes 句号/読点 als Zeichen gesetzt) und ihre Frageheuristiken.
  Alle anderen bekommen eine originalgetreue Transkription mit neutraler Bereinigung.
- **Die Oberfläche ist lokalisiert** in 16 Sprachen und folgt der Systemsprache von
  macOS — unabhängig von deiner Diktiersprache: Eine japanische Oberfläche kann auf
  Portugiesisch diktieren.
- **Kuratiert, nicht aufgebläht.** Wir könnten morgen Whispers 99 Sprachen auflisten;
  wir bieten die an, in denen eine Engine wirklich gut ist — und ein Test erzwingt das.

📖 **[Vollständige Sprachmatrix, Qualitätsstufen und bekannte Lücken →](../LANGUAGES.md)**

Deine Sprache fehlt oder eine Übersetzung stimmt nicht? Eine Sprache hinzuzufügen ist
bewusst klein gehalten — eine Übersetzung der Oberfläche braucht überhaupt kein Swift —
siehe [docs/LOCALIZATION.md](../LOCALIZATION.md). Besonders die maschinell erstellten
Sprachpakete brauchen den Blick von Muttersprachlern.

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

Native **Swift 6 / SwiftUI**-Dock-App (macOS 14) mit Home-Dashboard. Globaler
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
├── docs/              # LANGUAGES.md (Abdeckungsmatrix) · LOCALIZATION.md · readme/
├── specs/             # die Oberfläche des Menschen — Produktrichtung (der Agent bearbeitet sie nicht)
└── README.md
```

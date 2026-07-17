<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Spreek waar je maar wilt, in jouw taal — direct schone tekst, volledig op je apparaat.

Een snelle, privacyvriendelijke, open-source spraakdicteerapp voor macOS. Houd een
toets ingedrukt, spreek — in het Engels, 中文, Español, 日本語 of ruim 30 andere
talen — en je woorden verschijnen als schone tekst met leestekens in de app die
je op dat moment gebruikt. Je audio verlaat je Mac nooit — alles draait op je
apparaat.

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
[한국어](./README.ko.md) ·
**Nederlands** ·
[Polski](./README.pl.md) ·
[Português](./README.pt-BR.md) ·
[Русский](./README.ru.md) ·
[Svenska](./README.sv.md) ·
[Türkçe](./README.tr.md) ·
[Українська](./README.uk.md) ·
[Tiếng Việt](./README.vi.md)

_Deze vertaling is met zorg gemaakt, maar de [Engelse README](../../README.md) is leidend. Verbeteringen zijn welkom via een [pull request](../../CONTRIBUTING.md)._

</div>

---

> **Leidraad:** Spreek waar je maar wilt, krijg direct schone tekst, en je audio
> verlaat je Mac nooit.

## Waarom VoiceType

- 🔒 **Privé door ontwerp.** Audio en transcripties blijven op je Mac. Geen account, geen telemetrie, geen cloud — er valt niets om je voor af te melden.
- ⚡ **Lage latentie is dé feature.** Native Swift met Apple's spraakmodel op het apparaat — de tijd tot tekst is wat we optimaliseren.
- 🌍 **Spreekt jouw taal.** Dicteer in ruim 30 talen — niet alleen Engels. De opschoning begrijpt de conventies van elke taal (volledige-breedte 中文-leestekens, uitgesproken 句号, taalbewuste stopwoordjes), de app kiest een engine die jouw taal echt ondersteunt, en de interface zelf is beschikbaar in 16 talen.
- 🎙️ **Druk-en-spreek, overal.** Een globale sneltoets werkt in elke app; de opgeschoonde tekst wordt precies daar ingevoegd waar je cursor staat.
- ✨ **Slimme opschoning.** Leestekens, hoofdletters en het verwijderen van stopwoordjes — zonder ooit je woorden te veranderen.
- 📊 **Je stem, in beeld.** Een rustig Home-dashboard houdt je woorden, tempo en dagreeksen bij, met een volledige activiteitsheatmap en een vriendelijke gebruikssamenvatting op het apparaat — allemaal berekend op je Mac.
- 🧩 **Verwisselbare engines.** Standaard Apple's ingebouwde model, met een optionele upgrade op het apparaat — NVIDIA Parakeet — die je kunt downloaden en waarnaar je kunt wisselen, één tegelijk.

## Downloaden en installeren

1. **[⬇ Download VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** van de nieuwste release.
2. Open de DMG en sleep **VoiceType** naar je map **Apps**. De app is
   **ondertekend en genotariseerd door Apple**, dus hij start gewoon met een
   dubbelklik — geen Gatekeeper-omweg nodig.
3. Verleen de drie toestemmingen waar VoiceType om vraagt — **Microfoon**,
   **Spraakherkenning** en **Toegankelijkheid** — en je bent klaar.

> Vereist **macOS 14** of nieuwer (Apple Silicon).

**Updates gaan automatisch.** VoiceType controleert op de achtergrond op nieuwe
versies (en op verzoek via **Zoek naar updates…**) en installeert ze ter plekke
met [Sparkle](https://sparkle-project.org) — elke update is cryptografisch
ondertekend en geverifieerd. Opnieuw downloaden is niet nodig. _(Automatisch
updaten werkt vanaf v0.1.1; alleen de allereerste build, v0.1.0, moet je één keer
handmatig vervangen.)_

## Zo gebruik je het

Houd waar dan ook **rechter Option (⌥)** ingedrukt en begin te praten. Er
verschijnt een matglazen pil met een live golfvorm terwijl er wordt geluisterd;
laat de toets los en je opgeschoonde tekst wordt ingevoegd in de actieve app.
Open het venster wanneer je maar wilt om je **Home-dashboard** te zien — je
tempo, totalen, activiteitsheatmap en waar je dicteert. Pas de toets, taal,
engines en opschoning aan in **Instellingen**.

## Engines

Alles draait op je apparaat. Apple's model is ingebouwd in macOS en standaard
geselecteerd; je kunt andere lokale engines downloaden via de pagina **Models**
in de navigatiekolom en ertussen wisselen (er is er één tegelijk actief).

| Fase | Standaard (ingebouwd) | Optionele alternatieven (op het apparaat) |
| --- | --- | --- |
| **Transcriptie** | Apple `Speech` | **Parakeet TDT 0.6B V3** (NVIDIA, via [FluidAudio](https://github.com/FluidInference/FluidAudio)) · **Whisper Base** (OpenAI, via [WhisperKit](https://github.com/argmaxinc/WhisperKit)) — worden op verzoek gedownload |
| **Opschoning** | Ingebouwde regels (direct, deterministisch) | Apple Intelligence (`FoundationModels`, macOS 26+) — ingebouwd in macOS, geen download |

Downloadbare modellen worden eenmalig op verzoek opgehaald (geen cloud tijdens
inferentie — je audio verlaat de Mac nog steeds nooit) en draaien als CoreML op
de Apple Neural Engine. VoiceType valt automatisch terug op een beschikbare
engine als jouw keuze niet kan draaien, en levert altijd liever platte tekst dan
te falen.

> Het Parakeet-spraakmodel is © NVIDIA, gelicentieerd onder
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio is
> Apache-2.0. Whisper is van OpenAI (MIT); WhisperKit is MIT.

<a name="languages"></a>
## Talen

VoiceType is van begin tot eind meertalig, geen Engels-met-ondertitels:

- **Dicteer in ruim 30 talen** — Engels, 中文, Español, Français, Deutsch,
  日本語, 한국어, Português, Русский, Tiếng Việt en meer. Jij kiest de taal;
  VoiceType gokt nooit.
- **Engines worden afgestemd op jouw taal.** Elk spraakmodel geeft aan wat het
  ondersteunt (Parakeet is alleen Europees; Nemotron dekt 40 landinstellingen,
  waaronder Chinees; Whisper is breed meertalig; Apple's lijst komt uit macOS).
  Modellen die jouw taal niet aankunnen worden grijs weergegeven, en VoiceType
  schakelt over naar een model dat het wél kan.
- **De opschoning kent de taal.** Elke taal heeft een klein, controleerbaar
  "taalpakket": de stopwoordjes (嗯/呃, ähm, euh — nooit woorden die betekenis
  dragen), de leestekenconventies (volledige-breedte 。，？ voor Chinees en
  Japans, uitgesproken 句号/読点 omgezet naar leestekens) en de
  vraagheuristieken.
- **De app zelf is gelokaliseerd** in 16 talen en volgt je macOS-systeemtaal
  (een taalinstelling per app in Systeeminstellingen werkt ook).

Ontbreekt jouw taal, of klopt een vertaling niet? Een taal toevoegen is bewust
klein gehouden — voor een UI-vertaling is helemaal geen Swift nodig — zie
[docs/LOCALIZATION.md](../LOCALIZATION.md).

<a name="privacy"></a>
## Privacy

Audio en transcripties blijven op je Mac, punt — er is geen cloudroute. Er wordt
niets buiten het apparaat gelogd, en audio wordt nooit naar schijf geschreven.
Zelfs de vriendelijke gebruikssamenvatting wordt alleen opgebouwd uit
geaggregeerde tellingen — nooit uit de tekst van je transcripties. Dit is een
grondbeginsel van het project, geen instelling die we later misschien veranderen.

## Bouwen vanaf de broncode

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## Bijdragen

Bijdragen zijn welkom. Lees de [bijdragegids](../../CONTRIBUTING.md) voor
ontwikkelvereisten, privacyverwachtingen en richtlijnen voor pull requests.
Wil je VoiceType in jouw taal? [docs/LOCALIZATION.md](../LOCALIZATION.md) bevat
de checklist — voor een UI-vertaling is helemaal geen Swift nodig, en de
dicteerkwaliteit voor een nieuwe taal is één goed gedocumenteerd bestand.
Van alle deelnemers wordt verwacht dat ze de
[gedragscode](../../CODE_OF_CONDUCT.md) volgen. Volg voor kwetsbaarheden het
vertrouwelijke meldproces in ons [beveiligingsbeleid](../../SECURITY.md).

## Architectuur

Native **Swift 6 / SwiftUI** Dock-app (macOS 14) met een Home-dashboard. Globale
druk-en-spreek-sneltoets · microfoonopname via AVAudioEngine · verwisselbare
transcriptie op het apparaat · verwisselbare opschoning · tekstinvoeging via
plakken/Toegankelijkheid · een zwevende opname-HUD. De kern (`VoiceTypeKit`) is
puur en van unittests voorzien; het app-target bevat de systeemengines en de UI.
Details staan in [`CLAUDE.md`](../../CLAUDE.md) en evolueren via `specs/`.

## Licentie

[MIT](../../LICENSE) © 2026 Michael Li.

Componenten van derden en modellen op het apparaat die met de app worden
meegeleverd, behouden hun eigen licenties — zie
[`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md) (ook meegeleverd in de
app-bundel).

## Hoe deze repo wordt gerund

VoiceType is een op zichzelf staande productrepo die dagelijks wordt gerund door
een agent (de **buitenste lus**: triage → review → mergen/escaleren), waarbij een
mens de **smaak** aanlevert door `specs/` te bewerken. Tijdens lokale ontwikkeling
wordt het [`@aros/*`](../../../agent-repo-os)-framework gekoppeld. Zie
[`CLAUDE.md`](../../CLAUDE.md) voor de spelregels.

## Repo-indeling

```
VoiceType/
├── CLAUDE.md          # spelregels voor de agent
├── Package.swift      # SwiftPM: VoiceTypeKit (kern) + VoiceType (app)
├── Sources/
│   ├── VoiceTypeKit/  # pure, geteste kern: protocollen, pipeline, opschoning, resolver
│   └── VoiceType/     # app: sneltoets, audio, engines, invoeging, dashboard-UI
├── Tests/             # unittests voor VoiceTypeKit
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── specs/             # het domein van de mens — productrichting (agent bewerkt dit niet)
└── README.md
```

<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Tala var som helst, på ditt språk — ren text direkt, allt på enheten.

En snabb, privat röstdikteringsapp med öppen källkod för macOS. Håll ned en
tangent, tala — på svenska, English, 中文, Español, 日本語 eller 30+ andra språk —
och dina ord landar som ren, interpunkterad text i vilken app du än använder.
Ditt ljud lämnar aldrig din Mac — allt körs på enheten.

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
[Nederlands](./README.nl.md) ·
[Polski](./README.pl.md) ·
[Português](./README.pt-BR.md) ·
[Русский](./README.ru.md) ·
**Svenska** ·
[Türkçe](./README.tr.md) ·
[Українська](./README.uk.md) ·
[Tiếng Việt](./README.vi.md)

_Den här översättningen underhålls efter bästa förmåga — den engelska README-filen
är den auktoritativa versionen. Rättelser tas tacksamt emot via pull request, se
[bidragsguiden](../../CONTRIBUTING.md)._

</div>

---

> **Ledstjärna:** Tala var som helst, få ren text direkt, och ditt ljud lämnar
> aldrig din Mac.

## Varför VoiceType

- 🔒 **Privat i grunden.** Ljud och transkript stannar på din Mac. Inget konto, ingen telemetri, inget moln — det finns inget att tacka nej till.
- ⚡ **Låg latens är själva funktionen.** Native Swift med Apples talmodell på enheten — tid till text är det vi optimerar.
- 🌍 **Talar ditt språk.** Diktera på 30+ språk — inte bara engelska. Uppstädningen förstår varje språks konventioner (fullbreddsinterpunktion för 中文, uttalade 句号, språkmedvetna utfyllnadsord), appen väljer en motor som faktiskt stöder ditt språk, och själva gränssnittet levereras på 16 språk.
- 🎙️ **Tryck och tala var som helst.** Ett globalt kortkommando fungerar i alla appar; den uppstädade texten infogas precis där markören står.
- ✨ **Smart uppstädning.** Interpunktion, versalisering och borttagning av utfyllnadsord — utan att någonsin ändra dina ord.
- 📊 **Din röst, visualiserad.** En lugn hempanel följer dina ord, ditt tempo och dina dagssviter, med en fullständig aktivitetskarta och en vänlig användningssammanfattning på enheten — allt beräknat på din Mac.
- 🧩 **Utbytbara motorer.** Apples inbyggda modell som standard, med en valfri uppgradering på enheten — NVIDIA Parakeet — som du kan hämta och byta till, en i taget.

## Hämta och installera

1. **[⬇ Hämta VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** från den senaste utgåvan.
2. Öppna DMG-filen och dra **VoiceType** till mappen **Program**. Appen är
   **signerad och notariserad av Apple**, så den startar med ett vanligt
   dubbelklick — ingen Gatekeeper-omväg behövs.
3. Ge de tre behörigheter som VoiceType ber om — **Mikrofon**,
   **Taligenkänning** och **Hjälpmedel** — så är du klar.

> Kräver **macOS 14** eller senare (Apple Silicon).

**Uppdateringar sker automatiskt.** VoiceType letar efter nya versioner i
bakgrunden (och på begäran via **Sök efter uppdateringar…**) och installerar dem
på plats med [Sparkle](https://sparkle-project.org) — varje uppdatering är
kryptografiskt signerad och verifierad. Ingen ny hämtning behövs. _(Automatisk
uppdatering fungerar från v0.1.1 och framåt; den allra första versionen, v0.1.0,
måste bytas ut för hand en gång.)_

## Så använder du den

Håll ned **höger alternativtangent (⌥)** var som helst och börja tala. En frostad
kapsel visas med en ljudvåg i realtid medan den lyssnar; släpp tangenten och din
uppstädade text infogas i appen som har fokus. Öppna fönstret när som helst för
att se din **hempanel** — ditt tempo, dina totaler, aktivitetskartan och var du
dikterar. Byt tangent, språk, motorer och uppstädning i **Inställningar**.

## Motorer

Allt körs på enheten. Apples modell är inbyggd i macOS och vald som standard; du
kan hämta andra lokala motorer från sidan **Modeller** i sidofältet och växla
mellan dem (en är aktiv åt gången).

| Steg | Standard (inbyggd) | Valfria alternativ (på enheten) |
| --- | --- | --- |
| **Transkribering** | Apple `Speech` | **Parakeet TDT 0.6B V3** (NVIDIA, via [FluidAudio](https://github.com/FluidInference/FluidAudio)) · **Whisper Base** (OpenAI, via [WhisperKit](https://github.com/argmaxinc/WhisperKit)) — hämtas vid behov |
| **Uppstädning** | Inbyggda regler (omedelbara, deterministiska) | Apple Intelligence (`FoundationModels`, macOS 26+) — inbyggd i macOS, ingen hämtning |

Hämtningsbara modeller laddas ned en gång vid behov (inget moln vid inferens —
ditt ljud lämnar fortfarande aldrig din Mac) och körs som CoreML på Apple Neural
Engine. VoiceType faller automatiskt tillbaka på en tillgänglig motor om ditt
val inte kan köras, och degraderar alltid till oformaterad text i stället för
att misslyckas.

> Talmodellen Parakeet är © NVIDIA, licensierad under
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio är
> Apache-2.0. Whisper är OpenAI (MIT); WhisperKit är MIT.

<a name="languages"></a>
## Språk

VoiceType är flerspråkigt från början till slut, inte engelska-med-undertexter:

- **Diktera på 30+ språk** — English, 中文, Español, Français, Deutsch,
  日本語, 한국어, Português, Русский, Tiếng Việt med flera. Du väljer språket;
  VoiceType gissar aldrig.
- **Motorer matchas mot ditt språk.** Varje talmodell deklarerar vad den stöder
  (Parakeet är enbart europeisk; Nemotron täcker 40 språkversioner inklusive
  kinesiska; Whisper är brett flerspråkig; Apples lista kommer från macOS).
  Modeller som inte klarar ditt språk tonas ned, och VoiceType växlar till en
  som kan.
- **Uppstädningen kan språket.** Varje språk levereras med ett litet,
  granskningsbart "språkpaket": dess utfyllnadsord (嗯/呃, ähm, euh — aldrig
  ord som bär betydelse), dess interpunktionskonventioner (fullbredds 。，？
  för kinesiska och japanska, uttalade 句号/読点 som återges som skiljetecken)
  och dess frågeheuristik.
- **Själva appen är lokaliserad** till 16 språk och följer ditt systemspråk i
  macOS (åsidosättning per app i Systeminställningar fungerar också).

Saknas ditt språk, eller haltar en översättning? Att lägga till ett språk är
medvetet litet — en gränssnittsöversättning kräver ingen Swift alls — se
[docs/LOCALIZATION.md](../LOCALIZATION.md).

<a name="privacy"></a>
## Integritet

Ljud och transkript stannar på din Mac, punkt slut — det finns ingen molnväg.
Ingenting loggas utanför enheten, och ljud skrivs aldrig till disk. Till och med
den vänliga användningssammanfattningen byggs enbart av aggregerade räkningar —
aldrig din transkripttext. Det här är en konstitutionell invariant i projektet,
inte en inställning vi kanske ändrar senare.

## Bygg från källkod

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## Bidra

Bidrag är välkomna. Läs [bidragsguiden](../../CONTRIBUTING.md) för
utvecklingskrav, integritetsförväntningar och vägledning kring pull requests.
Vill du ha VoiceType på ditt språk? [docs/LOCALIZATION.md](../LOCALIZATION.md)
har checklistan — en gränssnittsöversättning kräver ingen Swift alls, och
dikteringskvalitet för ett nytt språk är en väldokumenterad fil.
Alla deltagare förväntas följa [uppförandekoden](../../CODE_OF_CONDUCT.md).
För sårbarheter, följ den privata rapporteringsprocessen i vår
[säkerhetspolicy](../../SECURITY.md).

## Arkitektur

Native **Swift 6 / SwiftUI**-app i Dock (macOS 14) med en hempanel. Globalt
tryck-och-tala-kortkommando · mikrofonupptagning med AVAudioEngine · utbytbar
transkribering på enheten · utbytbar uppstädning · textinfogning via
inklistring/Hjälpmedel · en svävande inspelnings-HUD. Kärnan (`VoiceTypeKit`) är
ren och enhetstestad; appmålet innehåller systemmotorerna och gränssnittet.
Detaljerna finns i [`CLAUDE.md`](../../CLAUDE.md) och utvecklas via `specs/`.

## Licens

[MIT](../../LICENSE) © 2026 Michael Li.

Tredjepartskomponenter och modeller på enheten som medföljer appen behåller sina
egna licenser — se [`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md)
(finns även inuti apppaketet).

## Så drivs det här repot

VoiceType är ett fristående produktrepo som sköts dagligen av en agent (den
**yttre loopen**: sortera → granska → slå ihop/eskalera), där en människa står
för **smaken** genom att redigera `specs/`. Det länkar ramverket
[`@aros/*`](../../../agent-repo-os) under lokal utveckling. Se
[`CLAUDE.md`](../../CLAUDE.md) för spelreglerna.

## Repostruktur

```
VoiceType/
├── CLAUDE.md          # spelregler för agenten
├── Package.swift      # SwiftPM: VoiceTypeKit (kärna) + VoiceType (app)
├── Sources/
│   ├── VoiceTypeKit/  # ren, testad kärna: protokoll, pipeline, uppstädning, resolver
│   └── VoiceType/     # app: kortkommando, ljud, motorer, infogning, panelgränssnitt
├── Tests/             # enhetstester för VoiceTypeKit
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── specs/             # människans yta — produktriktning (agenten redigerar inte)
└── README.md
```

<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Mów gdziekolwiek, w swoim języku — czysty tekst natychmiast, w całości na urządzeniu.

Szybka, prywatna aplikacja open source do dyktowania głosowego na macOS.
Przytrzymaj klawisz, mów — po angielsku, 中文, Español, 日本語 lub w ponad 30
innych językach — a Twoje słowa trafią jako czysty, poprawnie interpunkcyjny
tekst do dowolnej aplikacji, z której korzystasz. Twój dźwięk nigdy nie opuszcza
Twojego Maca — wszystko działa na urządzeniu.

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-26%2B-111111?logo=apple)](https://www.apple.com/macos/)
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
**Polski** ·
[Português](./README.pt-BR.md) ·
[Русский](./README.ru.md) ·
[Svenska](./README.sv.md) ·
[Türkçe](./README.tr.md) ·
[Українська](./README.uk.md) ·
[Tiếng Việt](./README.vi.md)

_To tłumaczenie jest wykonane w miarę możliwości jak najlepiej; wersją wiążącą jest angielski README. Poprawki mile widziane — prześlij PR zgodnie z [przewodnikiem współtworzenia](../../CONTRIBUTING.md)._

</div>

---

> **Gwiazda przewodnia:** Mów gdziekolwiek, otrzymuj czysty tekst natychmiast,
> a Twój dźwięk nigdy nie opuszcza Twojego Maca.

## Dlaczego VoiceType

- 🔒 **Prywatność z założenia.** Dźwięk i transkrypcje pozostają na Twoim Macu. Bez konta, bez telemetrii, bez chmury — nie ma z czego rezygnować.
- ⚡ **Niskie opóźnienie to nasza funkcja.** Natywny Swift z działającym na urządzeniu modelem mowy Apple — optymalizujemy czas od głosu do tekstu.
- 🌍 **Mówi w Twoim języku.** Dyktuj w ponad 30 językach — nie tylko po angielsku. Czyszczenie tekstu rozumie konwencje każdego języka (pełnowymiarowa interpunkcja 中文, wypowiadane 句号, wypełniacze zależne od języka), aplikacja wybiera silnik, który naprawdę obsługuje Twój język, a sam interfejs jest dostępny w 16 językach.
- 🎙️ **Naciśnij i mów — wszędzie.** Globalny skrót klawiszowy działa w każdej aplikacji; oczyszczony tekst jest wstawiany dokładnie tam, gdzie znajduje się kursor.
- ✨ **Inteligentne czyszczenie.** Interpunkcja, wielkie litery i usuwanie wypełniaczy — bez zmieniania Twoich słów.
- 📊 **Twój głos w liczbach.** Spokojny pulpit Home śledzi Twoje słowa, tempo i serie dni, z pełną mapą cieplną aktywności i przyjaznym, tworzonym na urządzeniu podsumowaniem użycia — wszystko obliczane na Twoim Macu.
- 🧩 **Wymienne silniki.** Domyślnie wbudowany model Apple, z opcjonalnym ulepszeniem działającym na urządzeniu — NVIDIA Parakeet — które możesz pobrać i na które możesz się przełączyć, po jednym naraz.

## Pobieranie i instalacja

1. **[⬇ Pobierz VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** z najnowszego wydania.
2. Otwórz plik DMG i przeciągnij **VoiceType** do folderu **Aplikacje**.
   Aplikacja jest **podpisana i notaryzowana przez Apple**, więc uruchamia się
   zwykłym dwukrotnym kliknięciem — bez obchodzenia Gatekeepera.
3. Udziel trzech uprawnień, o które prosi VoiceType — **Mikrofon**,
   **Rozpoznawanie mowy** i **Dostępność** — i gotowe.

> Wymaga systemu **macOS 26** lub nowszego (Apple Silicon).

**Uaktualnienia są automatyczne.** VoiceType sprawdza dostępność nowych wersji w
tle (oraz na żądanie przez **Sprawdź uaktualnienia…**) i instaluje je w miejscu
za pomocą [Sparkle](https://sparkle-project.org) — każde uaktualnienie jest
kryptograficznie podpisane i weryfikowane. Nie trzeba pobierać ponownie.
_(Automatyczne uaktualnienia działają od wersji v0.1.1; pierwszą kompilację,
v0.1.0, trzeba raz wymienić ręcznie.)_

## Korzystanie

Przytrzymaj **prawy Option (⌥)** gdziekolwiek i zacznij mówić. Pojawi się
matowa pastylka z podglądem fali dźwiękowej na żywo podczas słuchania; puść
klawisz, a oczyszczony tekst zostanie wstawiony do aktywnej aplikacji. Otwórz
okno w dowolnym momencie, aby zobaczyć swój **pulpit Home** — tempo, sumy, mapę
cieplną aktywności i miejsca, w których dyktujesz. Klawisz, język, silniki i
czyszczenie zmienisz w **Ustawieniach**.

## Silniki

Wszystko działa na urządzeniu. Model Apple jest wbudowany w macOS i wybrany
domyślnie; inne lokalne silniki możesz pobrać na stronie **Models** na pasku
bocznym i przełączać się między nimi (aktywny jest jeden naraz).

| Etap | Domyślnie (wbudowane) | Opcjonalne alternatywy (na urządzeniu) |
| --- | --- | --- |
| **Transkrypcja** | Apple `SpeechTranscriber` | **Parakeet TDT 0.6B V3** (NVIDIA, przez [FluidAudio](https://github.com/FluidInference/FluidAudio)) · **Whisper Base** (OpenAI, przez [WhisperKit](https://github.com/argmaxinc/WhisperKit)) — pobierane na żądanie |
| **Czyszczenie** | Wbudowane reguły (natychmiastowe, deterministyczne) | Apple Intelligence (`FoundationModels`) — wbudowane w macOS, bez pobierania |

Pobierane modele są pobierane jednorazowo na żądanie (bez chmury w czasie
inferencji — Twój dźwięk nadal nigdy nie opuszcza Maca) i działają jako CoreML
na Apple Neural Engine. Jeśli wybrany silnik nie może działać, VoiceType
automatycznie przełącza się na dostępny, a zamiast zawodzić, zawsze wraca do
zwykłego tekstu.

> Model mowy Parakeet jest © NVIDIA, na licencji
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio jest na
> licencji Apache-2.0. Whisper należy do OpenAI (MIT); WhisperKit jest na
> licencji MIT.

<a name="languages"></a>
## Języki

VoiceType jest wielojęzyczny od początku do końca, a nie „angielski z
napisami”:

- **Dyktuj w ponad 30 językach** — English, 中文, Español, Français, Deutsch,
  日本語, 한국어, Português, Русский, Tiếng Việt i innych. Ty wybierasz język;
  VoiceType nigdy nie zgaduje.
- **Silniki są dopasowane do Twojego języka.** Każdy model mowy deklaruje, co
  obsługuje (Parakeet obsługuje tylko języki europejskie; Nemotron obejmuje 40
  ustawień regionalnych, w tym chiński; Whisper jest szeroko wielojęzyczny;
  lista Apple pochodzi z macOS). Modele, które nie radzą sobie z Twoim
  językiem, są wyszarzone, a VoiceType przełącza się na taki, który sobie
  poradzi.
- **Czyszczenie zna język.** Każdy język ma mały, łatwy do przejrzenia „pakiet
  językowy”: swoje wypełniacze (嗯/呃, ähm, euh — nigdy słowa niosące
  znaczenie), swoje konwencje interpunkcyjne (pełnowymiarowe 。，？ dla
  chińskiego i japońskiego, wypowiadane 句号/読点 zamieniane na znaki) oraz
  heurystyki pytań.
- **Sama aplikacja jest zlokalizowana** w 16 językach i podąża za językiem
  systemowym macOS (działa też nadpisanie dla pojedynczej aplikacji w
  Ustawieniach systemowych).

Brakuje Twojego języka albo tłumaczenie kuleje? Dodanie języka jest celowo
proste — tłumaczenie interfejsu nie wymaga ani linijki Swifta — zobacz
[docs/LOCALIZATION.md](../LOCALIZATION.md).

<a name="privacy"></a>
## Prywatność

Dźwięk i transkrypcje pozostają na Twoim Macu, kropka — nie ma żadnej ścieżki
do chmury. Nic nie jest rejestrowane poza urządzeniem, a dźwięk nigdy nie jest
zapisywany na dysku. Nawet przyjazne podsumowanie użycia powstaje wyłącznie ze
zbiorczych liczników — nigdy z treści Twoich transkrypcji. To konstytucyjny
niezmiennik projektu, a nie ustawienie, które moglibyśmy kiedyś zmienić.

## Kompilacja ze źródeł

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## Współtworzenie

Wkład jest mile widziany. Przeczytaj [przewodnik współtworzenia](../../CONTRIBUTING.md),
aby poznać wymagania deweloperskie, oczekiwania dotyczące prywatności i wskazówki
dotyczące pull requestów. Chcesz mieć VoiceType w swoim języku?
[docs/LOCALIZATION.md](../LOCALIZATION.md) zawiera listę kontrolną — tłumaczenie
interfejsu nie wymaga ani linijki Swifta, a jakość dyktowania dla nowego języka
to jeden dobrze udokumentowany plik. Wszystkich uczestników obowiązuje
[Kodeks postępowania](../../CODE_OF_CONDUCT.md). W sprawie luk w zabezpieczeniach
postępuj zgodnie z procesem poufnego zgłaszania opisanym w naszych
[Zasadach bezpieczeństwa](../../SECURITY.md).

## Architektura

Natywna aplikacja w Docku napisana w **Swift 6 / SwiftUI** (macOS 26) z pulpitem
Home. Globalny skrót push-to-talk · przechwytywanie mikrofonu przez AVAudioEngine ·
wymienna transkrypcja na urządzeniu · wymienne czyszczenie · wstawianie tekstu
przez wklejanie/Dostępność · pływający HUD nagrywania. Rdzeń (`VoiceTypeKit`)
jest czysty i objęty testami jednostkowymi; cel aplikacji zawiera silniki
systemowe i interfejs. Szczegóły znajdują się w [`CLAUDE.md`](../../CLAUDE.md)
i ewoluują poprzez `specs/`.

## Licencja

[MIT](../../LICENSE) © 2026 Michael Li.

Komponenty zewnętrzne i modele działające na urządzeniu dołączone do aplikacji
zachowują własne licencje — zobacz [`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md)
(dostarczane również wewnątrz pakietu aplikacji).

## Jak prowadzone jest to repozytorium

VoiceType to samodzielne repozytorium produktu prowadzone na co dzień przez
agenta (**pętla zewnętrzna**: selekcja → przegląd → scalenie/eskalacja), przy
czym człowiek dostarcza **gust**, edytując `specs/`. Podczas lokalnego rozwoju
łączy się z frameworkiem [`@aros/*`](../../../agent-repo-os). Zasady działania opisuje
[`CLAUDE.md`](../../CLAUDE.md).

## Układ repozytorium

```
VoiceType/
├── CLAUDE.md          # zasady działania dla agenta
├── Package.swift      # SwiftPM: VoiceTypeKit (rdzeń) + VoiceType (aplikacja)
├── Sources/
│   ├── VoiceTypeKit/  # czysty, testowany rdzeń: protokoły, potok, czyszczenie, resolver
│   └── VoiceType/     # aplikacja: skrót, dźwięk, silniki, wstawianie, interfejs pulpitu
├── Tests/             # testy jednostkowe VoiceTypeKit
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · uprawnienia (entitlements) · AppIcon
├── specs/             # powierzchnia człowieka — kierunek produktu (agent nie edytuje)
└── README.md
```

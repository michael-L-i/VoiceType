<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Dettatura in 33 lingue. Testo pulito all'istante. Tutto sul dispositivo.

Un'app di dettatura vocale per macOS veloce, privata e open source. Tieni premuto
un tasto, parla — in italiano, English, 中文, Español, 日本語, العربية, हिन्दी,
Tiếng Việt o in altre 26 lingue — e le tue parole arrivano come testo pulito e
punteggiato nell'app che stai usando.

Multilingue **dall'inizio alla fine**: il modello vocale viene abbinato alla tua
lingua, la ripulitura conosce la punteggiatura e gli intercalari della tua lingua e
l'interfaccia dell'app esiste in 16 lingue. Tutto gira **sul dispositivo**: il tuo
audio non lascia mai il Mac, in nessuna lingua.

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
**Italiano** ·
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

_Questa è una traduzione fatta al meglio; il README in inglese è la versione di riferimento. Correzioni benvenute tramite [PR](../../CONTRIBUTING.md)._

</div>

---

> **Stella polare:** Detta ovunque, ottieni testo pulito all'istante, e il tuo
> audio non lascia mai il Mac.

## Perché VoiceType

- 🌍 **Multilingue dall'inizio alla fine, non inglese sottotitolato.** Detta in [33 lingue](../LANGUAGES.md). VoiceType sceglie un modello vocale che supporta davvero la tua lingua, ripulisce seguendo le convenzioni di *quella* lingua — punteggiatura a tutta larghezza in 中文, 句号 pronunciato, intercalari specifici per lingua — e offre la propria interfaccia in 16 lingue.
- 🔒 **Privato in ogni lingua.** Audio e trascrizioni restano sul tuo Mac. Nessun account, nessuna telemetria, nessun cloud: non esiste nemmeno una via «mandiamo le lingue difficili a un server» da disattivare.
- ⚡ **La latenza è la funzionalità.** Swift nativo con modelli vocali sul dispositivo: ottimizziamo il tempo che serve per arrivare al testo.
- 🎙️ **Premi-e-parla ovunque.** Una scorciatoia globale funziona in qualsiasi app; il testo ripulito viene inserito esattamente dove si trova il cursore.
- ✨ **Pulizia intelligente.** Punteggiatura, maiuscole e rimozione degli intercalari — senza mai cambiare le tue parole.
- 📊 **La tua voce, visualizzata.** Una tranquilla dashboard Home tiene traccia di parole, ritmo e serie di giorni consecutivi, con una mappa termica completa dell'attività e un simpatico riepilogo d'uso on-device — tutto calcolato sul tuo Mac.
- 🧩 **Motori intercambiabili.** Il modello Apple integrato è quello predefinito, con upgrade locali opzionali — NVIDIA Parakeet, NVIDIA Nemotron, OpenAI Whisper — che puoi scaricare e alternare (uno attivo alla volta).

## Download e installazione

1. **[⬇ Scarica VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** dall'ultima release.
2. Apri il DMG e trascina **VoiceType** nella cartella **Applicazioni**. L'app è
   **firmata e autenticata da Apple**, quindi si avvia con un normale doppio
   clic — nessun workaround per Gatekeeper necessario.
3. Concedi le tre autorizzazioni richieste da VoiceType — **Microfono**,
   **Riconoscimento vocale** e **Accessibilità** — e sei a posto.

> Richiede **macOS 14** o versioni successive (Apple Silicon).

**Gli aggiornamenti sono automatici.** VoiceType controlla la presenza di nuove
versioni in background (e su richiesta tramite **Verifica aggiornamenti…**) e le
installa direttamente con [Sparkle](https://sparkle-project.org) — ogni
aggiornamento è firmato e verificato crittograficamente. Nessun bisogno di
riscaricare. _(L'aggiornamento automatico funziona dalla v0.1.1 in poi; la
primissima build, la v0.1.0, va sostituita una volta a mano.)_

## Come si usa

Tieni premuto **Opzione destra (⌥)** ovunque e inizia a parlare. Appare una
pillola smerigliata che mostra una forma d'onda dal vivo mentre ascolta; rilascia
il tasto e il tuo testo ripulito viene inserito nell'app in primo piano. Apri la
finestra in qualsiasi momento per vedere la tua **dashboard Home** — ritmo,
totali, mappa termica dell'attività e dove detti. Cambia tasto, lingua, motori e
pulizia nelle **Impostazioni**.

## Motori

Tutto viene eseguito sul dispositivo. Il modello di Apple è integrato in macOS e
selezionato come predefinito; puoi scaricare altri motori locali dalla pagina
**Modelli** nella barra laterale e passare dall'uno all'altro (uno solo è attivo
alla volta).

| Motore | Lingue | Note |
| --- | --- | --- |
| **Apple Speech** (predefinito) | Varia in base a macOS | Integrato, nessun download. `SpeechTranscriber` su macOS 26+, `SFSpeechRecognizer` sul dispositivo su macOS 14–15 |
| **Parakeet TDT 0.6B V3** | **25** — solo europee | NVIDIA, tramite [FluidAudio](https://github.com/FluidInference/FluidAudio). Il più veloce; niente CJK |
| **Nemotron 3.5 ASR 0.6B** | **40 impostazioni locali**, incl. CJK, arabo, hindi | NVIDIA, tramite FluidAudio. Il cavallo di battaglia multilingue |
| **Whisper Base** | **99** | OpenAI, tramite [WhisperKit](https://github.com/argmaxinc/WhisperKit). La copertura più ampia |

Per la ripulitura le regole integrate (istantanee, deterministiche) sono l'opzione
predefinita; Apple Intelligence (`FoundationModels`, macOS 26+) è un upgrade
facoltativo incluso in macOS, senza nulla da scaricare. Vedi
[**docs/LANGUAGES.md**](../LANGUAGES.md) per la matrice completa lingua/motore.

I modelli scaricabili vengono recuperati una sola volta su richiesta (nessun cloud
al momento dell'inferenza — il tuo audio continua a non lasciare mai il Mac) e
vengono eseguiti come CoreML sull'Apple Neural Engine. VoiceType ricorre
automaticamente a un motore disponibile se la tua scelta non può essere eseguita,
e degrada sempre a testo semplice invece di fallire.

> Il modello vocale Parakeet è © NVIDIA, con licenza
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio è
> Apache-2.0. Whisper è di OpenAI (MIT); WhisperKit è MIT.

<a name="languages"></a>
## Lingue

La maggior parte delle app di dettatura è costruita per l'inglese e tradotta dopo.
VoiceType tratta ogni lingua come un caso di prima classe: è la cosa che ci sta più
a cuore.

**33 lingue** per la dettatura · **16** con regole di ripulitura scritte a mano ·
**16** con interfaccia tradotta · **0** che richiedono il cloud.

Arabo · Bulgaro · 简体中文 · Croato · Ceco · Danese · Nederlands · English ·
Estone · Finlandese · Français · Deutsch · Greco · हिन्दी · Ungherese · Italiano ·
日本語 · 한국어 · Lettone · Lituano · Maltese · Norsk · Polski · Português · Rumeno ·
Русский · Slovacco · Sloveno · Español · Svenska · Türkçe · Українська ·
Tiếng Việt

Che cosa significa qui «multilingue», in concreto:

- **La lingua la scegli tu; VoiceType non tira mai a indovinare.** Il riconoscimento
  automatico produce sciocchezze convincenti quando sbaglia, quindi non è previsto.
- **I motori sono abbinati alla tua lingua.** Ogni modello vocale dichiara che cosa
  supporta (Parakeet è solo europeo; Nemotron copre 40 impostazioni locali incluso il
  cinese; Whisper ne copre 99; l'elenco di Apple arriva da macOS). I modelli che non
  gestiscono la tua lingua vengono disattivati e VoiceType passa a uno che la gestisce.
- **La ripulitura conosce la lingua.** 16 lingue includono un piccolo «pacchetto
  lingua» ispezionabile: i suoi intercalari (嗯/呃, ähm, euh — mai parole che portano
  significato), le sue convenzioni di punteggiatura (。，？ a tutta larghezza per
  cinese e giapponese, 句号/読点 pronunciati resi come segni) e le sue euristiche per
  le domande. Le altre ottengono una trascrizione fedele con ripulitura neutra.
- **L'interfaccia è localizzata** in 16 lingue e segue la lingua di sistema di macOS,
  indipendentemente dalla lingua di dettatura: un'interfaccia in giapponese può
  dettare in portoghese.
- **Selezionate, non gonfiate.** Potremmo elencare domani le 99 lingue di Whisper;
  offriamo quelle in cui un motore è davvero bravo, e un test lo garantisce.

📖 **[Matrice completa delle lingue, livelli di qualità e lacune note →](../LANGUAGES.md)**

Manca la tua lingua o una traduzione è imprecisa? Aggiungere una lingua è
volutamente semplice — una traduzione dell'interfaccia non richiede alcun Swift —
vedi [docs/LOCALIZATION.md](../LOCALIZATION.md). I pacchetti generati
automaticamente hanno particolarmente bisogno dell'occhio di madrelingua.

## Privacy

Audio e trascrizioni restano sul tuo Mac, punto — non esiste alcun percorso verso
il cloud. Nulla viene registrato fuori dal dispositivo, e l'audio non viene mai
scritto su disco. Perfino il simpatico riepilogo d'uso è costruito solo da
conteggi aggregati — mai dal testo delle tue trascrizioni. Questo è un principio
costituzionale del progetto, non un'impostazione che potremmo cambiare in futuro.

## Compilare dal codice sorgente

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## Contribuire

I contributi sono benvenuti. Leggi la [guida ai contributi](../../CONTRIBUTING.md)
per i requisiti di sviluppo, le aspettative sulla privacy e le indicazioni per le
pull request. Vuoi VoiceType nella tua lingua?
[docs/LOCALIZATION.md](../LOCALIZATION.md) contiene la checklist — una traduzione
dell'interfaccia non richiede alcuno Swift, e la qualità di dettatura per una
nuova lingua è un unico file ben documentato.
Tutti i partecipanti sono tenuti a rispettare il [Codice di condotta](../../CODE_OF_CONDUCT.md).
Per le vulnerabilità, segui la procedura di segnalazione privata nella nostra
[Politica di sicurezza](../../SECURITY.md).

## Architettura

App nativa **Swift 6 / SwiftUI** nel Dock (macOS 14) con una dashboard Home.
Scorciatoia globale premi-e-parla · acquisizione del microfono con AVAudioEngine ·
trascrizione on-device intercambiabile · pulizia intercambiabile · inserimento del
testo tramite incolla/Accessibilità · un HUD di registrazione fluttuante. Il core
(`VoiceTypeKit`) è puro e coperto da unit test; il target dell'app contiene i
motori di sistema e l'interfaccia. I dettagli sono in [`CLAUDE.md`](../../CLAUDE.md)
ed evolvono tramite `specs/`.

## Licenza

[MIT](../../LICENSE) © 2026 Michael Li.

I componenti di terze parti e i modelli on-device inclusi nell'app mantengono le
proprie licenze — vedi [`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md)
(incluso anche nel bundle dell'app).

## Come viene gestito questo repo

VoiceType è un repo di prodotto autonomo gestito quotidianamente da un agente (il
**ciclo esterno**: smistamento → revisione → merge/escalation), con un umano che
fornisce il **gusto** modificando `specs/`. Durante lo sviluppo locale collega il
framework [`@aros/*`](../../../agent-repo-os). Vedi [`CLAUDE.md`](../../CLAUDE.md) per le
regole operative.

## Struttura del repo

```
VoiceType/
├── CLAUDE.md          # regole operative per l'agente
├── Package.swift      # SwiftPM: VoiceTypeKit (core) + VoiceType (app)
├── Sources/
│   ├── VoiceTypeKit/  # core puro e testato: protocolli, pipeline, pulizia, resolver
│   └── VoiceType/     # app: scorciatoia, audio, motori, inserimento, UI della dashboard
├── Tests/             # unit test di VoiceTypeKit
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── docs/              # LANGUAGES.md (matrice di copertura) · LOCALIZATION.md · readme/
├── specs/             # la superficie dell'umano — direzione di prodotto (l'agente non la modifica)
└── README.md
```

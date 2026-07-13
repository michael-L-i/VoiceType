<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Detta ovunque, nella tua lingua — testo pulito all'istante, tutto sul dispositivo.

Un'app di dettatura vocale per macOS veloce, privata e open source. Tieni premuto
un tasto, parla — in English, 中文, Español, 日本語 o in oltre 30 altre lingue —
e le tue parole arrivano come testo pulito e punteggiato in qualsiasi app tu stia
usando. Il tuo audio non lascia mai il Mac — tutto viene eseguito sul dispositivo.

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

- 🔒 **Privato fin dalla progettazione.** Audio e trascrizioni restano sul tuo Mac. Nessun account, nessuna telemetria, nessun cloud — non c'è nulla da cui disattivarsi.
- ⚡ **La latenza è la funzionalità.** Swift nativo con il modello vocale on-device di Apple — il tempo dal parlato al testo è ciò che ottimizziamo.
- 🌍 **Parla la tua lingua.** Detta in oltre 30 lingue — non solo in inglese. La pulizia conosce le convenzioni di ogni lingua (punteggiatura 中文 a larghezza intera, 句号 pronunciato, intercalari specifici per lingua), l'app sceglie un motore che supporta davvero la tua lingua e l'interfaccia stessa è disponibile in 16 lingue.
- 🎙️ **Premi-e-parla ovunque.** Una scorciatoia globale funziona in qualsiasi app; il testo ripulito viene inserito esattamente dove si trova il cursore.
- ✨ **Pulizia intelligente.** Punteggiatura, maiuscole e rimozione degli intercalari — senza mai cambiare le tue parole.
- 📊 **La tua voce, visualizzata.** Una tranquilla dashboard Home tiene traccia di parole, ritmo e serie di giorni consecutivi, con una mappa termica completa dell'attività e un simpatico riepilogo d'uso on-device — tutto calcolato sul tuo Mac.
- 🧩 **Motori intercambiabili.** Il modello integrato di Apple come predefinito, con un upgrade on-device opzionale — NVIDIA Parakeet — che puoi scaricare e attivare, uno alla volta.

## Download e installazione

1. **[⬇ Scarica VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** dall'ultima release.
2. Apri il DMG e trascina **VoiceType** nella cartella **Applicazioni**. L'app è
   **firmata e autenticata da Apple**, quindi si avvia con un normale doppio
   clic — nessun workaround per Gatekeeper necessario.
3. Concedi le tre autorizzazioni richieste da VoiceType — **Microfono**,
   **Riconoscimento vocale** e **Accessibilità** — e sei a posto.

> Richiede **macOS 26** o versioni successive (Apple Silicon).

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

| Fase | Predefinito (integrato) | Alternative opzionali (on-device) |
| --- | --- | --- |
| **Trascrizione** | Apple `SpeechTranscriber` | **Parakeet TDT 0.6B V3** (NVIDIA, tramite [FluidAudio](https://github.com/FluidInference/FluidAudio)) · **Whisper Base** (OpenAI, tramite [WhisperKit](https://github.com/argmaxinc/WhisperKit)) — scaricati su richiesta |
| **Pulizia** | Regole integrate (istantanee, deterministiche) | Apple Intelligence (`FoundationModels`) — integrato in macOS, nessun download |

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

VoiceType è multilingue da un capo all'altro, non inglese-con-sottotitoli:

- **Detta in oltre 30 lingue** — English, 中文, Español, Français, Deutsch,
  日本語, 한국어, Português, Русский, Tiếng Việt e altre ancora. Sei tu a
  scegliere la lingua; VoiceType non tira mai a indovinare.
- **I motori sono abbinati alla tua lingua.** Ogni modello vocale dichiara cosa
  supporta (Parakeet è solo per lingue europee; Nemotron copre 40 impostazioni
  locali incluso il cinese; Whisper è ampiamente multilingue; l'elenco di Apple
  proviene da macOS). I modelli che non gestiscono la tua lingua vengono
  disabilitati, e VoiceType passa a uno che la supporta.
- **La pulizia conosce la lingua.** Ogni lingua include un piccolo "pacchetto
  lingua" facilmente revisionabile: i suoi intercalari (嗯/呃, ähm, euh — mai
  parole che portano significato), le sue convenzioni di punteggiatura (。，？
  a larghezza intera per cinese e giapponese, 句号/読点 pronunciati resi come
  segni) e le sue euristiche per le domande.
- **L'app stessa è localizzata** in 16 lingue, seguendo la lingua di sistema di
  macOS (funziona anche l'impostazione per singola app in Impostazioni di
  Sistema).

Manca la tua lingua, o una traduzione è imprecisa? Aggiungere una lingua è
volutamente semplice — una traduzione dell'interfaccia non richiede alcuno
Swift — vedi [docs/LOCALIZATION.md](../LOCALIZATION.md).

<a name="privacy"></a>
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

App nativa **Swift 6 / SwiftUI** nel Dock (macOS 26) con una dashboard Home.
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
├── specs/             # la superficie dell'umano — direzione di prodotto (l'agente non la modifica)
└── README.md
```

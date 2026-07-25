<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Ditado em 33 idiomas. Texto limpo na hora. Tudo no dispositivo.

Um app de ditado por voz para macOS rápido, privado e de código aberto. Segure uma
tecla, fale — em português, English, 中文, Español, 日本語, العربية, हिन्दी,
Tiếng Việt ou em outros 26 idiomas — e suas palavras chegam como texto limpo e
pontuado no app que você estiver usando.

Multilíngue **de ponta a ponta**: o modelo de fala é escolhido de acordo com seu
idioma, a limpeza conhece a pontuação e os vícios de linguagem do seu idioma, e a
própria interface do app existe em 16 idiomas. Tudo isso roda **no dispositivo** —
seu áudio nunca sai do seu Mac, em nenhum idioma.

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
[日本語](./README.ja.md) ·
[한국어](./README.ko.md) ·
[Nederlands](./README.nl.md) ·
[Polski](./README.pl.md) ·
**Português** ·
[Русский](./README.ru.md) ·
[Svenska](./README.sv.md) ·
[Türkçe](./README.tr.md) ·
[Українська](./README.uk.md) ·
[Tiếng Việt](./README.vi.md)

_Esta é uma tradução feita com o melhor esforço possível; o README em inglês é a versão oficial. Correções são bem-vindas via [PR](../../CONTRIBUTING.md)._

</div>

---

> **Estrela-guia:** fale em qualquer lugar e obtenha texto limpo na hora, com o
> seu áudio nunca saindo do seu Mac.

## Por que o VoiceType

- 🌍 **Multilíngue de ponta a ponta, não inglês legendado.** Dite em [33 idiomas](../LANGUAGES.md). O VoiceType escolhe um modelo de fala que realmente suporta seu idioma, limpa o texto segundo as convenções *desse* idioma — pontuação de largura completa em 中文, 句号 falado, vícios de linguagem específicos de cada idioma — e oferece a própria interface em 16 idiomas.
- 🔒 **Privado em todos os idiomas.** Áudio e transcrições ficam no seu Mac. Sem conta, sem telemetria, sem nuvem — não existe nem mesmo um caminho de «mandar os idiomas difíceis para um servidor» que você precisasse desativar.
- ⚡ **A latência é o recurso.** Swift nativo com modelos de fala no dispositivo — otimizamos o tempo até o texto.
- 🎙️ **Pressione para falar em qualquer lugar.** Um atalho de teclado global funciona em qualquer app; o texto limpo é inserido exatamente onde o cursor está.
- ✨ **Limpeza inteligente.** Pontuação, uso de maiúsculas e remoção de palavras de preenchimento — sem nunca alterar as suas palavras.
- 📊 **Sua voz, visualizada.** Um painel Início tranquilo acompanha suas palavras, seu ritmo e suas sequências de dias, com um mapa de calor de atividade completo e um resumo de uso amigável gerado no dispositivo — tudo calculado no seu Mac.
- 🧩 **Motores plugáveis.** O modelo integrado da Apple por padrão, com upgrades locais opcionais — NVIDIA Parakeet, NVIDIA Nemotron, OpenAI Whisper — que você pode baixar e alternar (um ativo por vez).

## Baixar e instalar

1. **[⬇ Baixe o VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** da versão mais recente.
2. Abra o DMG e arraste o **VoiceType** para a pasta **Aplicativos**. O app é
   **assinado e autenticado pela Apple**, então ele abre com um clique duplo
   normal — sem precisar contornar o Gatekeeper.
3. Conceda as três permissões que o VoiceType solicita — **Microfone**,
   **Reconhecimento de Fala** e **Acessibilidade** — e pronto.

> Requer **macOS 14** ou posterior (Apple Silicon).

**As atualizações são automáticas.** O VoiceType verifica novas versões em
segundo plano (e sob demanda via **Buscar Atualizações…**) e as instala no
próprio lugar com o [Sparkle](https://sparkle-project.org) — cada atualização é
assinada e verificada criptograficamente. Não é preciso baixar de novo. _(A
atualização automática funciona a partir da v0.1.1; a primeiríssima versão,
v0.1.0, precisa ser substituída uma vez manualmente.)_

## Como usar

Segure **Option Direita (⌥)** em qualquer lugar e comece a falar. Uma pílula
fosca aparece mostrando uma forma de onda ao vivo enquanto ele escuta; solte a
tecla e o seu texto já limpo é inserido no app em foco. Abra a janela a qualquer
momento para ver o seu **painel Início** — seu ritmo, totais, mapa de calor de
atividade e onde você dita. Altere a tecla, o idioma, os mecanismos e a limpeza
nos **Ajustes**.

## Mecanismos

Tudo roda no dispositivo. O modelo da Apple vem integrado ao macOS e é
selecionado por padrão; você pode baixar outros mecanismos locais na página
**Modelos** da barra lateral e alternar entre eles (um fica ativo por vez).

| Motor | Idiomas | Observações |
| --- | --- | --- |
| **Apple Speech** (padrão) | Varia conforme o macOS | Integrado, sem download. `SpeechTranscriber` no macOS 26+, `SFSpeechRecognizer` no dispositivo no macOS 14–15 |
| **Parakeet TDT 0.6B V3** | **25** — apenas europeus | NVIDIA, via [FluidAudio](https://github.com/FluidInference/FluidAudio). O mais rápido; sem CJK |
| **Nemotron 3.5 ASR 0.6B** | **40 locales**, incl. CJK, árabe e hindi | NVIDIA, via FluidAudio. O cavalo de batalha multilíngue |
| **Whisper Base** | **99** | OpenAI, via [WhisperKit](https://github.com/argmaxinc/WhisperKit). A cobertura mais ampla |

Para a limpeza, as regras integradas (instantâneas e determinísticas) são o padrão;
o Apple Intelligence (`FoundationModels`, macOS 26+) é um upgrade opcional embutido
no macOS, sem nada para baixar. Veja [**docs/LANGUAGES.md**](../LANGUAGES.md) para a
matriz completa de idiomas e motores.

Os modelos baixáveis são obtidos uma única vez, sob demanda (nada de nuvem na
hora da inferência — seu áudio continua nunca saindo do Mac), e rodam como
CoreML no Apple Neural Engine. O VoiceType recorre automaticamente a um
mecanismo disponível se a sua escolha não puder rodar, e sempre degrada para
texto simples em vez de falhar.

> O modelo de fala Parakeet é © NVIDIA, licenciado sob
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). O FluidAudio é
> Apache-2.0. O Whisper é da OpenAI (MIT); o WhisperKit é MIT.

<a name="languages"></a>
## Idiomas

A maioria dos apps de ditado é construída para o inglês e traduzida depois. O
VoiceType trata cada idioma como um caso de primeira classe — é o que mais nos
importa acertar.

**33 idiomas** para ditado · **16** com regras de limpeza escritas à mão ·
**16** com interface traduzida · **0** que precisem da nuvem.

Árabe · Búlgaro · 简体中文 · Croata · Tcheco · Dinamarquês · Nederlands · English ·
Estoniano · Finlandês · Français · Deutsch · Grego · हिन्दी · Húngaro · Italiano ·
日本語 · 한국어 · Letão · Lituano · Maltês · Norsk · Polski · Português · Romeno ·
Русский · Eslovaco · Esloveno · Español · Svenska · Türkçe · Українська ·
Tiếng Việt

O que «multilíngue» significa aqui, na prática:

- **Você escolhe o idioma; o VoiceType nunca adivinha.** A detecção automática produz
  bobagens convincentes quando erra, então não é oferecida.
- **Os motores são compatibilizados com seu idioma.** Cada modelo de fala declara o
  que suporta (Parakeet é só europeu; Nemotron cobre 40 locales incluindo chinês;
  Whisper cobre 99; a lista da Apple vem do macOS). Modelos que não dão conta do seu
  idioma ficam esmaecidos e o VoiceType troca por um que dá.
- **A limpeza conhece o idioma.** 16 idiomas trazem um «pacote de idioma» pequeno e
  revisável: seus vícios de linguagem (嗯/呃, ähm, euh — nunca palavras que carregam
  significado), suas convenções de pontuação (。，？ de largura completa para chinês e
  japonês; 句号/読点 falados convertidos em sinais) e suas heurísticas de pergunta. Os
  demais recebem transcrição fiel com limpeza neutra.
- **A interface é localizada** em 16 idiomas e segue o idioma do sistema do macOS —
  independente do idioma de ditado, então uma interface em japonês pode ditar em
  português.
- **Curados, não inflados.** Poderíamos listar amanhã os 99 idiomas do Whisper;
  oferecemos aqueles em que um motor é genuinamente bom, e um teste garante isso.

📖 **[Matriz completa de idiomas, níveis de qualidade e lacunas conhecidas →](../LANGUAGES.md)**

Seu idioma está faltando ou uma tradução ficou estranha? Adicionar um idioma é
propositalmente pequeno — traduzir a interface não exige nada de Swift — veja
[docs/LOCALIZATION.md](../LOCALIZATION.md). Os pacotes gerados por máquina precisam
especialmente do olhar de falantes nativos.

## Privacidade

Áudio e transcrições ficam no seu Mac, e ponto final — não existe caminho para a
nuvem. Nada é registrado fora do dispositivo, e o áudio nunca é gravado em
disco. Até o resumo de uso amigável é construído apenas a partir de contagens
agregadas — nunca do texto das suas transcrições. Isso é um invariante
constitucional do projeto, não um ajuste que poderíamos mudar depois.

## Compilar a partir do código-fonte

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## Como contribuir

Contribuições são bem-vindas. Leia o [guia de contribuição](../../CONTRIBUTING.md)
para conhecer os requisitos de desenvolvimento, as expectativas de privacidade e
as orientações para pull requests. Quer o VoiceType no seu idioma?
[docs/LOCALIZATION.md](../LOCALIZATION.md) tem a lista de verificação — uma
tradução da interface não exige nada de Swift, e a qualidade de ditado para um
novo idioma é um único arquivo bem documentado.
Espera-se que todos os participantes sigam o [Código de Conduta](../../CODE_OF_CONDUCT.md).
Para vulnerabilidades, siga o processo de comunicação privada da nossa
[Política de Segurança](../../SECURITY.md).

## Arquitetura

App de Dock nativo em **Swift 6 / SwiftUI** (macOS 14) com um painel Início.
Atalho global de pressionar-para-falar · captura de microfone com AVAudioEngine ·
transcrição plugável no dispositivo · limpeza plugável · injeção de texto via
colagem/Acessibilidade · um HUD de gravação flutuante. O núcleo (`VoiceTypeKit`)
é puro e coberto por testes unitários; o alvo do app contém os mecanismos de
sistema e a interface. Os detalhes estão em [`CLAUDE.md`](../../CLAUDE.md) e
evoluem via `specs/`.

## Licença

[MIT](../../LICENSE) © 2026 Michael Li.

Os componentes de terceiros e os modelos no dispositivo incluídos no app mantêm
suas próprias licenças — veja [`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md)
(também incluído dentro do pacote do app).

## Como este repositório é conduzido

O VoiceType é um repositório de produto independente conduzido no dia a dia por
um agente (o **loop externo**: triagem → revisão → merge/escalonamento), com um
humano fornecendo o **gosto** ao editar `specs/`. Ele usa o framework
[`@aros/*`](../../../agent-repo-os) via link durante o desenvolvimento local. Veja
[`CLAUDE.md`](../../CLAUDE.md) para as regras de operação.

## Estrutura do repositório

```
VoiceType/
├── CLAUDE.md          # regras de operação para o agente
├── Package.swift      # SwiftPM: VoiceTypeKit (núcleo) + VoiceType (app)
├── Sources/
│   ├── VoiceTypeKit/  # núcleo puro e testado: protocolos, pipeline, limpeza, resolver
│   └── VoiceType/     # app: atalho, áudio, mecanismos, injeção, interface do painel
├── Tests/             # testes unitários do VoiceTypeKit
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── docs/              # LANGUAGES.md (matriz de cobertura) · LOCALIZATION.md · readme/
├── specs/             # a superfície do humano — direção de produto (o agente não edita)
└── README.md
```

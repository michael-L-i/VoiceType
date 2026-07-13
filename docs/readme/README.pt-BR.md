<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Fale em qualquer lugar, no seu idioma — texto limpo na hora, tudo no dispositivo.

Um app de ditado por voz para macOS rápido, privado e de código aberto. Segure
uma tecla, fale — em English, 中文, Español, 日本語 ou mais de 30 outros idiomas —
e suas palavras aparecem como texto limpo e pontuado em qualquer app que você
estiver usando. Seu áudio nunca sai do seu Mac — tudo roda no dispositivo.

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

- 🔒 **Privado por concepção.** Áudio e transcrições ficam no seu Mac. Sem conta, sem telemetria, sem nuvem — não há nada de que você precise se descadastrar.
- ⚡ **Latência é o recurso.** Swift nativo com o modelo de fala no dispositivo da Apple — o tempo até o texto é o que otimizamos.
- 🌍 **Fala o seu idioma.** Dite em mais de 30 idiomas — não só em inglês. A limpeza entende as convenções de cada idioma (pontuação de largura total em 中文, 句号 falado, palavras de preenchimento por idioma), o app escolhe um mecanismo que realmente suporta o seu idioma, e a própria interface está disponível em 16 idiomas.
- 🎙️ **Pressione para falar em qualquer lugar.** Um atalho de teclado global funciona em qualquer app; o texto limpo é inserido exatamente onde o cursor está.
- ✨ **Limpeza inteligente.** Pontuação, uso de maiúsculas e remoção de palavras de preenchimento — sem nunca alterar as suas palavras.
- 📊 **Sua voz, visualizada.** Um painel Início tranquilo acompanha suas palavras, seu ritmo e suas sequências de dias, com um mapa de calor de atividade completo e um resumo de uso amigável gerado no dispositivo — tudo calculado no seu Mac.
- 🧩 **Mecanismos plugáveis.** O modelo integrado da Apple por padrão, com um upgrade opcional no dispositivo — NVIDIA Parakeet — que você pode baixar e ativar, um de cada vez.

## Baixar e instalar

1. **[⬇ Baixe o VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** da versão mais recente.
2. Abra o DMG e arraste o **VoiceType** para a pasta **Aplicativos**. O app é
   **assinado e autenticado pela Apple**, então ele abre com um clique duplo
   normal — sem precisar contornar o Gatekeeper.
3. Conceda as três permissões que o VoiceType solicita — **Microfone**,
   **Reconhecimento de Fala** e **Acessibilidade** — e pronto.

> Requer **macOS 26** ou posterior (Apple Silicon).

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

| Etapa | Padrão (integrado) | Alternativas opcionais (no dispositivo) |
| --- | --- | --- |
| **Transcrição** | Apple `SpeechTranscriber` | **Parakeet TDT 0.6B V3** (NVIDIA, via [FluidAudio](https://github.com/FluidInference/FluidAudio)) · **Whisper Base** (OpenAI, via [WhisperKit](https://github.com/argmaxinc/WhisperKit)) — baixados sob demanda |
| **Limpeza** | Regras integradas (instantâneas, determinísticas) | Apple Intelligence (`FoundationModels`) — integrado ao macOS, sem download |

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

O VoiceType é multilíngue de ponta a ponta, não "inglês com legendas":

- **Dite em mais de 30 idiomas** — English, 中文, Español, Français, Deutsch,
  日本語, 한국어, Português, Русский, Tiếng Việt e muito mais. Você escolhe o
  idioma; o VoiceType nunca adivinha.
- **Os mecanismos são combinados com o seu idioma.** Cada modelo de fala declara
  o que suporta (o Parakeet é só para idiomas europeus; o Nemotron cobre 40
  localidades, incluindo chinês; o Whisper é amplamente multilíngue; a lista da
  Apple vem do macOS). Modelos que não dão conta do seu idioma ficam esmaecidos,
  e o VoiceType muda para um que dê.
- **A limpeza conhece o idioma.** Cada idioma traz um pequeno "pacote de idioma"
  revisável: suas palavras de preenchimento (嗯/呃, ähm, euh — nunca palavras
  que carregam significado), suas convenções de pontuação (。，？ de largura
  total para chinês e japonês, 句号/読点 falados convertidos em sinais) e suas
  heurísticas de pergunta.
- **O próprio app é localizado** em 16 idiomas, seguindo o idioma do sistema no
  seu macOS (a opção por app nos Ajustes do Sistema também funciona).

Seu idioma está faltando, ou uma tradução ficou estranha? Adicionar um idioma é
deliberadamente simples — uma tradução da interface não exige nada de Swift —
veja [docs/LOCALIZATION.md](../LOCALIZATION.md).

<a name="privacy"></a>
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

App de Dock nativo em **Swift 6 / SwiftUI** (macOS 26) com um painel Início.
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
├── specs/             # a superfície do humano — direção de produto (o agente não edita)
└── README.md
```

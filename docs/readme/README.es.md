<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Dictado en 33 idiomas. Texto limpio al instante. Todo en el dispositivo.

Una app de dictado por voz para macOS rápida, privada y de código abierto. Mantén
pulsada una tecla, habla — en español, English, 中文, 日本語, العربية, हिन्दी,
Tiếng Việt o en otros 26 idiomas — y tus palabras aparecen como texto limpio y
puntuado en cualquier app que estés usando.

Multilingüe **de principio a fin**: el modelo de voz se ajusta a tu idioma, la
limpieza conoce la puntuación y las muletillas de tu idioma, y la propia interfaz
de la app está en 16 idiomas. Todo ello se ejecuta **en el dispositivo**: tu audio
nunca sale de tu Mac, en ningún idioma.

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
**Español** ·
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

_Esta traducción se mantiene con el mejor esfuerzo posible; el README en inglés es la versión de referencia. ¿Ves algo mejorable? Las correcciones son bienvenidas vía [PR](../../CONTRIBUTING.md)._

</div>

---

> **Estrella polar:** habla donde quieras y obtén texto limpio al instante, sin
> que tu audio salga nunca de tu Mac.

## Por qué VoiceType

- 🌍 **Multilingüe de principio a fin, no inglés con subtítulos.** Dicta en [33 idiomas](../LANGUAGES.md). VoiceType elige un modelo de voz que realmente admita tu idioma, limpia el texto siguiendo las convenciones de *ese* idioma —puntuación de ancho completo en 中文, 句号 dictado, muletillas propias de cada idioma— y ofrece su interfaz en 16 idiomas.
- 🔒 **Privado en todos los idiomas.** El audio y las transcripciones se quedan en tu Mac. Sin cuenta, sin telemetría, sin nube: ni siquiera existe una vía de «mandamos los idiomas difíciles a un servidor» que debas desactivar.
- ⚡ **La latencia es la función.** Swift nativo con modelos de voz en el dispositivo: optimizamos el tiempo hasta el texto.
- 🎙️ **Pulsar para hablar en cualquier parte.** Una función rápida de teclado global funciona en cualquier app; el texto limpio se inserta justo donde está tu cursor.
- ✨ **Limpieza inteligente.** Puntuación, mayúsculas y eliminación de muletillas — sin cambiar nunca tus palabras.
- 📊 **Tu voz, visualizada.** Un panel de inicio sereno registra tus palabras, tu ritmo y tus rachas diarias, con un mapa de calor de actividad completo y un resumen de uso amigable generado en el dispositivo — todo calculado en tu Mac.
- 🧩 **Motores intercambiables.** El modelo integrado de Apple por defecto, con mejoras locales opcionales —NVIDIA Parakeet, NVIDIA Nemotron, OpenAI Whisper— que puedes descargar y alternar (uno activo cada vez).

## Descarga e instalación

1. **[⬇ Descarga VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** desde la última versión.
2. Abre el DMG y arrastra **VoiceType** a tu carpeta **Aplicaciones**. La app
   está **firmada y notarizada por Apple**, así que se abre con un doble clic
   normal — sin trucos para saltarse Gatekeeper.
3. Concede los tres permisos que pide VoiceType — **Micrófono**,
   **Reconocimiento de voz** y **Accesibilidad** — y listo.

> Requiere **macOS 14** o posterior (Apple Silicon).

**Las actualizaciones son automáticas.** VoiceType busca versiones nuevas en
segundo plano (y bajo demanda con **Buscar actualizaciones…**) y las instala en
el mismo lugar con [Sparkle](https://sparkle-project.org) — cada actualización
está firmada y verificada criptográficamente. No hace falta volver a descargar
nada. _(La actualización automática funciona a partir de la v0.1.1; la primera
compilación, la v0.1.0, hay que reemplazarla una vez a mano.)_

## Cómo se usa

Mantén pulsada la tecla **Opción derecha (⌥)** en cualquier parte y empieza a
hablar. Aparece una pastilla esmerilada con una forma de onda en vivo mientras
escucha; suelta la tecla y tu texto ya limpio se inserta en la app activa. Abre
la ventana cuando quieras para ver tu **panel de inicio** — tu ritmo, tus
totales, el mapa de calor de actividad y dónde dictas. Cambia la tecla, el
idioma, los motores y la limpieza en **Ajustes**.

## Motores

Todo se ejecuta en el dispositivo. El modelo de Apple viene integrado en macOS
y está seleccionado por omisión; puedes descargar otros motores locales desde la
página **Modelos** de la barra lateral y alternar entre ellos (solo uno está
activo a la vez).

| Motor | Idiomas | Notas |
| --- | --- | --- |
| **Apple Speech** (por defecto) | Varía según macOS | Integrado, sin descarga. `SpeechTranscriber` en macOS 26+, `SFSpeechRecognizer` en el dispositivo en macOS 14–15 |
| **Parakeet TDT 0.6B V3** | **25** — solo europeos | NVIDIA, vía [FluidAudio](https://github.com/FluidInference/FluidAudio). El más rápido; sin CJK |
| **Nemotron 3.5 ASR 0.6B** | **40 configuraciones regionales**, incl. CJK, árabe e hindi | NVIDIA, vía FluidAudio. El caballo de batalla multilingüe |
| **Whisper Base** | **99** | OpenAI, vía [WhisperKit](https://github.com/argmaxinc/WhisperKit). La cobertura más amplia |

Para la limpieza, las reglas integradas (instantáneas y deterministas) son la opción
por defecto; Apple Intelligence (`FoundationModels`, macOS 26+) es una mejora opcional
integrada en macOS que no requiere descarga. Consulta
[**docs/LANGUAGES.md**](../LANGUAGES.md) para la matriz completa de idiomas y motores.

Los modelos descargables se obtienen una sola vez bajo demanda (sin nube en el
momento de la inferencia — tu audio sigue sin salir nunca del Mac) y se ejecutan
como CoreML en el Apple Neural Engine. VoiceType recurre automáticamente a un
motor disponible si tu elección no puede ejecutarse, y siempre degrada a texto
sin formato en lugar de fallar.

> El modelo de voz Parakeet es © NVIDIA, con licencia
> [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio es
> Apache-2.0. Whisper es de OpenAI (MIT); WhisperKit es MIT.

<a name="languages"></a>
## Idiomas

La mayoría de las apps de dictado se construyen para el inglés y se traducen después.
VoiceType trata cada idioma como un caso de primera clase: es lo que más nos importa
hacer bien.

**33 idiomas** para dictar · **16** con reglas de limpieza escritas a mano ·
**16** con interfaz traducida · **0** que necesiten la nube.

Árabe · Búlgaro · 简体中文 · Croata · Checo · Danés · Nederlands · English ·
Estonio · Finés · Français · Deutsch · Griego · हिन्दी · Húngaro · Italiano ·
日本語 · 한국어 · Letón · Lituano · Maltés · Norsk · Polski · Português · Rumano ·
Русский · Eslovaco · Esloveno · Español · Svenska · Türkçe · Українська ·
Tiếng Việt

Qué significa aquí «multilingüe», en concreto:

- **Tú eliges el idioma; VoiceType nunca adivina.** La detección automática produce
  disparates convincentes cuando se equivoca, así que no se ofrece.
- **Los motores se ajustan a tu idioma.** Cada modelo de voz declara lo que admite
  (Parakeet es solo europeo; Nemotron cubre 40 configuraciones regionales, incluido
  el chino; Whisper cubre 99; la lista de Apple viene de macOS). Los modelos que no
  pueden con tu idioma se atenúan y VoiceType cambia a uno que sí puede.
- **La limpieza conoce el idioma.** 16 idiomas incluyen un «paquete de idioma»
  pequeño y revisable: sus muletillas (嗯/呃, ähm, euh — nunca palabras con
  significado), sus convenciones de puntuación (。，？ de ancho completo para chino y
  japonés; 句号/読点 dictados convertidos en signos) y sus heurísticas de pregunta.
  El resto obtiene una transcripción fiel con limpieza neutra.
- **La interfaz está localizada** en 16 idiomas y sigue el idioma del sistema de
  macOS, con independencia del idioma de dictado: una interfaz en japonés puede
  dictar en portugués.
- **Seleccionados, no inflados.** Podríamos anunciar mañana los 99 idiomas de
  Whisper; ofrecemos aquellos en los que un motor es realmente bueno, y una prueba
  lo garantiza.

📖 **[Matriz completa de idiomas, niveles de calidad y carencias conocidas →](../LANGUAGES.md)**

¿Falta tu idioma o hay una traducción mejorable? Añadir un idioma es deliberadamente
pequeño —una traducción de la interfaz no necesita nada de Swift—: consulta
[docs/LOCALIZATION.md](../LOCALIZATION.md). Los paquetes generados automáticamente
necesitan especialmente la mirada de hablantes nativos.

## Privacidad

El audio y las transcripciones se quedan en tu Mac, y punto — no existe ninguna
ruta hacia la nube. No se registra nada fuera del dispositivo, y el audio nunca
se escribe en disco. Incluso el resumen de uso amigable se construye solo a
partir de recuentos agregados — nunca del texto de tus transcripciones. Es un
invariante constitucional del proyecto, no un ajuste que podríamos cambiar más
adelante.

## Compilar desde el código fuente

```bash
swift test              # run the VoiceTypeKit unit tests
./Scripts/build-app.sh  # build VoiceType.app (ad-hoc signed)
./Scripts/make-dmg.sh   # package a drag-to-install VoiceType.dmg
open VoiceType.app
```

## Contribuir

Las contribuciones son bienvenidas. Lee la [guía de contribución](../../CONTRIBUTING.md)
para conocer los requisitos de desarrollo, las expectativas de privacidad y las
pautas para pull requests. ¿Quieres VoiceType en tu idioma?
[docs/LOCALIZATION.md](../LOCALIZATION.md) tiene la lista de comprobación — una
traducción de la interfaz no necesita nada de Swift, y la calidad del dictado
para un idioma nuevo es un único archivo bien documentado.
Se espera que todos los participantes sigan el
[Código de Conducta](../../CODE_OF_CONDUCT.md).
Para vulnerabilidades, sigue el proceso de notificación privada de nuestra
[Política de Seguridad](../../SECURITY.md).

## Arquitectura

App nativa de Dock en **Swift 6 / SwiftUI** (macOS 14) con un panel de inicio.
Función rápida de teclado global de pulsar para hablar · captura de micrófono
con AVAudioEngine · transcripción intercambiable en el dispositivo · limpieza
intercambiable · inserción de texto por pegado/Accesibilidad · un HUD flotante
de grabación. El núcleo (`VoiceTypeKit`) es puro y tiene pruebas unitarias; el
target de la app contiene los motores del sistema y la interfaz. Los detalles
están en [`CLAUDE.md`](../../CLAUDE.md) y evolucionan vía `specs/`.

## Licencia

[MIT](../../LICENSE) © 2026 Michael Li.

Los componentes de terceros y los modelos en el dispositivo incluidos con la app
conservan sus propias licencias — consulta
[`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md) (también incluido
dentro del paquete de la app).

## Cómo se gestiona este repositorio

VoiceType es un repositorio de producto independiente gestionado día a día por
un agente (el **bucle exterior**: clasificar → revisar → fusionar/escalar), con
un humano que aporta el **criterio** editando `specs/`. Enlaza el framework
[`@aros/*`](../../../agent-repo-os) durante el desarrollo local. Consulta
[`CLAUDE.md`](../../CLAUDE.md) para las reglas de funcionamiento.

## Estructura del repositorio

```
VoiceType/
├── CLAUDE.md          # reglas de funcionamiento para el agente
├── Package.swift      # SwiftPM: VoiceTypeKit (núcleo) + VoiceType (app)
├── Sources/
│   ├── VoiceTypeKit/  # núcleo puro y probado: protocolos, pipeline, limpieza, resolver
│   └── VoiceType/     # app: tecla rápida, audio, motores, inserción, interfaz del panel
├── Tests/             # pruebas unitarias de VoiceTypeKit
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── docs/              # LANGUAGES.md (matriz de cobertura) · LOCALIZATION.md · readme/
├── specs/             # la superficie del humano — dirección del producto (el agente no la edita)
└── README.md
```

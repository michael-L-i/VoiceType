<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### La dictée en 33 langues. Un texte propre instantanément. Entièrement sur votre appareil.

Une application de dictée vocale pour macOS rapide, privée et open source. Maintenez
une touche enfoncée, parlez — en français, English, 中文, Español, 日本語, العربية,
हिन्दी, Tiếng Việt ou dans 26 autres langues — et vos mots arrivent sous forme de
texte propre et ponctué dans n'importe quelle application.

Multilingue **de bout en bout** : le modèle vocal est adapté à votre langue, le
nettoyage connaît la ponctuation et les hésitations propres à votre langue, et
l'interface de l'app existe en 16 langues. Tout cela s'exécute **sur l'appareil** —
votre audio ne quitte jamais votre Mac, quelle que soit la langue.

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
**Français** ·
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

_Cette traduction est maintenue au mieux ; le README anglais est la version de référence. Les corrections sont bienvenues par [pull request](../../CONTRIBUTING.md)._

</div>

---

> **Notre cap :** parlez partout, obtenez immédiatement un texte propre, sans que votre audio ne quitte votre Mac.

## Pourquoi VoiceType

- 🌍 **Multilingue de bout en bout, pas de l'anglais sous-titré.** Dictez dans [33 langues](../LANGUAGES.md). VoiceType choisit un modèle vocal qui prend réellement votre langue en charge, applique les conventions de *cette* langue — ponctuation pleine chasse en 中文, 句号 prononcé, hésitations propres à chaque langue — et son interface est disponible en 16 langues.
- 🔒 **Privé dans toutes les langues.** L'audio et les transcriptions restent sur votre Mac. Aucun compte, aucune télémétrie, aucun cloud : il n'existe même pas de voie « on envoie les langues difficiles sur un serveur » à désactiver.
- ⚡ **La latence est la fonctionnalité.** Swift natif et modèles vocaux sur l'appareil : nous optimisons le temps jusqu'au texte.
- 🎙️ **Appuyez pour parler partout.** Un raccourci global fonctionne dans toute app ; le texte nettoyé est inséré exactement là où se trouve le curseur.
- ✨ **Nettoyage intelligent.** Ponctuation, majuscules et suppression des hésitations, sans jamais modifier vos mots.
- 📊 **Votre voix en images.** Un tableau de bord Home apaisé suit vos mots, votre rythme et vos séries quotidiennes, avec une carte d'activité complète et un résumé d'utilisation calculé localement sur votre Mac.
- 🧩 **Moteurs interchangeables.** Le modèle Apple intégré est utilisé par défaut ; vous pouvez télécharger des améliorations locales optionnelles — NVIDIA Parakeet, NVIDIA Nemotron, OpenAI Whisper — et basculer entre elles, une à la fois.

## Télécharger et installer

1. **[⬇ Téléchargez VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** depuis la dernière version.
2. Ouvrez le DMG et faites glisser **VoiceType** dans votre dossier **Applications**. L'app est **signée et notariée par Apple** ; elle s'ouvre normalement par double-clic, sans contournement de Gatekeeper.
3. Accordez les trois autorisations demandées par VoiceType : **Microphone**, **Reconnaissance vocale** et **Accessibilité**. C'est prêt.

> Nécessite macOS 14 ou version ultérieure (Apple Silicon).

**Les mises à jour sont automatiques.** VoiceType vérifie les nouvelles versions en arrière-plan (et à la demande via **Rechercher les mises à jour…**) et les installe sur place avec [Sparkle](https://sparkle-project.org) ; chaque mise à jour est signée et vérifiée cryptographiquement. Aucun nouveau téléchargement n'est nécessaire. _(La mise à jour automatique fonctionne à partir de v0.1.1 ; la toute première version, v0.1.0, doit être remplacée une fois à la main.)_

## Utilisation

Maintenez **Option droite (⌥)** n'importe où et commencez à parler. Une pastille givrée affiche une forme d'onde en direct pendant l'écoute ; relâchez la touche et votre texte nettoyé est inséré dans l'app active. Ouvrez la fenêtre à tout moment pour voir votre **tableau de bord Home** — rythme, totaux, carte d'activité et lieux où vous dictez. Modifiez la touche, la langue, les moteurs et le nettoyage dans **Réglages**.

## Moteurs

Tout s'exécute sur l'appareil. Le modèle Apple est intégré à macOS et sélectionné par défaut ; vous pouvez télécharger d'autres moteurs locaux depuis la page **Modèles** de la barre latérale et passer de l'un à l'autre (un seul est actif à la fois).

| Moteur | Langues | Remarques |
| --- | --- | --- |
| **Apple Speech** (par défaut) | Variable selon macOS | Intégré, aucun téléchargement. `SpeechTranscriber` sur macOS 26+, `SFSpeechRecognizer` sur appareil sur macOS 14–15 |
| **Parakeet TDT 0.6B V3** | **25** — Europe uniquement | NVIDIA, via [FluidAudio](https://github.com/FluidInference/FluidAudio). Le plus rapide ; pas de CJC |
| **Nemotron 3.5 ASR 0.6B** | **40 locales**, dont CJC, arabe, hindi | NVIDIA, via FluidAudio. Le cheval de bataille multilingue |
| **Whisper Base** | **99** | OpenAI, via [WhisperKit](https://github.com/argmaxinc/WhisperKit). La couverture la plus large |

Pour le nettoyage, les règles intégrées (instantanées, déterministes) sont utilisées
par défaut ; Apple Intelligence (`FoundationModels`, macOS 26+) est une amélioration
optionnelle intégrée à macOS, sans rien à télécharger. Voir
[**docs/LANGUAGES.md**](../LANGUAGES.md) pour la matrice complète moteur/langue.

Les modèles téléchargeables ne sont récupérés qu'une fois, à la demande (pas de cloud lors de l'inférence : votre audio reste sur le Mac) et s'exécutent avec CoreML sur le Neural Engine d'Apple. VoiceType bascule automatiquement vers un moteur disponible si votre choix ne peut pas s'exécuter et revient toujours au texte brut plutôt que d'échouer.

> Le modèle vocal Parakeet est © NVIDIA, sous licence [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio est sous Apache-2.0. Whisper est d'OpenAI (MIT) ; WhisperKit est MIT.

<a name="languages"></a>
## Langues

La plupart des apps de dictée sont conçues pour l'anglais puis traduites. VoiceType
traite chaque langue comme un cas de première classe — c'est ce à quoi nous tenons
le plus.

**33 langues** pour la dictée · **16** avec des règles de nettoyage écrites à la main ·
**16** avec une interface traduite · **0** qui nécessite le cloud.

Arabe · Bulgare · 简体中文 · Croate · Tchèque · Danois · Nederlands · English ·
Estonien · Finnois · Français · Deutsch · Grec · हिन्दी · Hongrois · Italiano ·
日本語 · 한국어 · Letton · Lituanien · Maltais · Norsk · Polski · Português ·
Roumain · Русский · Slovaque · Slovène · Español · Svenska · Türkçe ·
Українська · Tiếng Việt

Ce que « multilingue » signifie concrètement ici :

- **C'est vous qui choisissez la langue ; VoiceType ne devine jamais.** La détection
  automatique produit des absurdités convaincantes quand elle se trompe : elle n'est
  donc pas proposée.
- **Les moteurs sont adaptés à votre langue.** Chaque modèle vocal déclare ce qu'il
  prend en charge (Parakeet est européen uniquement ; Nemotron couvre 40 locales dont
  le chinois ; Whisper en couvre 99 ; la liste d'Apple vient de macOS). Les modèles
  incapables de traiter votre langue sont grisés et VoiceType bascule vers un modèle
  qui le peut.
- **Le nettoyage connaît la langue.** 16 langues disposent d'un « pack de langue »
  compact et relisible : ses hésitations (嗯/呃, ähm, euh — jamais des mots porteurs
  de sens), ses conventions de ponctuation (。，？ pleine chasse pour le chinois et le
  japonais, 句号/読点 prononcés rendus sous forme de signes) et ses heuristiques
  d'interrogation. Les autres bénéficient d'une transcription fidèle avec un
  nettoyage neutre.
- **L'interface est localisée** en 16 langues et suit la langue système de macOS —
  indépendamment de votre langue de dictée : une interface en japonais peut dicter
  en portugais.
- **Sélectionnées, pas gonflées.** Nous pourrions annoncer les 99 langues de Whisper
  dès demain ; nous proposons celles qu'un moteur maîtrise vraiment, et un test le
  garantit.

📖 **[Matrice complète des langues, niveaux de qualité et lacunes connues →](../LANGUAGES.md)**

Votre langue manque à l'appel ou une traduction est perfectible ? Ajouter une langue
est volontairement simple — une traduction de l'interface ne demande aucun Swift —
voir [docs/LOCALIZATION.md](../LOCALIZATION.md). Les packs générés automatiquement
ont particulièrement besoin du regard de locuteurs natifs.

## Confidentialité

L'audio et les transcriptions restent sur votre Mac, sans exception : il n'existe aucun chemin cloud. Rien n'est enregistré hors de l'appareil et l'audio n'est jamais écrit sur disque. Même le résumé d'utilisation est construit uniquement à partir de compteurs agrégés, jamais du texte de vos transcriptions. C'est un invariant constitutionnel du projet, pas un réglage qui pourrait changer plus tard.

## Compiler depuis les sources

```bash
swift test              # exécute les tests unitaires de VoiceTypeKit
./Scripts/build-app.sh  # construit VoiceType.app (signature ad hoc)
./Scripts/make-dmg.sh   # crée un VoiceType.dmg à glisser-déposer
open VoiceType.app
```

## Contribuer

Les contributions sont les bienvenues. Lisez le [guide de contribution](../../CONTRIBUTING.md) pour les exigences de développement, les attentes de confidentialité et les conseils pour les pull requests. Vous souhaitez VoiceType dans votre langue ? [docs/LOCALIZATION.md](../LOCALIZATION.md) contient la liste de contrôle : une traduction d'interface ne demande aucun Swift et la qualité de dictée pour une nouvelle langue tient dans un fichier bien documenté. Tous les participants doivent respecter le [Code de conduite](../../CODE_OF_CONDUCT.md). Pour les vulnérabilités, suivez la procédure privée de notre [politique de sécurité](../../SECURITY.md).

## Architecture

Application Dock native **Swift 6 / SwiftUI** (macOS 14) avec tableau de bord Home. Raccourci global appuyer-pour-parler · capture micro AVAudioEngine · transcription interchangeable sur l'appareil · nettoyage interchangeable · insertion de texte par le presse-papiers/Accessibilité · HUD d'enregistrement flottant. Le cœur (`VoiceTypeKit`) est pur et testé ; la cible app contient les moteurs système et l'interface. Les détails sont dans [`CLAUDE.md`](../../CLAUDE.md) et évoluent via `specs/`.

## Licence

[MIT](../../LICENSE) © 2026 Michael Li.

Les composants et modèles sur l'appareil fournis avec l'app conservent leurs propres licences ; consultez [`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md), également inclus dans le bundle de l'app.

## Comment ce dépôt est géré

VoiceType est un dépôt produit autonome géré au quotidien par un agent (la **boucle externe** : triage → revue → fusion/escalade), un humain apportant le **goût** en modifiant `specs/`. Il lie le framework [`@aros/*`](../../../agent-repo-os) pendant le développement local. Consultez [`CLAUDE.md`](../../CLAUDE.md) pour les règles de fonctionnement.

## Structure du dépôt

```
VoiceType/
├── CLAUDE.md          # règles de fonctionnement de l'agent
├── Package.swift      # SwiftPM : VoiceTypeKit (cœur) + VoiceType (app)
├── Sources/
│   ├── VoiceTypeKit/  # cœur pur et testé : protocoles, pipeline, nettoyage, résolveur
│   └── VoiceType/     # app : raccourci, audio, moteurs, insertion, tableau de bord
├── Tests/             # tests unitaires VoiceTypeKit
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── docs/              # LANGUAGES.md (matrice de couverture) · LOCALIZATION.md · readme/
├── specs/             # surface humaine : direction produit (l'agent ne modifie pas)
└── README.md
```

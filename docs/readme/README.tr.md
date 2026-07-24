<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Her yerde, kendi dilinizde konuşun — temiz metin anında, tamamen cihazınızda.

Hızlı, özel ve açık kaynaklı bir macOS sesle dikte uygulaması. Bir tuşa basılı
tutun, konuşun — Türkçe, English, 中文, Español, 日本語 veya 30'dan fazla başka
dilde — sözleriniz kullandığınız uygulamaya temiz, noktalı metin olarak düşsün.
Sesiniz Mac'inizden asla ayrılmaz; her şey cihaz üzerinde çalışır.

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)
&nbsp;[![Languages](https://img.shields.io/badge/dictation-30%2B%20languages-F2743E)](#languages)
&nbsp;[![License](https://img.shields.io/badge/license-MIT-111111)](../../LICENSE)

[English](../../README.md) · [简体中文](./README.zh-Hans.md) · [Deutsch](./README.de.md) · [Español](./README.es.md) · [Français](./README.fr.md) · [Italiano](./README.it.md) · [日本語](./README.ja.md) · [한국어](./README.ko.md) · [Nederlands](./README.nl.md) · [Polski](./README.pl.md) · [Português](./README.pt-BR.md) · [Русский](./README.ru.md) · [Svenska](./README.sv.md) · **Türkçe** · [Українська](./README.uk.md) · [Tiếng Việt](./README.vi.md)

_Bu çeviri mümkün olan en iyi şekilde korunur; İngilizce README referans sürümdür. Düzeltmeler [pull request](../../CONTRIBUTING.md) ile memnuniyetle karşılanır._

</div>

---

> **Kuzey yıldızımız:** Her yerde konuşun, temiz metni anında alın; sesiniz Mac'inizden hiç ayrılmasın.

## Neden VoiceType?

- 🔒 **Tasarımdan itibaren özel.** Ses ve transkriptler Mac'inizde kalır. Hesap, telemetri veya bulut yoktur; kapatacak bir şey de yoktur.
- ⚡ **Gecikme özelliktir.** Apple'ın cihaz içi konuşma modeliyle yerel Swift; metne ulaşma süresini iyileştiriyoruz.
- 🌍 **Sizin dilinizi konuşur.** Yalnızca İngilizce değil, 30'dan fazla dilde dikte edin. Temizleme her dilin kurallarını bilir (中文 tam genişlikli noktalama, söylenen 句号, dile özgü dolgu sesleri); uygulama dilinizi gerçekten destekleyen motoru seçer ve arayüz 16 dilde sunulur.
- 🎙️ **Her yerde basılı tutup konuşun.** Genel kısayol her uygulamada çalışır; temizlenmiş metin imlecin bulunduğu yere eklenir.
- ✨ **Akıllı temizleme.** Noktalama, büyük harf ve dolgu sözcüklerini kaldırma; sözlerinizi asla değiştirmeden.
- 📊 **Sesiniz görselleştirilir.** Sakin Home panosu sözcüklerinizi, hızınızı ve günlük serinizi; etkinlik ısı haritası ve tamamen Mac'inizde hesaplanan kullanım özetiyle birlikte gösterir.
- 🧩 **Değiştirilebilir motorlar.** Varsayılan Apple modeli yerleşiktir; isteğe bağlı, yerel NVIDIA Parakeet yükseltmesini indirip bir seferde bir motoru etkinleştirebilirsiniz.

## İndirme ve kurulum

1. Son sürümden **[⬇ VoiceType.dmg'yi indirin](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)**.
2. DMG'yi açın ve **VoiceType**'ı **Applications** klasörünüze sürükleyin. Uygulama Apple tarafından **imzalanmış ve noter onaylıdır**; Gatekeeper'ı aşmadan normal çift tıklamayla açılır.
3. VoiceType'ın istediği üç izni verin: **Mikrofon**, **Konuşma Tanıma** ve **Erişilebilirlik**.

> macOS 14 veya sonrası (Apple Silicon) gerekir.

**Güncellemeler otomatiktir.** VoiceType yeni sürümleri arka planda ve **Güncellemeleri Denetle…** komutuyla kontrol eder; [Sparkle](https://sparkle-project.org) ile yerinde kurar. Her güncelleme kriptografik olarak imzalanır ve doğrulanır. _(Otomatik güncelleme v0.1.1 ve sonrası için çalışır; ilk v0.1.0 sürümü bir kez elle değiştirilmelidir.)_

## Kullanım

Herhangi bir yerde **Sağ Option (⌥)** tuşunu basılı tutup konuşun. Dinlerken canlı dalga biçimini gösteren buzlu bir kapsül görünür; tuşu bıraktığınızda temiz metniniz odaktaki uygulamaya eklenir. **Home panosunda** hızınızı, toplamlarınızı, etkinlik ısı haritanızı ve dikte ettiğiniz yerleri görebilirsiniz. Tuşu, dili, motorları ve temizlemeyi **Ayarlar**'dan değiştirin.

## Motorlar

Her şey cihaz üzerinde çalışır. Apple modeli macOS'ta yerleşiktir ve varsayılan olarak seçilir; kenar çubuğundaki **Modeller** sayfasından başka yerel motorları indirip aralarında geçiş yapabilirsiniz (aynı anda yalnızca biri etkindir).

| Aşama | Varsayılan (yerleşik) | İsteğe bağlı alternatifler (cihaz üzerinde) |
| --- | --- | --- |
| **Transkripsiyon** | Apple `Speech` | **Parakeet TDT 0.6B V3** (NVIDIA, [FluidAudio](https://github.com/FluidInference/FluidAudio) aracılığıyla) · **Whisper Base** (OpenAI, [WhisperKit](https://github.com/argmaxinc/WhisperKit) aracılığıyla) — istek üzerine indirilir |
| **Temizleme** | Yerleşik kurallar (anlık, belirleyici) | Apple Intelligence (`FoundationModels`, macOS 26+) — macOS'ta yerleşik, indirme gerekmez |

İndirilebilir modeller yalnızca bir kez, istek üzerine alınır; çıkarım sırasında bulut kullanılmaz ve sesiniz Mac'inizde kalır. CoreML ile Apple Neural Engine'de çalışırlar. Seçtiğiniz motor çalışamazsa VoiceType kullanılabilir bir motora geçer ve hata vermek yerine her zaman düz metne iner.

> Parakeet konuşma modeli © NVIDIA ve [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) lisanslıdır. FluidAudio Apache-2.0'dır. Whisper OpenAI (MIT), WhisperKit MIT lisanslıdır.

<a name="languages"></a>
## Diller

VoiceType uçtan uca çok dillidir; altyazılı İngilizce değildir:

- **30'dan fazla dilde dikte edin:** Türkçe, English, 中文, Español, Français, Deutsch, 日本語, 한국어, Português, Русский, Tiếng Việt ve daha fazlası. Dili siz seçersiniz; VoiceType asla tahmin etmez.
- **Motorlar dilinize göre eşleştirilir.** Her konuşma modeli desteklediği dilleri bildirir (Parakeet yalnızca Avrupa dilleri; Nemotron Çince dahil 40 yerel ayar; Whisper geniş ölçüde çok dilli; Apple listesi macOS'tan gelir). Uygun olmayan modeller grileşir ve VoiceType desteklenen birine geçer.
- **Temizleme dili bilir.** Her dilin gözden geçirilebilir küçük bir "dil paketi" vardır: anlam taşıyan sözcükler asla değil, dolgu sözcükleri; noktalama kuralları (Çince ve Japonca için tam genişlikli 。，？; söylenen 句号/読点 işaret olur) ve soru sezgileri.
- **Uygulamanın kendisi** macOS sistem dilinizi izleyerek 16 dile çevrilmiştir; Sistem Ayarları'ndaki uygulama başına geçersiz kılma da çalışır.

Diliniz eksik mi, çeviri hatalı mı? Yeni dil eklemek bilinçli olarak küçüktür; bir arayüz çevirisi Swift gerektirmez. Bkz. [docs/LOCALIZATION.md](../LOCALIZATION.md).

<a name="privacy"></a>
## Gizlilik

Ses ve transkriptler Mac'inizde kalır, nokta; bulut yolu yoktur. Hiçbir şey cihaz dışına kaydedilmez ve ses asla diske yazılmaz. Kullanım özeti bile transkript metninden değil yalnızca toplu sayımlardan oluşturulur. Bu, projenin değişebilecek bir ayarı değil, anayasal değişmezidir.

## Kaynaktan derleme

```bash
swift test              # VoiceTypeKit birim testlerini çalıştırır
./Scripts/build-app.sh  # VoiceType.app'i derler (ad-hoc imzalı)
./Scripts/make-dmg.sh   # sürükleyip kurmalık VoiceType.dmg paketler
open VoiceType.app
```

## Katkıda bulunma

Katkılar memnuniyetle karşılanır. Geliştirme gereksinimleri, gizlilik beklentileri ve pull request rehberi için [katkı kılavuzunu](../../CONTRIBUTING.md) okuyun. VoiceType'ı kendi dilinizde mi istiyorsunuz? [docs/LOCALIZATION.md](../LOCALIZATION.md) kontrol listesini içerir: arayüz çevirisi Swift gerektirmez; yeni dilin dikte kalitesi iyi belgelenmiş tek bir dosyadır. Tüm katılımcılar [Davranış Kuralları](../../CODE_OF_CONDUCT.md)'na uymalıdır. Güvenlik açıkları için [Güvenlik Politikası](../../SECURITY.md)'ndaki gizli bildirim sürecini izleyin.

## Mimari

Home panolu yerel **Swift 6 / SwiftUI** Dock uygulaması (macOS 14). Genel bas-konuş kısayolu · AVAudioEngine mikrofon kaydı · değiştirilebilir cihaz içi transkripsiyon · değiştirilebilir temizleme · pano/Erişilebilirlik yoluyla metin ekleme · yüzen kayıt HUD'u. Çekirdek (`VoiceTypeKit`) saf ve testlidir; uygulama hedefi sistem motorlarını ve arayüzü tutar. Ayrıntılar [`CLAUDE.md`](../../CLAUDE.md)'dedir ve `specs/` ile gelişir.

## Lisans

[MIT](../../LICENSE) © 2026 Michael Li.

Uygulamayla gelen üçüncü taraf bileşenler ve cihaz içi modeller kendi lisanslarını korur; ayrıca uygulama paketinde bulunan [`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md)'ye bakın.

## Bu depo nasıl yürütülür

VoiceType, günlük olarak bir ajan tarafından ( **dış döngü**: önceliklendirme → inceleme → birleştirme/yükseltme) yürütülen bağımsız bir ürün deposudur; insan, `specs/` düzenleyerek **zevki** sağlar. Yerel geliştirmede [`@aros/*`](../../../agent-repo-os) çerçevesini bağlar. Çalışma kuralları için [`CLAUDE.md`](../../CLAUDE.md)'ye bakın.

## Depo düzeni

```
VoiceType/
├── CLAUDE.md          # ajan çalışma kuralları
├── Package.swift      # SwiftPM: VoiceTypeKit (çekirdek) + VoiceType (uygulama)
├── Sources/
│   ├── VoiceTypeKit/  # saf, testli çekirdek: protokoller, işlem hattı, temizleme, çözücü
│   └── VoiceType/     # uygulama: kısayol, ses, motorlar, ekleme, pano arayüzü
├── Tests/             # VoiceTypeKit birim testleri
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── specs/             # insan yüzeyi: ürün yönü (ajan düzenlemez)
└── README.md
```

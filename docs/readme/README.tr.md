<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### 33 dilde dikte. Anında temiz metin. Tamamı cihaz üzerinde.

macOS için hızlı, gizliliğe saygılı, açık kaynaklı bir sesli dikte uygulaması. Bir
tuşu basılı tutun ve konuşun — Türkçe, English, 中文, Español, 日本語, العربية,
हिन्दी, Tiếng Việt ya da 26 dilde daha — sözleriniz, o anda kullandığınız
uygulamaya temiz ve noktalanmış metin olarak düşsün.

**Baştan sona çok dilli**: konuşma modeli dilinize göre seçilir, temizleme aşaması
dilinizin noktalama alışkanlıklarını ve dolgu sözcüklerini bilir, uygulamanın kendi
arayüzü de 16 dilde sunulur. Bunların hepsi **cihaz üzerinde** çalışır — sesiniz
hangi dilde olursa olsun Mac'inizden hiç ayrılmaz.

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)
&nbsp;[![Dictation languages](https://img.shields.io/badge/dictation-33%20languages-F2743E)](../LANGUAGES.md)
&nbsp;[![Interface languages](https://img.shields.io/badge/interface-16%20languages-F2743E)](../LANGUAGES.md#interface-languages)
&nbsp;[![License](https://img.shields.io/badge/license-MIT-111111)](../../LICENSE)

[English](../../README.md) · [简体中文](./README.zh-Hans.md) · [Deutsch](./README.de.md) · [Español](./README.es.md) · [Français](./README.fr.md) · [Italiano](./README.it.md) · [日本語](./README.ja.md) · [한국어](./README.ko.md) · [Nederlands](./README.nl.md) · [Polski](./README.pl.md) · [Português](./README.pt-BR.md) · [Русский](./README.ru.md) · [Svenska](./README.sv.md) · **Türkçe** · [Українська](./README.uk.md) · [Tiếng Việt](./README.vi.md)

_Bu çeviri mümkün olan en iyi şekilde korunur; İngilizce README referans sürümdür. Düzeltmeler [pull request](../../CONTRIBUTING.md) ile memnuniyetle karşılanır._

</div>

---

> **Kuzey yıldızımız:** Her yerde konuşun, temiz metni anında alın; sesiniz Mac'inizden hiç ayrılmasın.

## Neden VoiceType?

- 🌍 **Altyazılı İngilizce değil, baştan sona çok dilli.** [33 dilde](../LANGUAGES.md) dikte edin. VoiceType dilinizi gerçekten destekleyen bir konuşma modeli seçer, metni *o dilin* kurallarına göre temizler — 中文 için tam genişlikte noktalama, sesli 句号, dile özgü dolgu sözcükleri — ve kendi arayüzünü 16 dilde sunar.
- 🔒 **Her dilde gizli.** Ses ve çeviri yazılar Mac'inizde kalır. Hesap yok, telemetri yok, bulut yok — «zor dilleri sunucuya gönderelim» diye kapatmanız gereken bir yol hiç yok.
- ⚡ **Gecikme başlı başına bir özelliktir.** Yerel Swift ve cihaz üzerindeki konuşma modelleriyle metne ulaşma süresini optimize ediyoruz.
- 🎙️ **Her yerde basılı tutup konuşun.** Genel kısayol her uygulamada çalışır; temizlenmiş metin imlecin bulunduğu yere eklenir.
- ✨ **Akıllı temizleme.** Noktalama, büyük harf ve dolgu sözcüklerini kaldırma; sözlerinizi asla değiştirmeden.
- 📊 **Sesiniz görselleştirilir.** Sakin Home panosu sözcüklerinizi, hızınızı ve günlük serinizi; etkinlik ısı haritası ve tamamen Mac'inizde hesaplanan kullanım özetiyle birlikte gösterir.
- 🧩 **Değiştirilebilir motorlar.** Varsayılan olarak Apple'ın yerleşik modeli; isteğe bağlı yerel yükseltmeleri — NVIDIA Parakeet, NVIDIA Nemotron, OpenAI Whisper — indirip aralarında geçiş yapabilirsiniz (aynı anda biri etkin).

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

| Motor | Diller | Notlar |
| --- | --- | --- |
| **Apple Speech** (varsayılan) | macOS sürümüne göre değişir | Yerleşik, indirme yok. macOS 26+ için `SpeechTranscriber`, macOS 14–15 için cihaz üzerinde `SFSpeechRecognizer` |
| **Parakeet TDT 0.6B V3** | **25** — yalnızca Avrupa dilleri | NVIDIA, [FluidAudio](https://github.com/FluidInference/FluidAudio) üzerinden. En hızlısı; CJK yok |
| **Nemotron 3.5 ASR 0.6B** | CJK, Arapça ve Hintçe dahil **40 yerel ayar** | NVIDIA, FluidAudio üzerinden. Çok dilli iş atı |
| **Whisper Base** | **99** | OpenAI, [WhisperKit](https://github.com/argmaxinc/WhisperKit) üzerinden. En geniş kapsam |

Temizleme için yerleşik kurallar (anında, belirlenimci) varsayılandır; Apple
Intelligence (`FoundationModels`, macOS 26+) macOS'a gömülü, indirilecek hiçbir şeyi
olmayan isteğe bağlı bir yükseltmedir. Dil–motor tablosunun tamamı için
[**docs/LANGUAGES.md**](../LANGUAGES.md) dosyasına bakın.

İndirilebilir modeller yalnızca bir kez, istek üzerine alınır; çıkarım sırasında bulut kullanılmaz ve sesiniz Mac'inizde kalır. CoreML ile Apple Neural Engine'de çalışırlar. Seçtiğiniz motor çalışamazsa VoiceType kullanılabilir bir motora geçer ve hata vermek yerine her zaman düz metne iner.

> Parakeet konuşma modeli © NVIDIA ve [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) lisanslıdır. FluidAudio Apache-2.0'dır. Whisper OpenAI (MIT), WhisperKit MIT lisanslıdır.

<a name="languages"></a>
## Diller

Dikte uygulamalarının çoğu İngilizce için yapılır, sonradan çevrilir. VoiceType her
dili birinci sınıf bir durum olarak ele alır — en çok önemsediğimiz şey bu.

Dikte için **33 dil** · elle yazılmış temizleme kuralları olan **16 dil** ·
çevrilmiş arayüzü olan **16 dil** · buluta ihtiyaç duyan **0 dil**.

Arapça · Bulgarca · 简体中文 · Hırvatça · Çekçe · Danca · Nederlands · English ·
Estonca · Fince · Français · Deutsch · Yunanca · हिन्दी · Macarca · Italiano ·
日本語 · 한국어 · Letonca · Litvanca · Maltaca · Norsk · Polski · Português ·
Rumence · Русский · Slovakça · Slovence · Español · Svenska · Türkçe ·
Українська · Tiếng Việt

«Çok dilli» burada tam olarak şu anlama geliyor:

- **Dili siz seçersiniz; VoiceType asla tahmin etmez.** Otomatik algılama yanıldığında
  kendinden emin saçmalıklar üretir, bu yüzden sunulmuyor.
- **Motorlar dilinize göre eşleştirilir.** Her konuşma modeli neyi desteklediğini
  bildirir (Parakeet yalnızca Avrupa dilleri; Nemotron Çince dahil 40 yerel ayar;
  Whisper 99 dil; Apple'ın listesi macOS'tan gelir). Dilinizi işleyemeyen modeller
  soluklaşır ve VoiceType işleyebilen bir motora geçer.
- **Temizleme dili bilir.** 16 dil, küçük ve gözden geçirilebilir bir «dil paketi»
  ile gelir: o dilin dolgu sözcükleri (嗯/呃, ähm, euh — anlam taşıyan sözcükler asla),
  noktalama alışkanlıkları (Çince ve Japonca için tam genişlikte 。，？, sesli
  söylenen 句号/読点 işaretlere dönüştürülür) ve soru sezgileri. Diğerleri sadık bir
  çeviri yazı ile nötr temizleme alır.
- **Arayüz 16 dile yerelleştirilmiştir** ve macOS sistem dilinizi izler — dikte
  dilinden bağımsız olarak, yani Japonca arayüzle Portekizce dikte edebilirsiniz.
- **Şişirilmiş değil, seçilmiş.** Whisper'ın 99 dilini yarın listeleyebilirdik; biz
  bir motorun gerçekten iyi olduğu dilleri sunuyoruz ve bunu bir test güvence altına
  alıyor.

📖 **[Tam dil tablosu, kalite katmanları ve bilinen eksikler →](../LANGUAGES.md)**

Diliniz eksik mi, yoksa bir çeviri mi yanlış? Dil eklemek bilinçli olarak küçük
tutulmuştur — arayüz çevirisi hiç Swift gerektirmez — bkz.
[docs/LOCALIZATION.md](../LOCALIZATION.md). Özellikle makineyle yazılmış paketlerin
ana dili konuşanların gözüne ihtiyacı var.

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
├── docs/              # LANGUAGES.md (kapsam tablosu) · LOCALIZATION.md · readme/
├── specs/             # insan yüzeyi: ürün yönü (ajan düzenlemez)
└── README.md
```

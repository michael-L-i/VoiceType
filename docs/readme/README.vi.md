<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Đọc chính tả bằng 33 ngôn ngữ. Văn bản sạch ngay lập tức. Toàn bộ trên máy.

Một ứng dụng nhập liệu bằng giọng nói cho macOS: nhanh, riêng tư và mã nguồn mở.
Giữ một phím rồi nói — bằng tiếng Việt, English, 中文, Español, 日本語, العربية,
हिन्दी hoặc 26 ngôn ngữ khác — và lời bạn nói sẽ hiện ra dưới dạng văn bản sạch,
có dấu câu, ngay trong ứng dụng bạn đang dùng.

Đa ngôn ngữ **từ đầu đến cuối**: mô hình giọng nói được chọn theo ngôn ngữ của bạn,
bước dọn dẹp hiểu quy ước dấu câu và từ đệm của ngôn ngữ đó, và bản thân giao diện
ứng dụng có 16 ngôn ngữ. Tất cả đều chạy **trên máy** — âm thanh của bạn không bao
giờ rời khỏi máy Mac, ở bất kỳ ngôn ngữ nào.

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)
&nbsp;[![Dictation languages](https://img.shields.io/badge/dictation-33%20languages-F2743E)](../LANGUAGES.md)
&nbsp;[![Interface languages](https://img.shields.io/badge/interface-16%20languages-F2743E)](../LANGUAGES.md#interface-languages)
&nbsp;[![License](https://img.shields.io/badge/license-MIT-111111)](../../LICENSE)

[English](../../README.md) · [简体中文](./README.zh-Hans.md) · [Deutsch](./README.de.md) · [Español](./README.es.md) · [Français](./README.fr.md) · [Italiano](./README.it.md) · [日本語](./README.ja.md) · [한국어](./README.ko.md) · [Nederlands](./README.nl.md) · [Polski](./README.pl.md) · [Português](./README.pt-BR.md) · [Русский](./README.ru.md) · [Svenska](./README.sv.md) · [Türkçe](./README.tr.md) · [Українська](./README.uk.md) · **Tiếng Việt**

_Bản dịch này được duy trì trong khả năng có thể; README tiếng Anh là bản tham chiếu. Rất hoan nghênh các chỉnh sửa qua [pull request](../../CONTRIBUTING.md)._

</div>

---

> **Kim chỉ nam:** Nói ở bất cứ đâu, nhận văn bản gọn gàng ngay lập tức mà âm thanh của bạn không rời khỏi Mac.

## Vì sao VoiceType

- 🌍 **Đa ngôn ngữ từ đầu đến cuối, không phải tiếng Anh gắn phụ đề.** Đọc chính tả bằng [33 ngôn ngữ](../LANGUAGES.md). VoiceType chọn mô hình giọng nói thực sự hỗ trợ ngôn ngữ của bạn, dọn dẹp theo quy ước của *chính* ngôn ngữ đó — dấu câu toàn chiều rộng trong 中文, 句号 được đọc thành lời, từ đệm riêng của từng ngôn ngữ — và cung cấp giao diện bằng 16 ngôn ngữ.
- 🔒 **Riêng tư ở mọi ngôn ngữ.** Âm thanh và bản ghi ở lại trên máy Mac của bạn. Không tài khoản, không đo từ xa, không đám mây — thậm chí không tồn tại đường đi «gửi những ngôn ngữ khó lên máy chủ» để mà tắt.
- ⚡ **Độ trễ chính là tính năng.** Swift thuần cùng các mô hình giọng nói chạy trên máy — chúng tôi tối ưu thời gian từ lúc nói đến lúc ra chữ.
- 🎙️ **Nhấn để nói ở mọi nơi.** Phím tắt toàn cục hoạt động trong mọi ứng dụng; văn bản đã làm sạch được chèn ngay vị trí con trỏ.
- ✨ **Làm sạch thông minh.** Dấu câu, viết hoa và bỏ từ đệm — nhưng không bao giờ thay đổi lời của bạn.
- 📊 **Trực quan hóa giọng nói.** Bảng điều khiển Home nhẹ nhàng theo dõi số từ, nhịp nói và chuỗi ngày của bạn, cùng bản đồ nhiệt hoạt động và tóm tắt sử dụng được tính hoàn toàn trên Mac.
- 🧩 **Bộ máy thay thế được.** Mặc định là mô hình tích hợp của Apple, cùng các bản nâng cấp cục bộ tùy chọn — NVIDIA Parakeet, NVIDIA Nemotron, OpenAI Whisper — bạn có thể tải về và chuyển đổi giữa chúng (mỗi lần một bộ máy).

## Tải xuống và cài đặt

1. **[⬇ Tải VoiceType.dmg](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)** từ bản phát hành mới nhất.
2. Mở DMG và kéo **VoiceType** vào thư mục **Applications**. Ứng dụng được Apple **ký và công chứng**, nên mở bằng nhấp đúp bình thường, không cần vượt qua Gatekeeper.
3. Cấp ba quyền mà VoiceType yêu cầu: **Microphone**, **Speech Recognition** và **Accessibility**.

> Yêu cầu macOS 14 trở lên (Apple Silicon).

**Cập nhật tự động.** VoiceType kiểm tra phiên bản mới ở nền (và theo yêu cầu qua **Check for Updates…**) rồi cài tại chỗ bằng [Sparkle](https://sparkle-project.org); mỗi bản cập nhật đều được ký và xác minh bằng mật mã. _(Tự động cập nhật hoạt động từ v0.1.1; bản đầu tiên v0.1.0 cần được thay thế thủ công một lần.)_

## Cách dùng

Giữ **Option phải (⌥)** ở bất cứ đâu và bắt đầu nói. Một viên nang kính mờ hiện dạng sóng trực tiếp khi ứng dụng lắng nghe; thả phím để chèn văn bản đã làm sạch vào ứng dụng đang được chọn. Mở **bảng điều khiển Home** bất cứ lúc nào để xem nhịp nói, tổng số, bản đồ nhiệt và nơi bạn đọc chính tả. Thay đổi phím, ngôn ngữ, động cơ và cách làm sạch trong **Settings**.

## Động cơ

Mọi thứ chạy trên thiết bị. Mô hình Apple có sẵn trong macOS và được chọn mặc định; bạn có thể tải các động cơ cục bộ khác ở trang **Models** trên thanh bên và chuyển đổi giữa chúng (mỗi lần chỉ có một động cơ hoạt động).

| Bộ máy | Ngôn ngữ | Ghi chú |
| --- | --- | --- |
| **Apple Speech** (mặc định) | Tùy theo macOS | Tích hợp sẵn, không cần tải. `SpeechTranscriber` trên macOS 26+, `SFSpeechRecognizer` trên máy với macOS 14–15 |
| **Parakeet TDT 0.6B V3** | **25** — chỉ ngôn ngữ châu Âu | NVIDIA, qua [FluidAudio](https://github.com/FluidInference/FluidAudio). Nhanh nhất; không có CJK |
| **Nemotron 3.5 ASR 0.6B** | **40 miền địa phương**, gồm CJK, tiếng Ả Rập, tiếng Hindi | NVIDIA, qua FluidAudio. Trụ cột đa ngôn ngữ |
| **Whisper Base** | **99** | OpenAI, qua [WhisperKit](https://github.com/argmaxinc/WhisperKit). Phạm vi rộng nhất |

Với bước dọn dẹp, các quy tắc tích hợp (tức thì, tất định) là mặc định; Apple
Intelligence (`FoundationModels`, macOS 26+) là bản nâng cấp tùy chọn đã nằm sẵn
trong macOS, không phải tải gì thêm. Xem
[**docs/LANGUAGES.md**](../LANGUAGES.md) để có bảng đối chiếu ngôn ngữ – bộ máy đầy đủ.

Các mô hình có thể tải chỉ được lấy một lần khi cần; không có đám mây lúc suy luận nên âm thanh vẫn ở trên Mac. Chúng chạy bằng CoreML trên Apple Neural Engine. Nếu lựa chọn của bạn không chạy được, VoiceType tự động chuyển sang động cơ khả dụng và luôn trả về văn bản thô thay vì thất bại.

> Mô hình giọng nói Parakeet © NVIDIA, theo giấy phép [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio là Apache-2.0. Whisper là của OpenAI (MIT); WhisperKit là MIT.

<a name="languages"></a>
## Ngôn ngữ

Phần lớn ứng dụng đọc chính tả được xây cho tiếng Anh rồi mới dịch sang ngôn ngữ
khác. VoiceType coi mọi ngôn ngữ là công dân hạng nhất — đây là điều chúng tôi
quan tâm nhất.

**33 ngôn ngữ** để đọc chính tả · **16** có quy tắc dọn dẹp viết tay ·
**16** có giao diện đã dịch · **0** cần đến đám mây.

Tiếng Ả Rập · Tiếng Bulgaria · 简体中文 · Tiếng Croatia · Tiếng Séc · Tiếng Đan Mạch ·
Nederlands · English · Tiếng Estonia · Tiếng Phần Lan · Français · Deutsch ·
Tiếng Hy Lạp · हिन्दी · Tiếng Hungary · Italiano · 日本語 · 한국어 · Tiếng Latvia ·
Tiếng Litva · Tiếng Malta · Norsk · Polski · Português · Tiếng Romania · Русский ·
Tiếng Slovakia · Tiếng Slovenia · Español · Svenska · Türkçe · Українська ·
Tiếng Việt

«Đa ngôn ngữ» ở đây thực sự có nghĩa là:

- **Bạn chọn ngôn ngữ; VoiceType không bao giờ đoán.** Nhận dạng tự động khi sai sẽ
  tạo ra thứ vô nghĩa nhưng nghe rất thuyết phục, nên chúng tôi không cung cấp.
- **Bộ máy được chọn khớp với ngôn ngữ của bạn.** Mỗi mô hình giọng nói khai báo
  những gì nó hỗ trợ (Parakeet chỉ có ngôn ngữ châu Âu; Nemotron bao phủ 40 miền địa
  phương gồm cả tiếng Trung; Whisper bao phủ 99; danh sách của Apple lấy từ macOS).
  Mô hình không xử lý được ngôn ngữ của bạn sẽ bị làm mờ, và VoiceType chuyển sang
  mô hình xử lý được.
- **Bước dọn dẹp hiểu ngôn ngữ.** 16 ngôn ngữ đi kèm một «gói ngôn ngữ» nhỏ gọn, dễ
  rà soát: các từ đệm (嗯/呃, ähm, euh — không bao giờ là từ mang nghĩa), quy ước dấu
  câu (。，？ toàn chiều rộng cho tiếng Trung và tiếng Nhật; 句号/読点 đọc thành lời
  được chuyển thành dấu) và quy tắc nhận biết câu hỏi. Các ngôn ngữ còn lại vẫn được
  ghi lại trung thực với phần dọn dẹp trung tính.
- **Giao diện được bản địa hóa** sang 16 ngôn ngữ và đi theo ngôn ngữ hệ thống macOS —
  độc lập với ngôn ngữ đọc chính tả, nên giao diện tiếng Nhật vẫn có thể đọc chính tả
  tiếng Bồ Đào Nha.
- **Được tuyển chọn, không phải thổi phồng.** Chúng tôi có thể liệt kê 99 ngôn ngữ
  của Whisper ngay ngày mai; nhưng chúng tôi chỉ cung cấp những ngôn ngữ mà một bộ
  máy thực sự làm tốt, và có một bài kiểm thử bảo đảm điều đó.

📖 **[Bảng ngôn ngữ đầy đủ, các mức chất lượng và những thiếu sót đã biết →](../LANGUAGES.md)**

Ngôn ngữ của bạn còn thiếu, hay có chỗ dịch chưa đúng? Việc thêm một ngôn ngữ được
giữ nhỏ gọn có chủ đích — dịch giao diện hoàn toàn không cần Swift — xem
[docs/LOCALIZATION.md](../LOCALIZATION.md). Đặc biệt các gói do máy tạo rất cần con
mắt của người bản ngữ.

## Quyền riêng tư

Âm thanh và bản chép lời ở lại trên Mac của bạn, không có ngoại lệ — không hề có đường gửi lên đám mây. Không gì được ghi nhật ký ngoài thiết bị và âm thanh không bao giờ được ghi ra đĩa. Ngay cả tóm tắt sử dụng thân thiện cũng chỉ được tạo từ các số đếm tổng hợp, không phải nội dung bản chép lời. Đây là bất biến hiến định của dự án, không phải một cài đặt có thể thay đổi sau này.

## Xây dựng từ mã nguồn

```bash
swift test              # chạy kiểm thử đơn vị VoiceTypeKit
./Scripts/build-app.sh  # xây dựng VoiceType.app (ký ad-hoc)
./Scripts/make-dmg.sh   # đóng gói VoiceType.dmg kéo-thả để cài
open VoiceType.app
```

## Đóng góp

Chúng tôi hoan nghênh đóng góp. Hãy đọc [hướng dẫn đóng góp](../../CONTRIBUTING.md) để biết yêu cầu phát triển, kỳ vọng về quyền riêng tư và hướng dẫn pull request. Muốn có VoiceType bằng ngôn ngữ của bạn? [docs/LOCALIZATION.md](../LOCALIZATION.md) có danh sách kiểm tra: bản dịch giao diện không cần Swift và chất lượng đọc chính tả cho ngôn ngữ mới nằm trong một tệp được ghi chép rõ ràng. Mọi người tham gia phải tuân thủ [Quy tắc ứng xử](../../CODE_OF_CONDUCT.md). Với lỗ hổng bảo mật, hãy theo quy trình báo cáo riêng tư trong [Chính sách bảo mật](../../SECURITY.md).

## Kiến trúc

Ứng dụng Dock **Swift 6 / SwiftUI** thuần (macOS 14) với bảng điều khiển Home. Phím tắt nhấn-để-nói toàn cục · thu âm mic AVAudioEngine · chép lời trên thiết bị có thể thay thế · làm sạch có thể thay thế · chèn văn bản qua clipboard/Accessibility · HUD ghi âm nổi. Lõi (`VoiceTypeKit`) thuần và có kiểm thử; mục tiêu ứng dụng chứa động cơ hệ thống và giao diện. Chi tiết nằm trong [`CLAUDE.md`](../../CLAUDE.md) và phát triển qua `specs/`.

## Giấy phép

[MIT](../../LICENSE) © 2026 Michael Li.

Các thành phần bên thứ ba và mô hình trên thiết bị đi kèm ứng dụng giữ giấy phép riêng; xem [`THIRD_PARTY_LICENSES.md`](../../THIRD_PARTY_LICENSES.md), cũng có trong gói ứng dụng.

## Cách repo này được vận hành

VoiceType là repo sản phẩm độc lập do một tác nhân vận hành hằng ngày (**vòng lặp bên ngoài**: phân loại → xem xét → hợp nhất/chuyển cấp), trong khi con người cung cấp **gu** bằng cách chỉnh sửa `specs/`. Khi phát triển cục bộ, nó liên kết framework [`@aros/*`](../../../agent-repo-os). Xem [`CLAUDE.md`](../../CLAUDE.md) để biết quy tắc vận hành.

## Bố cục repo

```
VoiceType/
├── CLAUDE.md          # quy tắc vận hành của tác nhân
├── Package.swift      # SwiftPM: VoiceTypeKit (lõi) + VoiceType (ứng dụng)
├── Sources/
│   ├── VoiceTypeKit/  # lõi thuần, được kiểm thử: giao thức, pipeline, làm sạch, bộ phân giải
│   └── VoiceType/     # ứng dụng: phím tắt, âm thanh, động cơ, chèn văn bản, giao diện bảng điều khiển
├── Tests/             # kiểm thử đơn vị VoiceTypeKit
├── Scripts/           # build-app.sh · make-dmg.sh · make-icon.swift · release.sh
├── Resources/         # Info.plist · entitlements · AppIcon
├── docs/              # LANGUAGES.md (bảng phạm vi hỗ trợ) · LOCALIZATION.md · readme/
├── specs/             # bề mặt của con người: hướng sản phẩm (tác nhân không sửa)
└── README.md
```

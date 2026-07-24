<div align="center">

<img src="../logo.png" width="128" alt="VoiceType" />

# VoiceType

### Nói ở bất cứ đâu, bằng ngôn ngữ của bạn — văn bản gọn gàng ngay tức thì, hoàn toàn trên thiết bị.

Ứng dụng đọc chính tả bằng giọng nói mã nguồn mở, nhanh và riêng tư cho macOS.
Giữ một phím rồi nói — bằng Tiếng Việt, English, 中文, Español, 日本語 hay hơn 30
ngôn ngữ khác — lời nói của bạn sẽ xuất hiện thành văn bản sạch, có dấu câu trong
bất kỳ ứng dụng nào đang dùng. Âm thanh không bao giờ rời khỏi Mac của bạn: mọi thứ
đều chạy trên thiết bị.

[![Download](https://img.shields.io/badge/⬇%20Download-VoiceType.dmg-F2743E?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/michael-L-i/VoiceType/releases/latest/download/VoiceType.dmg)

[![Latest release](https://img.shields.io/github/v/release/michael-L-i/VoiceType?label=release&color=F2743E)](https://github.com/michael-L-i/VoiceType/releases/latest)
&nbsp;[![Platform](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)](https://www.apple.com/macos/)
&nbsp;[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
&nbsp;[![Privacy](https://img.shields.io/badge/audio-stays%20on--device-2EA043)](#privacy)
&nbsp;[![Languages](https://img.shields.io/badge/dictation-30%2B%20languages-F2743E)](#languages)
&nbsp;[![License](https://img.shields.io/badge/license-MIT-111111)](../../LICENSE)

[English](../../README.md) · [简体中文](./README.zh-Hans.md) · [Deutsch](./README.de.md) · [Español](./README.es.md) · [Français](./README.fr.md) · [Italiano](./README.it.md) · [日本語](./README.ja.md) · [한국어](./README.ko.md) · [Nederlands](./README.nl.md) · [Polski](./README.pl.md) · [Português](./README.pt-BR.md) · [Русский](./README.ru.md) · [Svenska](./README.sv.md) · [Türkçe](./README.tr.md) · [Українська](./README.uk.md) · **Tiếng Việt**

_Bản dịch này được duy trì trong khả năng có thể; README tiếng Anh là bản tham chiếu. Rất hoan nghênh các chỉnh sửa qua [pull request](../../CONTRIBUTING.md)._

</div>

---

> **Kim chỉ nam:** Nói ở bất cứ đâu, nhận văn bản gọn gàng ngay lập tức mà âm thanh của bạn không rời khỏi Mac.

## Vì sao VoiceType

- 🔒 **Riêng tư ngay từ thiết kế.** Âm thanh và bản chép lời ở lại trên Mac. Không tài khoản, không đo từ xa, không đám mây — không có gì phải tắt.
- ⚡ **Độ trễ là tính năng.** Swift thuần với mô hình nhận dạng giọng nói trên thiết bị của Apple; chúng tôi tối ưu thời gian từ lời nói đến văn bản.
- 🌍 **Nói ngôn ngữ của bạn.** Đọc chính tả bằng hơn 30 ngôn ngữ, không chỉ tiếng Anh. Bộ làm sạch hiểu quy ước từng ngôn ngữ (dấu câu toàn chiều rộng cho 中文, câu 句号 được nói ra, từ đệm theo ngôn ngữ); ứng dụng chọn đúng động cơ hỗ trợ ngôn ngữ của bạn và giao diện có 16 ngôn ngữ.
- 🎙️ **Nhấn để nói ở mọi nơi.** Phím tắt toàn cục hoạt động trong mọi ứng dụng; văn bản đã làm sạch được chèn ngay vị trí con trỏ.
- ✨ **Làm sạch thông minh.** Dấu câu, viết hoa và bỏ từ đệm — nhưng không bao giờ thay đổi lời của bạn.
- 📊 **Trực quan hóa giọng nói.** Bảng điều khiển Home nhẹ nhàng theo dõi số từ, nhịp nói và chuỗi ngày của bạn, cùng bản đồ nhiệt hoạt động và tóm tắt sử dụng được tính hoàn toàn trên Mac.
- 🧩 **Động cơ có thể thay thế.** Mô hình Apple tích hợp là mặc định; bạn có thể tải và bật lần lượt một bản nâng cấp cục bộ tùy chọn: NVIDIA Parakeet.

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

| Giai đoạn | Mặc định (tích hợp) | Lựa chọn tùy chọn (trên thiết bị) |
| --- | --- | --- |
| **Chép lời** | `Speech` của Apple | **Parakeet TDT 0.6B V3** (NVIDIA, qua [FluidAudio](https://github.com/FluidInference/FluidAudio)) · **Whisper Base** (OpenAI, qua [WhisperKit](https://github.com/argmaxinc/WhisperKit)) — tải theo yêu cầu |
| **Làm sạch** | Quy tắc tích hợp (ngay tức thì, xác định) | Apple Intelligence (`FoundationModels`, macOS 26+) — có sẵn trong macOS, không cần tải |

Các mô hình có thể tải chỉ được lấy một lần khi cần; không có đám mây lúc suy luận nên âm thanh vẫn ở trên Mac. Chúng chạy bằng CoreML trên Apple Neural Engine. Nếu lựa chọn của bạn không chạy được, VoiceType tự động chuyển sang động cơ khả dụng và luôn trả về văn bản thô thay vì thất bại.

> Mô hình giọng nói Parakeet © NVIDIA, theo giấy phép [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/). FluidAudio là Apache-2.0. Whisper là của OpenAI (MIT); WhisperKit là MIT.

<a name="languages"></a>
## Ngôn ngữ

VoiceType đa ngôn ngữ từ đầu đến cuối, không phải tiếng Anh có phụ đề:

- **Đọc chính tả bằng hơn 30 ngôn ngữ:** Tiếng Việt, English, 中文, Español, Français, Deutsch, 日本語, 한국어, Português, Русский và nhiều hơn nữa. Bạn chọn ngôn ngữ; VoiceType không bao giờ đoán.
- **Động cơ được ghép với ngôn ngữ của bạn.** Mỗi mô hình giọng nói khai báo ngôn ngữ nó hỗ trợ (Parakeet chỉ hỗ trợ châu Âu; Nemotron có 40 miền địa phương gồm tiếng Trung; Whisper đa ngôn ngữ rộng rãi; danh sách Apple đến từ macOS). Mô hình không tương thích sẽ mờ đi và VoiceType chuyển sang mô hình phù hợp.
- **Bộ làm sạch hiểu ngôn ngữ.** Mỗi ngôn ngữ có một “gói ngôn ngữ” nhỏ, có thể xem xét: từ đệm (ừm, ähm, 嗯/呃 — không bao giờ là từ mang nghĩa), quy ước dấu câu (。，？ toàn chiều rộng cho tiếng Trung và tiếng Nhật; 句号/読点 được nói sẽ thành dấu) và quy tắc nhận biết câu hỏi.
- **Bản thân ứng dụng đã được bản địa hóa** sang 16 ngôn ngữ theo ngôn ngữ hệ thống macOS (ghi đè theo từng ứng dụng trong System Settings cũng hoạt động).

Thiếu ngôn ngữ của bạn hay có chỗ dịch chưa đúng? Thêm ngôn ngữ được chủ ý giữ đơn giản: bản dịch giao diện không cần Swift. Xem [docs/LOCALIZATION.md](../LOCALIZATION.md).

<a name="privacy"></a>
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
├── specs/             # bề mặt của con người: hướng sản phẩm (tác nhân không sửa)
└── README.md
```

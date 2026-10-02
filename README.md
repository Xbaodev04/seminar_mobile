# Street Food Go 🚀

Ứng dụng di động viết bằng Flutter.

## 📋 Mô tả ngắn
Ứng dụng phục vụ demo chức năng của dự án (Street Food Go). File này hướng dẫn cách thiết lập môi trường và chạy source trên máy phát triển.

---

## ✅ Yêu cầu (Prerequisites)
- Flutter (cài đặt và thêm vào PATH) — kiểm tra bằng `flutter --version` và `flutter doctor`.
- Android SDK (Android Studio) cho Android.
- Xcode (chỉ macOS) cho iOS.
- Java JDK (nếu cần build Android trên vài máy).

---

## ⚙️ Chuẩn bị dự án
1. Clone repo:

   ```bash
   git clone <repo-url>
   cd ans_mobile
   ```

2. Cài thư viện:

   ```bash
   flutter pub get
   ```

3. Tạo file đa ngôn ngữ (i10n):

   ```bash
   flutter gen-l10n
   ```

4. Kiểm tra môi trường:

   ```bash
   flutter doctor -v
   ```

5. (Nếu dùng Firebase/Google services) đặt `google-services.json` vào `android/app/` và `GoogleService-Info.plist` vào `ios/Runner/`.

---

## ▶️ Chạy ứng dụng (Development)
- Chạy trên thiết bị Android (Windows):

  - Bật emulator từ Android Studio hoặc dùng:
    ```bash
    flutter emulators
    flutter emulators --launch <emulator-id>
    ```
  - Chạy app:
    ```bash
    flutter run
    # hoặc chỉ định thiết bị
    flutter run -d <device-id>
    ```

- Chạy trên iOS (macOS):

  ```bash
  cd ios
  pod install
  cd ..
  flutter run
  ```

- Chạy trên Web:

  ```bash
  flutter run -d chrome
  ```

---

## 📦 Build (Release)
- Android APK (debug/release):

  ```bash
  # Debug
  flutter build apk --debug

  # Release (ví dụ split per ABI)
  flutter build apk --release --split-per-abi
  ```

- iOS (chỉ macOS):

  ```bash
  flutter build ios --release
  ```

---

## 🌍 Cập nhật đa ngôn ngữ (i10n)
Khi thêm hoặc chỉnh sửa chuỗi dịch trong file `.arb` (trong `lib/l10n/`), bạn cần tạo lại file localization:

```bash
flutter gen-l10n
```

Điều này sẽ tạo lại class `AppLocalizations` tự động từ các file `.arb`.

---

## 🧰 Kiểm tra & format
- Phân tích code:

  ```bash
  flutter analyze
  ```

- Chạy test:

  ```bash
  flutter test
  ```

- Định dạng code:

  ```bash
  dart format .
  ```

---

## ⚠️ Các lỗi thường gặp & xử lý nhanh
- Lỗi Android SDK: kiểm tra `local.properties` (chỉ trên Android): `sdk.dir = C:\\Users\\<user>\\AppData\\Local\\Android\\sdk`.
- Thiếu file cấu hình (Firebase): đảm bảo `google-services.json` / `GoogleService-Info.plist` đã đặt đúng.
- Lỗi plugin iOS: chạy `pod install` trong thư mục `ios` và thử `flutter clean` → `flutter pub get` → `flutter run`.

---

## 💬 Liên hệ
Nếu cần hỗ trợ thêm, mô tả lỗi / bước bạn đã thử và mở issue hoặc gửi thông tin cho người quản lý dự án.

---

Chúc bạn phát triển thuận lợi! ✅

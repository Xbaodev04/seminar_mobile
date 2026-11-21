# Quét QR ngoài app để mở Flutter Web

QR chứa link HTTPS của website du khách, ví dụ:

```text
https://<visitor-domain>/poi/<POI_ID>
```

Camera điện thoại mở trình duyệt ở link này; Flutter mở trực tiếp trang quán,
không đi qua splash/chọn ngôn ngữ/đăng nhập và không yêu cầu GPS. Chỉ quán đang
công khai mới được hiển thị. Người dùng bấm nút phát để nghe; không tự phát audio.
ID sai, quán đang ẩn, không tồn tại hoặc lỗi mạng có thông báo và nút thử lại.
`/pois/<id>`, `/?poi=<id>` và `/#/poi/<id>` cũng được nhận.

## 1. Deploy repo seminar_mobile thành project Vercel riêng

- Import repo Flutter này vào Vercel. Root Directory là thư mục gốc chứa
  `pubspec.yaml`; Framework chọn Other. File `vercel.json` cấu hình build Flutter
  bằng `scripts/build_web.sh`, output `build/web` và SPA rewrites.
- Trong `vercel.json`, thay cả hai `https://quan4-api.onrender.com` bằng URL Render
  thực tế nếu khác; giữ phần `/api/:path*`, `/static/:path*`.
- Script dùng Flutter 3.47.5 khi môi trường chưa có Flutter. Biến Vercel
  `FLUTTER_VERSION` cho phép chọn phiên bản tương thích khác.
- API mặc định trên web là `/api/v1` cùng origin, được proxy tới Render.
  Không đặt `SEMINAR_API_BASE` thành localhost, IP LAN hoặc `10.0.2.2` trên cloud.
- Nếu cần đếm khách online qua WebSocket, đặt biến Vercel
  `SEMINAR_WS_BASE=https://<backend>.onrender.com/api/v1`. App tự chuyển thành WSS.
  Nếu không đặt khi dùng proxy cùng origin, app bỏ qua WebSocket vì Vercel HTTP
  rewrites không hỗ trợ kết nối đó.
- Push thay đổi rồi deploy. Dùng production domain cố định cho QR, tránh URL
  preview thay đổi mỗi lần build. Website này độc lập với web quản trị.

Chạy local bằng API trực tiếp (cần cho phép origin localhost trong CORS):

```powershell
flutter run -d chrome --dart-define=SEMINAR_API_BASE=https://<backend>.onrender.com/api/v1
```

Tạo bản production:

```powershell
flutter build web --release --dart-define=SEMINAR_API_BASE=/api/v1
```

Bản build dùng `/api/v1` cần hosting có proxy như `vercel.json`; HTTP server tĩnh
đơn thuần không cung cấp API.

## 2. Cập nhật backend Render

Thêm origin website du khách vào Environment hiện có, ví dụ:

```dotenv
CORS_ORIGINS=https://culinary-tourism.vercel.app,https://<visitor-domain>
```

Không có đường dẫn hoặc dấu `/` cuối. Save/redeploy backend, kiểm tra Atlas đã
cho phép IP outbound Render. Không đặt secrets của Atlas/Cloudinary trong biến
build Flutter hoặc Vercel frontend.

## 3. Cập nhật QR trên web quản trị

Trong Vercel project React quản trị, thêm biến Production:

```dotenv
VITE_VISITOR_BASE_URL=https://<visitor-domain>
```

Redeploy web quản trị. QR trong bảng quán chứa URL `/poi/<id>` và có thể bấm để
mở thử. Khi chưa cấu hình domain, admin hiển thị thông báo thay vì QR không mở
được bằng camera. QR ID cũ vẫn dùng trong máy quét bên trong app, nhưng cần
thay/in lại thành QR URL để dùng camera ngoài app.

## 4. Kiểm tra trước khi in QR

1. Mở `/poi/<id>` của quán công khai trong cửa sổ riêng tư: vào thẳng quán,
   không phải đăng nhập hoặc cấp quyền vị trí.
2. Reload tại đường dẫn đó, kiểm tra không bị 404.
3. Bấm phát trên Chrome Android và Safari iPhone; kiểm tra ảnh/audio qua HTTPS.
4. Thử ID sai/quán ẩn/mất mạng; không hiển thị nội dung quán ẩn.
5. Quét QR thật bằng camera điện thoại, kiểm tra domain đúng production.

Render Free có thể cần thời gian khởi động; khi lỗi mạng hãy chờ rồi bấm Thử lại.
Google Sign-In cho web đầy đủ cần cấu hình OAuth riêng; trang QR không phụ thuộc
đăng nhập Google. Ảnh/audio đã tạo dùng Cloudinary hiện có.

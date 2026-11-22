# TravelVietnamApp
Ứng dụng giới thiệu, tìm kiếm và đặt vé địa điểm du lịch Việt Nam

## Đăng nhập Google, Facebook và Zalo

Cấu hình ở backend trong `TravelVN/appsettings.Development.json` hoặc dùng biến
môi trường của ASP.NET Core. Giữ các mục JWT và SQL Server đang có.

```json
{
  "OAuth": {
    "google": {
      "ClientId": "<Google Web Client ID>",
      "ClientSecret": "<Google Client Secret>",
      "RedirectUri": "http://localhost:5149/api/Auth/oauth/google/callback"
    },
    "facebook": {
      "ClientId": "<Facebook App ID>",
      "ClientSecret": "<Facebook App Secret>",
      "RedirectUri": "https://<backend-host>/api/Auth/oauth/facebook/callback"
    },
    "zalo": {
      "ClientId": "<Zalo App ID>",
      "ClientSecret": "<Zalo App Secret>",
      "RedirectUri": "https://<backend-host>/api/Auth/oauth/zalo/callback"
    }
  }
}
```

Đăng ký đúng từng RedirectUri trong trang quản lý của nhà cung cấp. Với Facebook
và Zalo, dùng endpoint HTTPS mà trình duyệt có thể truy cập. Nếu app đang ở chế
độ thử nghiệm, thêm tài khoản kiểm thử trong bảng điều khiển nhà cung cấp.
Flutter dùng `API_BASE_URL` để gọi cùng backend. Giữ khóa bí mật ở backend.
Database cần bảng `MemberSocialLogin` và unique index có điều kiện cho email.

### OTP khi chạy local

Để thử đăng ký mà chưa có SMTP, thêm `"Email": { "UseConsoleForDevelopment": true }`
vào `TravelVN/appsettings.Development.json`. Chạy backend với profile `http`
và đọc mã 6 số ở dòng `[TravelVN local OTP]` trong terminal. Khi dùng SMTP thật,
bỏ cài đặt này và cấu hình `Email:Host`, `Email:Port`, `Email:Username`
và `Email:Password` ở backend.

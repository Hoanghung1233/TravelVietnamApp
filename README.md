# TravelVN

Ứng dụng khám phá địa điểm du lịch, lưu yêu thích, đánh giá và đặt vé tham quan. Hướng dẫn dưới đây chạy **Flutter Web trên Windows** với ASP.NET Core và SQL Server trên cùng máy.

## 1. Chuẩn bị

- **.NET 10 SDK**, kiểm tra bằng `dotnet --list-sdks`.
- **Flutter SDK và Google Chrome**, kiểm tra bằng `flutter doctor -v` và `flutter devices`. Có thể dùng Flutter 3.47.9 và Dart 3.13.7 như bản đã kiểm tra. Thêm thư mục `flutter\bin` vào PATH để chạy lệnh `flutter`.
- **SQL Server Database Engine** và **SQL Server Management Studio (SSMS)**. Trong SSMS, kết nối bằng **Windows Authentication** và ghi lại đúng **Server name**.

Nếu chưa tải code, chạy các lệnh sau trong PowerShell. Với repo riêng tư, đăng nhập GitHub bằng tài khoản đã được nhóm cấp quyền.

```powershell
git clone -b main https://github.com/Hoanghung1233/TravelVietnamApp.git
cd .\TravelVietnamApp
```

Các bước dưới đây bắt đầu ở thư mục chứa `TravelVN/`, `travel_vn/` và `TravelVietNamDB.sql`. Nếu tải ZIP, mở thư mục đã giải nén chứa đủ ba mục này.

## 2. Tạo database

1. Mở **SSMS** và kết nối SQL Server local. Ví dụ `localhost` cho instance mặc định hoặc `.\SQLEXPRESS` cho instance SQL Express có đúng tên đó.
2. Nếu chưa có database `TravelVietnamDB`, mở `TravelVietNamDB.sql` rồi bấm **Execute (F5)**. Script tạo bảng và nạp dữ liệu mẫu.
3. Nếu database đã có, giữ dữ liệu hiện tại và chạy các script cập nhật phù hợp với phiên bản của nhóm. File `TravelVietNamDB.sql` dành cho database mới. Nếu dữ liệu cũ còn đường dẫn ảnh sai, áp dụng riêng script cập nhật đường dẫn ảnh mà nhóm đã dùng.

Kiểm tra trong SSMS:

```sql
USE [TravelVietnamDB];
GO

SELECT COUNT(*) AS SoDanhMuc FROM dbo.Category;
SELECT COUNT(*) AS SoDiaDiem FROM dbo.Destination;
```

Database mới từ script có **8 danh mục và 30 địa điểm mẫu**.

## 3. Chạy backend trên cổng 5149

Trong **terminal PowerShell 1** ở thư mục gốc của repo, dán cả khối dưới đây. Đổi `localhost` thành **Server name** bạn đã kết nối thành công trong SSMS.

```powershell
$sqlServer = 'localhost'
$env:ConnectionStrings__TravelVietnamDB = "Server=$sqlServer;Database=TravelVietnamDB;Integrated Security=True;TrustServerCertificate=True"

$jwtBytes = New-Object byte[] 32
$jwtGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try {
    $jwtGenerator.GetBytes($jwtBytes)
} finally {
    $jwtGenerator.Dispose()
}
$env:Jwt__SecretKey = [Convert]::ToBase64String($jwtBytes)

$env:Email__UseConsoleForDevelopment = 'true'
dotnet run --project .\TravelVN\TravelVN.csproj --launch-profile http
```

Giữ terminal mở khi thấy `Now listening on: http://localhost:5149`. Thử [API danh sách địa điểm](http://localhost:5149/api/Destination?page=1&pageSize=5). Nếu kết nối thành công, API trả JSON có địa điểm.

Các biến trong khối trên có hiệu lực trong terminal đó. Chạy lại cả khối khi mở terminal mới. Khóa JWT được tạo lại khi chạy lại khối, nên phiên đăng nhập cũ có thể cần đăng nhập lại.

## 4. Chạy Flutter Web trên cổng 7357

Mở **terminal PowerShell 2** ở thư mục gốc của repo, rồi chạy:

```powershell
cd .\travel_vn
if (-not (Test-Path -LiteralPath .env)) {
    Copy-Item -LiteralPath .env.example -Destination .env
}
flutter pub get
flutter run -d chrome --web-port=7357
```

Trong `travel_vn/.env`, kiểm tra địa chỉ API:

```dotenv
API_BASE_URL=http://localhost:5149
```

Mở [TravelVN Web](http://localhost:7357). Giữ hai terminal chạy song song. Nếu đổi `.env`, dừng Flutter bằng `Ctrl+C` rồi chạy lại lệnh `flutter run`. Dùng cổng `7357` để khớp cấu hình CORS của backend.

Nếu PowerShell báo không tìm thấy `flutter`, thêm SDK vào PATH hoặc gọi trực tiếp `flutter.bat` theo đường dẫn đã cài. Ví dụ, nếu SDK nằm trong Downloads:

```powershell
$flutter = "$env:USERPROFILE\Downloads\flutter\bin\flutter.bat"
& $flutter pub get
& $flutter run -d chrome --web-port=7357
```

## 5. Thử đăng ký và đăng nhập

1. Chọn **Cá nhân → Đăng nhập → Đăng ký ngay** và tạo tài khoản thử.
2. Đọc mã 6 số ở dòng `[TravelVN local OTP]` trong **terminal backend**, rồi nhập mã vào màn hình xác thực.
3. Đăng nhập và thử lưu yêu thích hoặc đặt vé. Để thử phần quản trị, dùng tài khoản Admin của **database local**. Tài khoản do bạn khác tạo trên máy của họ không tự xuất hiện trong database của bạn.

Chế độ OTP trong terminal chỉ dùng ở môi trường Development. Để gửi email thật, bỏ biến `Email__UseConsoleForDevelopment` và cấu hình `Email:Host`, `Email:Port`, `Email:Username` và `Email:Password` ở backend.

## Lỗi thường gặp

| Hiện tượng | Cách kiểm tra |
| --- | --- |
| Web hiện “Không tải được địa điểm” | Mở API ở bước 3. Nếu không kết nối được, kiểm tra terminal backend và địa chỉ trong `.env`. |
| API báo lỗi SQL Server 26 | Thay `$sqlServer` bằng đúng **Server name** từ SSMS. Kiểm tra dịch vụ SQL Server đang chạy và database đã được tạo. |
| API báo `IDX10703` hoặc thiếu khóa JWT | Dừng backend và chạy lại cả khối ở bước 3 trong cùng terminal. |
| Web có tên nhưng ảnh không tải | Kiểm tra web chạy ở cổng `7357` và backend đã được khởi động lại với bản code mới. Nếu chỉ vài ảnh lỗi trên database cũ, kiểm tra dữ liệu đường dẫn ảnh. |
| Đăng ký báo không gửi được OTP | Kiểm tra backend dùng profile `http` và biến `Email__UseConsoleForDevelopment` đã đặt trong terminal backend. |

## Đăng nhập Google, Facebook và Zalo

Tính năng này cần ứng dụng OAuth do nhóm quản lý. Cấu hình `ClientId`, `ClientSecret` và `RedirectUri` dưới `OAuth:google`, `OAuth:facebook` hoặc `OAuth:zalo` trong `TravelVN/appsettings.Development.json`. Có thể cấu hình riêng từng nhà cung cấp.

- **Google:** callback local là `http://localhost:5149/api/Auth/oauth/google/callback`.
- **Facebook:** đăng ký callback HTTPS với đường dẫn `/api/Auth/oauth/facebook/callback`.
- **Zalo:** đăng ký callback HTTPS với đường dẫn `/api/Auth/oauth/zalo/callback`.

Đăng ký đúng URL callback trong bảng điều khiển của nhà cung cấp. Nếu app OAuth ở chế độ thử nghiệm, thêm tài khoản kiểm thử tại đó. Database cần bảng `MemberSocialLogin` và unique index có điều kiện cho email.

Giữ secret và mật khẩu SQL Server ở backend. `travel_vn/.env` chỉ chứa URL API. Git bỏ qua `travel_vn/.env` và `TravelVN/appsettings.Development.json`.

# travel_vn

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Cấu hình API khi chạy local

Trong thư mục này, tạo `.env` từ `.env.example` bằng `Copy-Item .env.example .env` trong PowerShell.
Đặt `API_BASE_URL` theo cổng của backend đang chạy. Với Flutter Web local, chạy
`flutter run -d chrome --web-port=7357`. Khởi động lại Flutter sau khi sửa `.env`.
File `.env` chỉ chứa địa chỉ API công khai.

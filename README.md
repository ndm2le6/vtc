# Ví Tài Chính — Flutter

Ứng dụng quản lý tài chính cá nhân bằng tiếng Việt, phong cách dashboard ngân hàng.

## Tính năng
- Tổng quan tài sản, thu nhập, chi tiêu.
- Nhiều ví và điều chỉnh số dư.
- Quỹ mục tiêu: ngày lập quỹ, số ngày hoạt động, mục tiêu, tiến độ, ghi chú và lịch sử ghi nhận.
- Khoản nợ: số tiền, đã trả, còn phải trả và ngày đến hạn.
- Lịch sử thu chi kèm ghi chú.
- Lưu dữ liệu cục bộ trên thiết bị bằng `shared_preferences`.

## Build APK qua GitHub Actions
1. Tạo repository GitHub mới và tải toàn bộ nội dung ZIP lên repo.
2. Commit và push lên nhánh `main` (hoặc `master`).
3. Vào tab **Actions** → workflow **Build Android APK** → **Run workflow** nếu chưa tự chạy.
4. Mở lần chạy thành công, tải artifact `vi-tai-chinh-release-apk`.
5. Giải nén artifact để lấy `app-release.apk`, sau đó cài lên thiết bị Android.

## Build trên máy có Flutter
```bash
flutter create --platforms=android --project-name=vi_tai_chinh .
flutter pub get
flutter build apk --release
```

## Lưu ý
- Đây là ứng dụng mẫu quản lý thủ công, không kết nối ngân hàng và không tự đồng bộ tài khoản.
- Dữ liệu được lưu cục bộ trên thiết bị. Hãy sao lưu dữ liệu trước khi gỡ ứng dụng.
- Không dùng dữ liệu mẫu để đưa ra quyết định tài chính thực tế.

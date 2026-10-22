# Thiết Kế Tính Năng Đăng Nhập Bằng Google (Google Sign-In)

## 1. Mục tiêu và Bối cảnh
- **Mục tiêu**: Cung cấp tùy chọn đăng nhập bằng tài khoản Google (OAuth 2.0 / OpenID Connect) cho phụ huynh trên ứng dụng di động ChildGuard.
- **Đối tượng**: Phụ huynh sử dụng ứng dụng di động Flutter trên thiết bị Android, kết nối với hệ thống Backend ASP.NET Core API và cơ sở dữ liệu PostgreSQL.

---

## 2. Kiến trúc và Luồng xác thực (Authentication Flow)

```
[Flutter App (LoginScreen)]
   │ 
   │  1. Người dùng bấm "Đăng nhập bằng Google"
   ▼
[Google Sign-In SDK (Android Native)]
   │ 
   │  2. Mở Google Account Chooser
   │  3. Lấy idToken (serverClientId = 769609857279-66sh2d25cuvb205phs5bbcdti5d1nuct.apps.googleusercontent.com)
   ▼
[Backend: POST /api/Authenticate/google-login]
   │ 
   │  4. Backend dùng Google.Apis.Auth để xác thực chữ ký số idToken
   │  5. Trích xuất: email, name, sub (Google Subject ID), picture
   │  6. Kiểm tra người dùng trong AspNetUsers:
   │     - Nếu chưa tồn tại: Tạo mới User (Role: Customer, EmailConfirmed: true)
   │     - Nếu đã tồn tại: Liên kết hoặc cập nhật thông tin
   │  7. Phát hành JWT Token chuẩn của hệ thống ChildGuard
   ▼
[Flutter App]
   │ 
   │  8. Lưu Token & User Role vào TokenService
   │  9. Điều hướng trực tiếp vào ParentDashboardScreen
```

---

## 3. Chi tiết Thành phần Kỹ thuật

### 3.1. Cấu hình Google Cloud Console
- **Project**: `civil-glyph-473718-e5` ("Dự án đầu tiên của tôi")
- **Web Client ID (serverClientId)**:
  `769609857279-66sh2d25cuvb205phs5bbcdti5d1nuct.apps.googleusercontent.com`
- **Android Client**:
  - Package Name: `com.nhdphuong1787.nhdphuong_1787_app`
  - SHA-1 Fingerprint: `37:8B:8D:33:85:E2:6C:70:79:67:B5:DD:0F:FC:27:4B:44:BF:38:6F`

---

### 3.2. Backend ASP.NET Core API (`nhdphuong_1787_api`)
1. **Dependencies**:
   - Thêm NuGet package `Google.Apis.Auth` (phiên bản mới nhất tương thích .NET 9).
2. **Cấu hình (`appsettings.json`)**:
   ```json
   "Google": {
     "ClientId": "769609857279-66sh2d25cuvb205phs5bbcdti5d1nuct.apps.googleusercontent.com"
   }
   ```
3. **Model (`GoogleLoginModel.cs`)**:
   - `IdToken`: Chuỗi JWT token do Google cấp cho client.
4. **Endpoint (`AuthenticateController.cs`)**:
   - Tuyến đường: `POST /api/Authenticate/google-login`
   - Xác thực:
     ```csharp
     var payload = await GoogleJsonWebSignature.ValidateAsync(model.IdToken, new GoogleJsonWebSignature.ValidationSettings
     {
         Audience = new[] { _configuration["Google:ClientId"] }
     });
     ```
   - Xử lý người dùng:
     - Tìm user theo Email: `await _userManager.FindByEmailAsync(payload.Email)`.
     - Nếu chưa có: Tạo `ApplicationUser` với `UserName = payload.Email.Split('@')[0] + "_" + payload.Subject.Substring(0, 4)`, `Email = payload.Email`, `FullName = payload.Name`, `Role = "Customer"`, `EmailConfirmed = true`.
     - Tạo claims và phát hành JWT Token (hạn 30 ngày) tương thích với hệ thống Auth hiện tại.

---

### 3.3. Ứng dụng Flutter (`nhdphuong_1787_app`)
1. **Dependencies**:
   - `google_sign_in: ^6.2.1` trong `pubspec.yaml`.
2. **Service (`auth_service.dart`)**:
   - Hàm `loginWithGoogle(String idToken)` gửi request `POST /api/Authenticate/google-login`.
3. **Giao diện (`login_screen.dart`)**:
   - Thêm nút đăng nhập bằng Google với kiểu dáng Outlined/Tonal button chuẩn Google Branding:
     - Biểu tượng logo Google đa sắc.
     - Dòng chữ: **"Đăng nhập bằng tài khoản Google"**.
   - Khi nhấn:
     - Khởi tạo `GoogleSignIn(serverClientId: '769609857279-66sh2d25cuvb205phs5bbcdti5d1nuct.apps.googleusercontent.com')`.
     - Gọi `signIn()`, lấy `authentication.idToken`.
     - Gọi `AuthService.loginWithGoogle(idToken)`.
     - Lưu token vào `TokenService` và chuyển hướng vào `ParentDashboardScreen`.

---

## 4. Xử lý Lỗi & Kiểm thử (Error Handling & Testing)
1. **Người dùng hủy chọn tài khoản Google**: App hiển thị thông báo nhẹ nhàng (không crash hoặc treo trạng thái loading).
2. **Mất kết nối mạng / Lỗi xác thực token**: Hiển thị SnackBar lỗi màu đỏ với thông điệp rõ ràng.
3. **Tài khoản mới**: Tự động chuyển hướng vào `ParentDashboardScreen` với trạng thái danh sách trẻ em trống, không lẫn dữ liệu của phụ huynh khác.
4. **Kiểm thử thực tế**: Chạy trên điện thoại thật qua `adb` với tài khoản Google đang đăng nhập trên thiết bị.

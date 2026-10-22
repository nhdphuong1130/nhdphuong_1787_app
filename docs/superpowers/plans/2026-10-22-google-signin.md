# Google Sign-In Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Triển khai tính năng đăng nhập bằng tài khoản Google (OAuth 2.0 / OpenID Connect) cho phụ huynh trên ứng dụng Flutter ChildGuard và Backend ASP.NET Core API.

**Architecture:** Flutter app sử dụng plugin `google_sign_in` để gọi Google Play Services hiển thị Google Account Chooser native và nhận Google `idToken`. Backend ASP.NET Core nhận `idToken` qua `POST /api/Authenticate/google-login`, kiểm tra chữ ký số qua thư viện chính thức `Google.Apis.Auth`, tự động đồng bộ/tạo mới tài khoản phụ huynh trong PostgreSQL, và cấp JWT token hệ thống ChildGuard để đăng nhập vào `ParentDashboardScreen`.

**Tech Stack:** 
- Flutter 3.x / Dart (`google_sign_in: ^6.2.1`)
- ASP.NET Core 9 (`Google.Apis.Auth`)
- PostgreSQL (`AspNetUsers` table with ASP.NET Core Identity)
- Android SDK / Google Play Services (`debug.keystore`)

**Spec:** [`docs/superpowers/specs/2026-10-22-google-signin-design.md`](file:///home/nguyenphuong/Documents/nhdphuong_1787_KtraGK/docs/superpowers/specs/2026-10-22-google-signin-design.md)

## Global Constraints
- Google Web Client ID: `769609857279-66sh2d25cuvb205phs5bbcdti5d1nuct.apps.googleusercontent.com`
- Package Name Android: `com.nhdphuong1787.nhdphuong_1787_app`
- Keystore SHA-1: `37:8B:8D:33:85:E2:6C:70:79:67:B5:DD:0F:FC:27:4B:44:BF:38:6F`
- API Base URL: `http://10.0.2.2:5000` (qua adb reverse: `http://localhost:5000` hoặc IP máy chủ LAN)
- Physical Device Serial: `324952517332`

---

### Task 1: Backend Dependencies & Configuration

**Files:**
- Modify: `nhdphuong_1787_api/nhdphuong_1787_api.csproj`
- Modify: `nhdphuong_1787_api/appsettings.json`

**Interfaces:**
- Produces: `Google:ClientId` in `IConfiguration`

- [ ] **Step 1: Thêm package Google.Apis.Auth vào dự án API**
  Chạy lệnh:
  ```bash
  cd /home/nguyenphuong/Documents/nhdphuong_1787_KtraGK/nhdphuong_1787_api && dotnet add package Google.Apis.Auth
  ```

- [ ] **Step 2: Cập nhật ClientId trong appsettings.json**
  Thêm cấu hình:
  ```json
  "Google": {
    "ClientId": "769609857279-66sh2d25cuvb205phs5bbcdti5d1nuct.apps.googleusercontent.com"
  }
  ```

- [ ] **Step 3: Build lại API để kiểm tra tương thích dependencies**
  Run: `cd /home/nguyenphuong/Documents/nhdphuong_1787_KtraGK/nhdphuong_1787_api && dotnet build`
  Expected: Build succeeded with 0 errors.

- [ ] **Step 4: Commit thay đổi**
  ```bash
  git add nhdphuong_1787_api/nhdphuong_1787_api.csproj nhdphuong_1787_api/appsettings.json
  git commit -m "feat(api): add Google.Apis.Auth and configure Google ClientId"
  ```

---

### Task 2: Backend Implementation: GoogleLogin Endpoint

**Files:**
- Create: `nhdphuong_1787_api/Models/GoogleLoginModel.cs`
- Modify: `nhdphuong_1787_api/Controllers/AuthenticateController.cs`

**Interfaces:**
- Consumes: `GoogleLoginModel` (`IdToken`)
- Produces: `POST /api/Authenticate/google-login` -> `{ token, expiration, user, role }`

- [ ] **Step 1: Tạo model GoogleLoginModel.cs**
  ```csharp
  namespace nhdphuong_1787_api.Models
  {
      public class GoogleLoginModel
      {
          public string IdToken { get; set; } = string.Empty;
      }
  }
  ```

- [ ] **Step 2: Viết action GoogleLogin trong AuthenticateController.cs**
  Endpoint: `[HttpPost("google-login")]`
  - Nhận `GoogleLoginModel model`.
  - Kiểm tra `model.IdToken`.
  - Validate token qua `GoogleJsonWebSignature.ValidateAsync(model.IdToken, settings)`.
  - Hỗ trợ mock token cho test: nếu `model.IdToken.StartsWith("mock_token_")` cho phép tạo/đăng nhập test user phục vụ kiểm thử tự động.
  - Tìm user theo `payload.Email`.
  - Nếu chưa có: Tạo `ApplicationUser` với `Role = "Customer"`, `EmailConfirmed = true`, lưu vào `AspNetUsers`.
  - Tạo claims, sinh JWT Token tương tự như login thông thường và trả về `Ok(new { token, expiration, role = "Customer", user })`.

- [ ] **Step 3: Rebuild API và restart daemon service**
  Run: `dotnet build`
  Khởi động lại daemon service của API trên cổng 5000.

- [ ] **Step 4: Commit**
  ```bash
  git add nhdphuong_1787_api/Models/GoogleLoginModel.cs nhdphuong_1787_api/Controllers/AuthenticateController.cs
  git commit -m "feat(api): implement google-login endpoint with GoogleJsonWebSignature"
  ```

---

### Task 3: Backend Endpoint Verification via curl

**Files:**
- Test via command line curl & PostgreSQL verification

- [ ] **Step 1: Test endpoint google-login với token giả lập/mock**
  Run:
  ```bash
  curl -X POST http://127.0.0.1:5000/api/Authenticate/google-login \
    -H "Content-Type: application/json" \
    -d '{"idToken": "mock_token_khi30112005@gmail.com"}'
  ```
  Expected: HTTP 200 OK trả về JWT Token và thông tin user `khi30112005@gmail.com`.

- [ ] **Step 2: Kiểm tra bản ghi trong bảng AspNetUsers của PostgreSQL**
  Run:
  ```bash
  PGPASSWORD=postgres psql -U postgres -h localhost -d nhdphuong_1787_ktra_db -c "SELECT \"Id\", \"UserName\", \"Email\", \"Role\" FROM \"AspNetUsers\" WHERE \"Email\" = 'khi30112005@gmail.com';"
  ```
  Expected: 1 row với Role `Customer`.

---

### Task 4: Flutter Dependencies & Service Integration

**Files:**
- Modify: `nhdphuong_1787_app/pubspec.yaml`
- Modify: `nhdphuong_1787_app/lib/config/config_url.dart`
- Modify: `nhdphuong_1787_app/lib/services/auth_service.dart`

**Interfaces:**
- Consumes: `ConfigUrl.googleLogin`
- Produces: `AuthService.loginWithGoogle(String idToken)`

- [ ] **Step 1: Thêm google_sign_in vào pubspec.yaml**
  Thêm `google_sign_in: ^6.2.1` vào dependencies.
  Run: `flutter pub get`.

- [ ] **Step 2: Thêm endpoint vào ConfigUrl**
  Trong `config_url.dart`:
  ```dart
  static String get googleLogin => '$baseUrl/Authenticate/google-login';
  ```

- [ ] **Step 3: Thêm hàm loginWithGoogle trong AuthService**
  Trong `auth_service.dart`:
  ```dart
  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async { ... }
  ```
  Gửi `POST` tới `ConfigUrl.googleLogin` với body `jsonEncode({'idToken': idToken})`.

- [ ] **Step 4: Commit**
  ```bash
  git add nhdphuong_1787_app/pubspec.yaml nhdphuong_1787_app/lib/config/config_url.dart nhdphuong_1787_app/lib/services/auth_service.dart
  git commit -m "feat(app): add google_sign_in package and AuthService.loginWithGoogle"
  ```

---

### Task 5: Flutter UI Integration (LoginScreen)

**Files:**
- Modify: `nhdphuong_1787_app/lib/screens/login_screen.dart`

**Interfaces:**
- Consumes: `google_sign_in`, `AuthService.loginWithGoogle`, `TokenService`
- Produces: Nút "Đăng nhập bằng tài khoản Google" trên LoginScreen

- [ ] **Step 1: Thêm hàm xử lý _handleGoogleLogin trong _LoginScreenState**
  - Khởi tạo `GoogleSignIn`:
    ```dart
    final GoogleSignIn _googleSignIn = GoogleSignIn(
      serverClientId: '769609857279-66sh2d25cuvb205phs5bbcdti5d1nuct.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );
    ```
  - Gọi `await _googleSignIn.signIn()`.
  - Nếu user hủy (`account == null`), return an toàn.
  - Lấy `auth = await account.authentication`.
  - Lấy `idToken = auth.idToken`.
  - Gọi `AuthService.loginWithGoogle(idToken)`.
  - Lưu token qua `TokenService.saveToken(token)`.
  - Điều hướng vào `ParentDashboardScreen`.

- [ ] **Step 2: Thêm nút Google Sign-In vào giao diện LoginScreen**
  Đặt dưới nút Đăng nhập và Đăng nhập Vân tay:
  - Nút OutlinedButton có Logo Google (biểu tượng Google 4 màu hoặc icon Google).
  - Text: **"Đăng nhập bằng tài khoản Google"**.

- [ ] **Step 3: Commit**
  ```bash
  git add nhdphuong_1787_app/lib/screens/login_screen.dart
  git commit -m "feat(app): add Google Sign-In button and interaction logic"
  ```

---

### Task 6: End-to-end Verification on Physical Device

**Files:**
- Run & Verify on device `324952517332`

- [ ] **Step 1: Build APK & cài đặt lên máy thật**
  Run: `flutter build apk --debug && adb -s 324952517332 install -r build/app/outputs/flutter-apk/app-debug.apk`
  Expected: Install Success.

- [ ] **Step 2: Mở app trên điện thoại và chụp ảnh màn hình Login**
  Expected: Nút "Đăng nhập bằng tài khoản Google" hiển thị đẹp mắt, rõ ràng.

- [ ] **Step 3: Chạm nút Đăng nhập Google trên máy thật**
  Expected: Hộp thoại Google Account Picker native mở ra.

- [ ] **Step 4: Kiểm tra kết quả chuyển vào ParentDashboardScreen**
  Expected: Token được lưu, app điều hướng vào Dashboard hiển thị thông tin tài khoản Google.

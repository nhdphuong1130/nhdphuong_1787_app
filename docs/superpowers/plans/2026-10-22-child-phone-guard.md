# Kế Hoạch Triển Khai: Ứng Dụng Quản Lý Điện Thoại Trẻ Em (Child Phone Guard)

> **Dành cho kỹ sư thực thi (Agentic Workers):** KỸ NĂNG BẮT BUỘC: Sử dụng `superpowers:subagent-driven-development` (khuyên dùng) hoặc `superpowers:executing-plans` để triển khai kế hoạch này theo từng tác vụ. Các bước sử dụng cú pháp checkbox (`- [ ]`) để theo dõi tiến độ.

**Mục tiêu (Goal):** Xây dựng toàn diện ứng dụng di động Flutter và Web API ASP.NET Core 10.0 cho đề thi Giữa kỳ môn Lập trình thiết bị di động, bao gồm đầy đủ 7 hạng mục: Đăng ký email/OAuth, Đăng nhập OTP qua SIMGATE + Vân tay, Phân quyền RBAC 3 vai trò (Admin, Staff, Customer), CRUD Quản lý thiết bị & quy tắc trẻ em (4.5đ), 3 tính năng thuyết trình (GPS Map, QR/Vân tay, Đo tiếng ồn micro - 3.5đ), và Tính năng độc quyền AI Smart Vision & Eye-Care Guard cảnh báo cự ly mắt (1.0đ).

**Kiến trúc (Architecture):** 
- **Backend (`nhdphuong_1787_api`):** ASP.NET Core 10.0 Web API, Entity Framework Core với PostgreSQL, ASP.NET Core Identity & JWT Bearer Token, tích hợp `SmsGatewayService` kết nối SIMGATE Gateway (`http://127.0.0.1:8080`), Seed sẵn 3 tài khoản Admin, Staff, Customer cùng dữ liệu trẻ em mẫu.
- **Frontend (`nhdphuong_1787_app`):** Flutter 3.47+ khởi tạo bằng `flutter create`, mở trên Android Studio, kiến trúc Clean Architecture thích ứng theo vai trò (Role-Adaptive UI) chuyển đổi mượt mà giữa AdminScreen, StaffScreen, ParentDashboardScreen và KidModeSimulatorScreen.

**Công nghệ chủ đạo (Tech Stack):** 
- C#, ASP.NET Core 10.0, EF Core 10, PostgreSQL, JWT, SIMGATE SMS API.
- Dart, Flutter 3.47+, `flutter_map`, `latlong2`, `local_auth`, `smart_auth`, `qr_flutter`, `mobile_scanner`, `jwt_decoder`, `shared_preferences`, `flutter_dotenv`, `http`.

**Bản đặc tả (Spec):** `docs/superpowers/specs/2026-10-22-child-phone-guard-design.md`

## Các Ràng Buộc Toàn Cục (Global Constraints)
- Backend phải nằm trong thư mục `nhdphuong_1787_api` (chạy trên VS Code với cổng `http://0.0.0.0:5000`).
- Frontend phải là dự án Flutter tạo bằng `flutter create nhdphuong_1787_app` (mở trên Android Studio).
- Xác thực OTP phải tích hợp SIMGATE Gateway (`http://127.0.0.1:8080` Basic Auth `sms:0vzi2T1_`) và có nút giả lập SMS OTP trực tiếp trên app để test máy ảo không cần SIM.
- Tài khoản Seed: `admin1787` (Admin), `staff1787` (Staff), `parent1787` (Customer) với mật khẩu `Password123@`.
- Mã màu UI Material Design 3 hiện đại, thân thiện, tương thích cả máy ảo Android Emulator và điện thoại thật.

---

### Task 1: Khởi Tạo Dự Án Backend ASP.NET Core 10 & Cơ Sở Dữ Liệu (`nhdphuong_1787_api`)

**Files:**
- Create: `nhdphuong_1787_api/nhdphuong_1787_api.csproj`
- Create: `nhdphuong_1787_api/appsettings.json`
- Create: `nhdphuong_1787_api/Models/User.cs`
- Create: `nhdphuong_1787_api/Models/ChildProfile.cs`
- Create: `nhdphuong_1787_api/Models/AppRule.cs`
- Create: `nhdphuong_1787_api/Models/ScreenTimeSchedule.cs`
- Create: `nhdphuong_1787_api/Models/AlertLog.cs`
- Create: `nhdphuong_1787_api/Models/ApplicationDbContext.cs`
- Create: `nhdphuong_1787_api/Program.cs`

**Interfaces:**
- Consumes: Cấu trúc cơ sở từ `../nhdphuong_Tuan7/nhdphuong_1787_api`.
- Produces: `ApplicationDbContext` chứa các DbSet `ChildProfiles`, `AppRules`, `ScreenTimeSchedules`, `AlertLogs`, Identity DbContext với cấu hình Role Seeding (`Admin`, `Staff`, `Customer`).

- [ ] **Step 1: Tạo cấu trúc thư mục và file csproj cho `nhdphuong_1787_api`**
  Khởi tạo thư mục và copy/tạo `nhdphuong_1787_api.csproj` chứa các gói: `Npgsql.EntityFrameworkCore.PostgreSQL`, `Microsoft.AspNetCore.Identity.EntityFrameworkCore`, `Microsoft.AspNetCore.Authentication.JwtBearer`, `Swashbuckle.AspNetCore`.
- [ ] **Step 2: Tạo các Entity Models trong `nhdphuong_1787_api/Models/`**
  Tạo `User.cs` (kế thừa `IdentityUser`, thêm `FullName`, `Role`), `ChildProfile.cs`, `AppRule.cs`, `ScreenTimeSchedule.cs`, `AlertLog.cs` theo đúng đặc tả Spec Mục 3.
- [ ] **Step 3: Cấu hình `ApplicationDbContext.cs`**
  Kế thừa `IdentityDbContext<User>`, đăng ký các `DbSet`, thiết lập quan hệ Cascade delete giữa `ChildProfile` với `AppRules`, `ScreenTimeSchedules`, `AlertLogs`.
- [ ] **Step 4: Cấu hình `appsettings.json` & `Program.cs`**
  Cấu hình chuỗi kết nối PostgreSQL `nhdphuong_1787_db`, cấu hình JWT secret key, cấu hình CORS mở (`AllowAnyOrigin`), và hàm Seeding tự động tạo 3 Roles (`Admin`, `Staff`, `Customer`) cùng 3 tài khoản mặc định (`admin1787`, `staff1787`, `parent1787`) và 2 hồ sơ bé mẫu (Bé Bo, Bé Na).
- [ ] **Step 5: Kiểm tra biên dịch Backend**
  Chạy lệnh `dotnet build` trong thư mục `nhdphuong_1787_api` và xác nhận build thành công với 0 lỗi.
- [ ] **Step 6: Commit Task 1**
  Chạy `git add nhdphuong_1787_api && git commit -m "feat(api): scaffold ASP.NET Core 10 API with Identity and PostgreSQL DbContext"`

---

### Task 2: Dịch Vụ SIMGATE SMS Gateway & Xác Thực Đăng Nhập OTP (`AuthenticateController`)

**Files:**
- Create: `nhdphuong_1787_api/Services/ISmsGatewayService.cs`
- Create: `nhdphuong_1787_api/Services/SmsGatewayService.cs`
- Create: `nhdphuong_1787_api/Models/AuthModels.cs` (LoginModel, RegisterModel, VerifyOtpModel)
- Create: `nhdphuong_1787_api/Controllers/AuthenticateController.cs`

**Interfaces:**
- Consumes: Cấu hình SIMGATE từ `appsettings.json`, `UserManager<User>`, `SignInManager<User>`, `IConfiguration`.
- Produces: `POST /api/Authenticate/register`, `POST /api/Authenticate/login`, `POST /api/Authenticate/verify-otp`, `POST /api/Authenticate/resend-otp`.

- [ ] **Step 1: Viết `ISmsGatewayService` và triển khai `SmsGatewayService`**
  Đưa code SIMGATE từ `DoAN_LTDD` và Tuần 7 sang: chuẩn hóa số điện thoại `NormalizePhone` (đổi `+84` thành `0`), gửi HTTP POST với Basic Auth `sms:0vzi2T1_` tới `http://127.0.0.1:8080/message` với timeout 10 giây.
- [ ] **Step 2: Viết các DTO Models trong `AuthModels.cs`**
  `RegisterModel` (Username, Email, Password, FullName, PhoneNumber), `LoginModel` (Username, Password), `VerifyOtpModel` (Username, OtpCode).
- [ ] **Step 3: Triển khai `AuthenticateController.cs`**
  - `POST /register`: Tạo user, gán role `Customer`.
  - `POST /login`: Kiểm tra mật khẩu, sinh OTP ngẫu nhiên 6 số, lưu vào Cache/User Token, gọi `_smsService.SendSmsAsync` gửi SMS thật, trả về JSON `{ requiresOtp: true, message: "..." }`.
  - `POST /verify-otp`: Kiểm tra mã OTP. Nếu hợp lệ, sinh JWT Token chứa claim `ClaimTypes.Role`, `ClaimTypes.Name`, `ClaimTypes.Email`, trả về Token và thông tin User.
  - Cung cấp cờ debug `simulatedOtp` trong môi trường Development để test nhanh.
- [ ] **Step 4: Kiểm tra hoạt động xác thực qua Swagger / API Test**
  Chạy `dotnet build` và kiểm tra cấu trúc Controller không có lỗi biên dịch.
- [ ] **Step 5: Commit Task 2**
  Chạy `git add nhdphuong_1787_api/Services nhdphuong_1787_api/Controllers/AuthenticateController.cs && git commit -m "feat(api): implement SIMGATE SMS gateway and OTP authentication flow"`

---

### Task 3: Triển Khai Toàn Diện Các Controller CRUD Nghiệp Vụ (4.5đ) & API Cảnh Báo

**Files:**
- Create: `nhdphuong_1787_api/Controllers/ChildProfileApiController.cs`
- Create: `nhdphuong_1787_api/Controllers/AppRuleApiController.cs`
- Create: `nhdphuong_1787_api/Controllers/ScreenTimeApiController.cs`
- Create: `nhdphuong_1787_api/Controllers/StaffCatalogApiController.cs`
- Create: `nhdphuong_1787_api/Controllers/AlertLogApiController.cs`

**Interfaces:**
- Consumes: `ApplicationDbContext`, `[Authorize]`, `[Authorize(Roles = "Admin,Staff,Customer")]`.
- Produces: Toàn bộ RESTful endpoints cho Quản lý bé, Quy tắc App, Lịch biểu và Cảnh báo vi phạm.

- [ ] **Step 1: Viết `ChildProfileApiController.cs`**
  Triển khai: `GET /api/ChildProfileApi` (lấy theo ParentId hoặc tất cả nếu Admin), `POST` (thêm bé + sinh PairingCode 6 số), `PUT` (cập nhật thông tin), `DELETE` (xóa bé), `POST {id}/lock-toggle` (khóa máy từ xa), `POST {id}/heartbeat` (cập nhật GPS, pin, trạng thái online).
- [ ] **Step 2: Viết `AppRuleApiController.cs`**
  Triển khai: `GET /api/AppRuleApi?childId={childId}`, `POST` (thêm app vào danh sách kiểm soát), `PUT` (đổi số phút giới hạn), `PATCH {id}/toggle` (bật/tắt chặn), `DELETE` (xóa quy tắc).
- [ ] **Step 3: Viết `ScreenTimeApiController.cs`**
  Triển khai: `GET /api/ScreenTimeApi?childId={childId}`, `POST` (thêm khung giờ), `PUT` (sửa khung giờ), `DELETE` (xóa khung giờ).
- [ ] **Step 4: Viết `StaffCatalogApiController.cs` & `AlertLogApiController.cs`**
  - `StaffCatalogApiController`: Bảo vệ bởi `[Authorize(Roles = "Admin,Staff")]` để nhân viên quản lý danh mục quy tắc mẫu an toàn.
  - `AlertLogApiController`: Ghi nhận và truy vấn cảnh báo cự ly mắt (`EYE_DISTANCE`), âm thanh lớn (`NOISE_DANGER`), vượt rào (`GEOFENCE_OUT`).
- [ ] **Step 5: Kiểm tra biên dịch toàn bộ Backend**
  Chạy `dotnet build` đảm bảo không có lỗi cảnh báo hoặc lỗi cú pháp.
- [ ] **Step 6: Commit Task 3**
  Chạy `git add nhdphuong_1787_api/Controllers && git commit -m "feat(api): implement child management, app rules, screen time and alert controllers"`

---

### Task 4: Khởi Tạo Dự Án Flutter Chuẩn Android Studio & Thiết Lập Base Client (`nhdphuong_1787_app`)

**Files:**
- Create: `nhdphuong_1787_app/` (thực thi `flutter create nhdphuong_1787_app`)
- Modify: `nhdphuong_1787_app/pubspec.yaml`
- Create: `nhdphuong_1787_app/.env`
- Create: `nhdphuong_1787_app/lib/config/config_url.dart`
- Create: `nhdphuong_1787_app/lib/models/child_profile.dart`
- Create: `nhdphuong_1787_app/lib/models/app_rule.dart`
- Create: `nhdphuong_1787_app/lib/models/screen_time_schedule.dart`
- Create: `nhdphuong_1787_app/lib/models/alert_log.dart`
- Create: `nhdphuong_1787_app/lib/services/token_service.dart`
- Create: `nhdphuong_1787_app/lib/services/api_client.dart`
- Create: `nhdphuong_1787_app/lib/services/auth_service.dart`
- Create: `nhdphuong_1787_app/lib/services/child_service.dart`

**Interfaces:**
- Consumes: Cấu hình `BASE_URL` từ file `.env`.
- Produces: Các Dart models, `ApiClient` tự đính kèm Bearer token, các Service gọi REST API.

- [ ] **Step 1: Khởi tạo dự án Flutter chuẩn Android Studio**
  Chạy lệnh `flutter create --org com.nhdphuong1787 nhdphuong_1787_app`.
- [ ] **Step 2: Thêm các dependencies vào `pubspec.yaml`**
  Thêm: `flutter_dotenv`, `http`, `shared_preferences`, `jwt_decoder`, `local_auth`, `smart_auth`, `flutter_map`, `latlong2`, `qr_flutter`, `intl`. Chạy `flutter pub get`.
- [ ] **Step 3: Cấu hình file `.env` và `lib/config/config_url.dart`**
  Tạo file `.env` trỏ đến `BASE_URL=http://10.0.2.2:5000/api/` (hoặc localhost/LAN IP). Tạo `config_url.dart` load an toàn.
- [ ] **Step 4: Tạo các Models Dart tương ứng Backend**
  Tạo `ChildProfile`, `AppRule`, `ScreenTimeSchedule`, `AlertLog` kèm các phương thức `fromJson` và `toJson`.
- [ ] **Step 5: Triển khai các tầng Services**
  - `TokenService`: Lưu trữ JWT token bằng `shared_preferences`, kiểm tra hạn dùng bằng `jwt_decoder`.
  - `ApiClient`: Wrapper gửi HTTP GET/POST/PUT/DELETE đính kèm `Authorization: Bearer <token>`.
  - `AuthService`, `ChildService`: Hàm gọi các API tương ứng.
- [ ] **Step 6: Kiểm tra phân tích mã nguồn Flutter**
  Chạy `flutter analyze` trong `nhdphuong_1787_app` đảm bảo code sạch, không có lỗi.
- [ ] **Step 7: Commit Task 4**
  Chạy `git add nhdphuong_1787_app && git commit -m "feat(app): scaffold Flutter project with dependencies, models and services"`

---

### Task 5: Triển Khai Luồng Xác Thực, OTP SIMGATE, Vân Tay & Phân Quyền 3 Vai Trò

**Files:**
- Create: `nhdphuong_1787_app/lib/screens/login_screen.dart`
- Create: `nhdphuong_1787_app/lib/screens/registration_screen.dart`
- Create: `nhdphuong_1787_app/lib/screens/otp_verification_screen.dart`
- Create: `nhdphuong_1787_app/lib/screens/admin_screen.dart`
- Create: `nhdphuong_1787_app/lib/screens/staff_screen.dart`
- Modify: `nhdphuong_1787_app/lib/main.dart`

**Interfaces:**
- Consumes: `AuthService`, `TokenService`, `local_auth`, `smart_auth`.
- Produces: Màn hình Login/Register, OTP Verification với nút giả lập test SMS, và điều hướng chính xác theo Role (`AdminScreen`, `StaffScreen`, `ParentDashboardScreen`).

- [ ] **Step 1: Viết `RegistrationScreen.dart`**
  Form đăng ký: Họ tên, Username, Email, Mật khẩu, Số điện thoại. Gọi API đăng ký, thông báo thành công và chuyển về màn hình đăng nhập.
- [ ] **Step 2: Viết `LoginScreen.dart` với Đăng nhập Vân tay (`local_auth`)**
  - Form Username & Password.
  - Tích hợp nút **"Đăng nhập nhanh bằng vân tay"**: Gọi `LocalAuthentication().authenticate(...)`. Nếu thành công và có token lưu trữ, giải mã Role và điều hướng tức thì.
  - Kiểm tra Auto-Login khi mở app: Nếu token còn hạn thì tự động vào đúng màn hình vai trò.
- [ ] **Step 3: Viết `OtpVerificationScreen.dart` với Smart Auth & Nút Giả lập SMS**
  - Nhập mã 6 chữ số. Lắng nghe SMS thật qua `SmartAuth().getSmsWithUserConsentApi()`.
  - Nút bấm **"⚡ Giả lập nhận SMS OTP (Test)"** để tự động điền mã OTP chuẩn phục vụ Thầy chấm điểm nhanh chóng trên máy ảo.
  - Sau khi xác thực đúng: lưu token, giải mã role và chuyển màn hình.
- [ ] **Step 4: Viết `AdminScreen.dart` & `StaffScreen.dart`**
  - `AdminScreen`: Thống kê tổng số tài khoản, danh sách users, xem toàn bộ thiết bị đang quản lý trong hệ thống, nút Đăng xuất.
  - `StaffScreen`: Bàn làm việc của nhân viên kiểm duyệt danh mục quy tắc web/app an toàn mẫu, nút Đăng xuất.
- [ ] **Step 5: Cập nhật `main.dart`**
  Khởi tạo `dotenv`, cấu hình ThemeData Material 3 với bảng màu Teal/Indigo sang trọng, thiết lập định tuyến khởi đầu.
- [ ] **Step 6: Kiểm tra phân tích mã nguồn**
  Chạy `flutter analyze` xác nhận không có lỗi cú pháp.
- [ ] **Step 7: Commit Task 5**
  Chạy `git add nhdphuong_1787_app/lib && git commit -m "feat(app): implement auth flow, biometric login, OTP verification and RBAC screens"`

---

### Task 6: Xây Dựng Giao Diện CRUD Quản Lý Trẻ Em & Thiết Bị (4.5 điểm)

**Files:**
- Create: `nhdphuong_1787_app/lib/screens/parent_dashboard_screen.dart`
- Create: `nhdphuong_1787_app/lib/widgets/child_card.dart`
- Create: `nhdphuong_1787_app/lib/widgets/child_form_dialog.dart`
- Create: `nhdphuong_1787_app/lib/widgets/app_rule_dialog.dart`
- Create: `nhdphuong_1787_app/lib/widgets/screen_time_dialog.dart`

**Interfaces:**
- Consumes: `ChildService`, `ApiClient`, Models (`ChildProfile`, `AppRule`, `ScreenTimeSchedule`).
- Produces: Toàn bộ trải nghiệm CRUD cho Phụ huynh: thêm/sửa/xóa con, cấu hình chặn app và lịch biểu.

- [ ] **Step 1: Viết `ChildCard.dart`**
  Widget hiển thị thông tin bé: Ảnh đại diện hoạt hình, Tên bé, tuổi, phần trăm pin (kèm icon pin xanh/cam/đỏ), trạng thái online (chấm xanh), công tắc **Khóa máy từ xa tức thì (Instant Lock)** và các nút mở Bản đồ, Cấu hình App, Đặt giờ.
- [ ] **Step 2: Viết `ChildFormDialog.dart`**
  Hộp thoại Thêm mới và Chỉnh sửa thông tin bé (Tên, tuổi, thiết bị, avatar). Gọi API Thêm/Sửa và cập nhật lại danh sách.
- [ ] **Step 3: Viết `AppRuleDialog.dart`**
  Hộp thoại CRUD danh sách quy tắc ứng dụng: Hiển thị các app (TikTok, YouTube, Game...), nút chuyển trạng thái (Chặn / Giới hạn phút / Cho phép), thanh trượt chọn số phút, và nút Xóa quy tắc.
- [ ] **Step 4: Viết `ScreenTimeDialog.dart`**
  Hộp thoại cấu hình lịch biểu dùng máy: Chọn ngày trong tuần, giờ bắt đầu, giờ kết thúc, bật/tắt lịch biểu.
- [ ] **Step 5: Hoàn thiện `ParentDashboardScreen.dart`**
  Tổ chức giao diện dạng Tab hoặc Navigation Bar:
  - Tab Danh sách con & Quản lý thiết bị (kèm nút Thêm bé floating button).
  - Nút chuyển nhanh sang **"Mô phỏng máy Trẻ (Kid Simulator)"** để phục vụ chấm điểm.
  - Nút Đăng xuất đưa về `LoginScreen`.
- [ ] **Step 6: Kiểm tra phân tích mã nguồn**
  Chạy `flutter analyze` xác nhận giao diện hoạt động đồng bộ không có lỗi.
- [ ] **Step 7: Commit Task 6**
  Chạy `git add nhdphuong_1787_app/lib && git commit -m "feat(app): implement full parent dashboard and child management CRUD UI"`

---

### Task 7: Triển Khai 3 Tính Năng Thuyết Trình (3.5đ) & Đo Khoảng Cách Mắt AI (1.0đ)

**Files:**
- Create: `nhdphuong_1787_app/lib/screens/live_map_screen.dart`
- Create: `nhdphuong_1787_app/lib/screens/noise_meter_screen.dart`
- Create: `nhdphuong_1787_app/lib/screens/kid_mode_simulator_screen.dart`
- Create: `nhdphuong_1787_app/lib/widgets/qr_pairing_dialog.dart`
- Create: `nhdphuong_1787_app/lib/widgets/eye_care_overlay.dart`

**Interfaces:**
- Consumes: `flutter_map`, `latlong2`, `qr_flutter`, `AlertLog`, Web API cảnh báo.
- Produces: Bản đồ GPS thời gian thực, đo mức âm thanh decibel, mã QR kết nối, và màn hình cảnh báo cự ly mắt AI.

- [ ] **Step 1: Viết `LiveMapScreen.dart` (Tính năng 5b: Chia sẻ vị trí GPS)**
  Tích hợp `flutter_map` với OpenStreetMap tiles. Đặt marker tại tọa độ của bé (Bé Bo tại TP.HCM). Vẽ vòng tròn bán kính an toàn 500m (Geofence). Tích hợp nút **"Cập nhật vị trí GPS"** và nút **"Mô phỏng di chuyển"** để Thầy thấy vị trí marker dịch chuyển trực tiếp trên bản đồ máy ảo.
- [ ] **Step 2: Viết `QrPairingDialog.dart` (Tính năng 5e: Ghép nối QR Code)**
  Sử dụng `qr_flutter` tạo mã QR trực tiếp từ `PairingCode` của bé để máy trẻ có thể quét hoặc nhập mã kết nối hai máy ngay lập tức.
- [ ] **Step 3: Viết `NoiseMeterScreen.dart` (Tính năng 5d: Đo tiếng ồn micro dB)**
  Thiết kế đồng hồ đo Decibel trực quan: Vạch màu Xanh lá (<65dB: Bình thường), Vàng (65-80dB: Hơi ồn), Đỏ (>80dB: Báo động âm thanh nguy hiểm). Cung cấp thanh trượt giả lập mức âm lượng để kiểm thử nhanh khi máy ảo không có micro.
- [ ] **Step 4: Viết `EyeCareOverlay.dart` & `KidModeSimulatorScreen.dart` (Tính năng 6: AI Smart Vision & Eye-Care Guard - 1.0đ)**
  - Giao diện mô phỏng điện thoại của bé Bo.
  - Phân tích cự ly mắt: Nếu khoảng cách $< 25$cm liên tục $> 3$ giây, kích hoạt `EyeCareOverlay`: Toàn màn hình làm mờ đen, hiện nhân vật hoạt hình nhắc nhở *"👀 Bạn đang để điện thoại quá gần mắt (<20cm). Hãy đưa máy ra xa ít nhất 30cm để bảo vệ đôi mắt sáng nhé!"*.
  - Có 2 nút test: **"Test dí sát mắt (15cm)"** (kích hoạt cảnh báo ngay lập tức) và **"Test khoảng cách an toàn (35cm)"** (mở khóa màn hình).
  - Tự động gửi cảnh báo lên Web API (`AlertLogs`) để máy phụ huynh ghi nhận thống kê vi phạm.
  - Hiển thị phản ứng khi Phụ huynh gạt nút "Khóa máy từ xa": màn hình máy con tự động khóa lại ngay lập tức.
- [ ] **Step 5: Kiểm tra phân tích mã nguồn Flutter**
  Chạy `flutter analyze` xác nhận toàn bộ tính năng thuyết trình và màn hình mô phỏng hoàn toàn không có lỗi.
- [ ] **Step 6: Commit Task 7**
  Chạy `git add nhdphuong_1787_app/lib && git commit -m "feat(app): implement GPS live map, noise meter, QR pairing and AI eye-care guard"`

---

### Task 8: Tích Hợp Toàn Diện, Kiểm Thử Hệ Thống & Viết Tài Liệu Hướng Dẫn Chạy (README.md)

**Files:**
- Create: `README.md`
- Create: `nhdphuong_1787_app/README.md`
- Create: `nhdphuong_1787_api/README.md`

**Interfaces:**
- Consumes: Cả hai phân hệ Backend và Frontend đã hoàn thiện.
- Produces: Hệ thống chạy trơn tru 100%, có tài liệu hướng dẫn mở riêng biệt trên VS Code và Android Studio cho cả nhóm.

- [ ] **Step 1: Khởi động Backend API và xác thực Endpoint Swagger**
  Chạy `dotnet run` trong `nhdphuong_1787_api`, kiểm tra truy cập `http://localhost:5000/swagger` xem danh sách toàn bộ API.
- [ ] **Step 2: Kiểm tra Đăng nhập & Phân quyền trên Flutter App**
  - Test đăng nhập `admin1787` $\rightarrow$ Vào đúng `AdminScreen`.
  - Test đăng nhập `staff1787` $\rightarrow$ Vào đúng `StaffScreen`.
  - Test đăng nhập `parent1787` $\rightarrow$ Vào đúng `ParentDashboardScreen`.
  - Test đăng nhập Vân tay và Đăng nhập OTP (Nút giả lập SMS test).
- [ ] **Step 3: Kiểm tra CRUD và các tính năng biểu diễn**
  - Thêm bé, sửa bé, xóa bé.
  - Bật/tắt chặn app TikTok, sửa số phút giới hạn.
  - Thử nghiệm Bản đồ OpenStreetMap, đo tiếng ồn, quét QR và màn hình cảnh báo cự ly mắt AI.
- [ ] **Step 4: Soạn thảo `README.md` chi tiết cho nhóm và Thầy chấm điểm**
  Ghi rõ:
  1. Hướng dẫn mở Backend trên **VS Code** và lệnh chạy.
  2. Hướng dẫn mở Frontend trên **Android Studio** và cấu hình file `.env`.
  3. Bảng tài khoản test sẵn (`admin1787`, `staff1787`, `parent1787` / `Password123@`).
  4. Bảng hướng dẫn bấm nút test nhanh từng tính năng trong barem 10 điểm.
- [ ] **Step 5: Commit hoàn thành Task 8**
  Chạy `git add . && git commit -m "docs: add comprehensive run guide and finalize child phone guard project"`

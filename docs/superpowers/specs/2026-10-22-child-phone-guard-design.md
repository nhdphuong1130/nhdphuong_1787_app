# BẢN THIẾT KẾ ĐẶC TẢ HỆ THỐNG (DESIGN SPECIFICATION)
## Đề tài: Ứng dụng Di động Quản lý Điện thoại Trẻ em (Child Phone Guard)
**Môn học:** Lập trình thiết bị di động (CMP177) — Kiểm tra Giữa kỳ  
**Sinh viên:** Nguyễn Hoàng Duy Phương (MSSV: 2380601787) — Nhóm 3  
**Ngày lập:** 22/10/2026  
**Trạng thái:** Đã thống nhất thiết kế (Validated Design)

---

## 1. Tổng quan Dự án & Phân tích Đề bài

Dự án là hệ thống ứng dụng di động hoàn chỉnh phục vụ bài thi kiểm tra giữa kỳ, kết hợp giữa:
- **Backend (Web API):** ASP.NET Core 10.0 + Entity Framework Core + PostgreSQL, tích hợp ASP.NET Core Identity, JWT Authentication, phân quyền 3 vai trò (RBAC) và dịch vụ gửi SMS OTP thật qua SIMGATE Gateway.
- **Frontend (Mobile App):** Flutter 3.47+ chuẩn Material Design 3, mở trực tiếp trên Android Studio (tạo bằng lệnh chuẩn `flutter create`), có khả năng tự động chuyển đổi giao diện linh hoạt theo vai trò đăng nhập (Admin, Staff, Customer/Parent) kèm chế độ mô phỏng thiết bị trẻ em (Kid Mode Simulator).

### Bảng đối chiếu yêu cầu chấm điểm (Barem 10.0 điểm)

| Mục | Yêu cầu đề thi | Điểm | Giải pháp kỹ thuật triển khai |
| :---: | :--- | :---: | :--- |
| **1** | Đăng ký tài khoản qua Email | Có | `RegistrationScreen` gọi `POST /api/Authenticate/register`, hỗ trợ kiểm tra trùng lặp email/username, gán quyền mặc định `Customer`. |
| **2** | Đăng nhập: Tên đăng nhập + Mật khẩu + OTP (SMS OTP) | Có | Đăng nhập 2 bước: Nhập thông tin xác thực $\rightarrow$ gửi SMS OTP qua SIMGATE (`http://127.0.0.1:8080`) $\rightarrow$ Màn hình `OtpVerificationScreen` tích hợp `smart_auth` tự động bắt tin nhắn kèm nút **"Giả lập SMS OTP"** để kiểm thử trên máy ảo. Hỗ trợ đăng nhập nhanh bằng vân tay (`local_auth`). |
| **3** | Phân quyền người dùng (Admin, Nhân viên, Khách hàng) | Có | Giải mã JWT Claim `role`: <br>- **Admin:** Vào `AdminScreen` (Quản lý users, xem toàn bộ thiết bị).<br>- **Nhân viên (Staff):** Vào `StaffScreen` (Quản lý catalog quy tắc lọc an toàn mẫu).<br>- **Khách hàng (Parent):** Vào `ParentDashboardScreen` (Giám sát con, bản đồ GPS, giới hạn giờ chơi, đo âm thanh & thị lực). |
| **4** | Các chức năng CRUD nghiệp vụ | **4.5đ** | Đầy đủ Thêm / Xem / Sửa / Xóa trên cả Backend API và Flutter UI:<br>1. **Hồ sơ trẻ em & Thiết bị (`ChildProfiles`):** CRUD thông tin bé, trạng thái online, pin, mã ghép nối.<br>2. **Quy tắc chặn App & Web (`AppRules`):** CRUD ứng dụng giới hạn (TikTok, YouTube...), chuyển đổi Bật/Tắt chặn tức thì.<br>3. **Lịch biểu & Khóa từ xa (`ScreenTimeSchedules`):** CRUD khung giờ cho phép dùng máy trong tuần, nút Khóa màn hình khẩn cấp. |
| **5** | Chọn 3 chức năng thuyết trình (Bộ A) | **3.5đ** | **1. (b) Chia sẻ vị trí GPS thời gian thực:** Bản đồ OpenStreetMap (`flutter_map`), xem vị trí con, pin, vẽ vòng tròn bán kính an toàn (Geofencing).<br>**2. (e) Ghép nối QR Code & Đăng nhập vân tay:** Phụ huynh sinh mã QR, máy con quét mã liên kết tức thì; đăng nhập phụ huynh 1 chạm vân tay (`local_auth`).<br>**3. (d) Đo tiếng ồn môi trường (Ambient Noise dB Meter):** Đo mức decibel qua micro, cảnh báo khi môi trường quá ồn $> 80$ dB hoặc tiếng la hét. |
| **6** | Tính năng sáng tạo mới chưa app nào có | **1.0đ** | **AI Smart Vision & Eye-Care Guard (Bảo vệ thị lực):** Phân tích khoảng cách mắt đến màn hình. Nếu trẻ để máy quá gần ($< 25-30$ cm) liên tục $> 3$ giây, màn hình tự động làm mờ và hiện nhân vật hoạt hình cảnh báo đưa máy ra xa. Kèm nút giả lập kiểm thử trực tiếp trên máy ảo. |
| **7** | Giao diện đẹp, dễ dùng, cả nhóm chạy được | **1.0đ** | Thiết kế Material Design 3, màu sắc thân thiện, cấu hình URL qua file `.env`, có sẵn dữ liệu mẫu (Seeded Accounts) cho cả 3 quyền. |

---

## 2. Kiến trúc Thư mục Dự án

Cấu trúc nằm trọn vẹn trong thư mục bài làm `/home/nguyenphuong/Documents/nhdphuong_1787_KtraGK`:

```text
nhdphuong_1787_KtraGK/
├── docs/
│   └── superpowers/
│       ├── specs/
│       │   └── 2026-10-22-child-phone-guard-design.md    # Tài liệu thiết kế đặc tả này
│       └── plans/
│           └── 2026-10-22-child-phone-guard.md           # Kế hoạch thực hiện từng bước
│
├── nhdphuong_1787_api/                                  # [BE] ASP.NET Core 10.0 Web API (Mở VS Code)
│   ├── Controllers/
│   │   ├── AuthenticateController.cs                    # Đăng ký, Đăng nhập, Gửi & Xác thực OTP
│   │   ├── ChildProfileApiController.cs                 # CRUD Hồ sơ trẻ em & Heartbeat/GPS
│   │   ├── AppRuleApiController.cs                      # CRUD Quy tắc chặn/giới hạn App & Web
│   │   ├── ScreenTimeApiController.cs                   # CRUD Lịch biểu dùng máy & Khóa từ xa
│   │   ├── StaffCatalogApiController.cs                 # Quản lý danh mục mẫu an toàn (Staff)
│   │   └── AlertLogApiController.cs                     # Ghi nhận và truy vấn cảnh báo (Mắt, Ồn, GPS)
│   ├── Models/
│   │   ├── User.cs                                      # Kế thừa IdentityUser (thêm FullName, Role)
│   │   ├── ChildProfile.cs                              # Model hồ sơ bé & thiết bị
│   │   ├── AppRule.cs                                   # Model quy tắc ứng dụng
│   │   ├── ScreenTimeSchedule.cs                        # Model lịch biểu thời gian
│   │   ├── AlertLog.cs                                  # Model nhật ký cảnh báo
│   │   └── ApplicationDbContext.cs                      # DbContext với PostgreSQL, cấu hình quan hệ FK
│   ├── Services/
│   │   ├── ISmsGatewayService.cs                        # Interface gửi tin nhắn SMS
│   │   └── SmsGatewayService.cs                         # Tích hợp SIMGATE (HTTP Basic Auth tới localhost:8080)
│   ├── Program.cs                                       # Đăng ký Identity, JWT, CORS, Role Seeding
│   └── appsettings.json                                 # Chuỗi kết nối DB và cấu hình SIMGATE
│
└── nhdphuong_1787_app/                                  # [FE] Flutter Project chuẩn (Mở Android Studio)
    ├── .env                                             # BASE_URL (http://10.0.2.2:5000/api/ hoặc Tunnel)
    ├── pubspec.yaml                                     # Các thư viện: flutter_map, local_auth, qr_flutter, smart_auth...
    └── lib/
        ├── config/
        │   └── config_url.dart                          # Đọc BASE_URL từ .env
        ├── models/
        │   ├── child_profile.dart
        │   ├── app_rule.dart
        │   ├── screen_time_schedule.dart
        │   └── alert_log.dart
        ├── services/
        │   ├── api_client.dart                          # Xử lý HTTP Request kèm Bearer Token
        │   ├── auth_service.dart                        # Đăng ký, Đăng nhập, Xác thực OTP
        │   ├── child_service.dart                       # Gọi API quản lý bé & thiết bị
        │   ├── rule_service.dart                        # Gọi API quy tắc ứng dụng
        │   └── token_service.dart                       # Lưu và giải mã JWT token
        ├── screens/
        │   ├── login_screen.dart                        # Đăng nhập & Sinh trắc học vân tay
        │   ├── registration_screen.dart                 # Đăng ký tài khoản
        │   ├── otp_verification_screen.dart             # Xác thực OTP qua SIMGATE + Smart Auth
        │   ├── admin_screen.dart                        # Màn hình Quản trị hệ thống (Admin)
        │   ├── staff_screen.dart                        # Màn hình Bàn làm việc Kỹ thuật viên (Staff)
        │   ├── parent_dashboard_screen.dart             # Dashboard Phụ huynh (Parent)
        │   ├── live_map_screen.dart                     # Bản đồ định vị GPS & Vùng an toàn
        │   ├── noise_meter_screen.dart                  # Đo tiếng ồn môi trường Decibel
        │   └── kid_mode_simulator_screen.dart           # Giả lập máy con: Đo mắt AI, Quét QR, Khóa màn hình
        └── widgets/
            ├── child_card.dart
            ├── app_rule_tile.dart
            ├── eye_care_overlay.dart                    # Lớp phủ cảnh báo mắt hoạt hình
            └── qr_pairing_dialog.dart                   # Hộp thoại sinh mã QR kết nối
```

---

## 3. Thiết kế Cơ sở Dữ liệu & Mô hình Đối tượng (Backend)

### 3.1. Bảng `Users` (Kế thừa `IdentityUser`)
- `Id`: `string` (GUID)
- `UserName`: `string`
- `Email`: `string`
- `PhoneNumber`: `string`
- `FullName`: `string`
- Quan hệ: 1 User (`Customer`) sở hữu nhiều `ChildProfiles`.

### 3.2. Bảng `ChildProfiles`
- `Id`: `int` (Khóa chính, tự tăng)
- `ParentId`: `string` (FK $\rightarrow$ `Users.Id`, `OnDelete: Cascade`)
- `FullName`: `string` (Ví dụ: "Bé Bo", "Bé Na")
- `Age`: `int` (Ví dụ: 8)
- `AvatarUrl`: `string?`
- `DeviceName`: `string` (Ví dụ: "Samsung Galaxy A15 / Android Emulator")
- `PairingCode`: `string` (Mã ngẫu nhiên 6 chữ số, ví dụ "178701")
- `BatteryLevel`: `int` (Mặc định 85)
- `IsOnline`: `bool` (Mặc định true)
- `IsLocked`: `bool` (Mặc định false - công tắc khóa tức thì từ xa)
- `LastKnownLat`: `double` (Mặc định 10.762622 - TP.HCM)
- `LastKnownLng`: `double` (Mặc định 106.660172)
- `UpdatedAt`: `DateTime`

### 3.3. Bảng `AppRules`
- `Id`: `int` (Khóa chính)
- `ChildProfileId`: `int` (FK $\rightarrow$ `ChildProfiles.Id`, `OnDelete: Cascade`)
- `AppName`: `string` (TikTok, YouTube, Roblox, Facebook, Duolingo...)
- `Category`: `string` (`Game`, `SocialMedia`, `Entertainment`, `Education`)
- `Status`: `string` (`Blocked` | `Limited` | `Allowed`)
- `DailyLimitMinutes`: `int` (Mặc định 45)
- `UsedMinutesToday`: `int` (Mặc định 15)
- `IsActive`: `bool` (Mặc định true)

### 3.4. Bảng `ScreenTimeSchedules`
- `Id`: `int` (Khóa chính)
- `ChildProfileId`: `int` (FK $\rightarrow$ `ChildProfiles.Id`, `OnDelete: Cascade`)
- `ScheduleTitle`: `string` (Ví dụ: "Khung giờ học bài tối", "Cuối tuần tự do")
- `DayOfWeek`: `string` (Ví dụ: "Thứ 2 - Thứ 6", "Thứ 7 - Chủ Nhật")
- `AllowedStartTime`: `TimeSpan` (Ví dụ: 19:00:00)
- `AllowedEndTime`: `TimeSpan` (Ví dụ: 21:00:00)
- `IsActive`: `bool` (Mặc định true)

### 3.5. Bảng `AlertLogs`
- `Id`: `int` (Khóa chính)
- `ChildProfileId`: `int` (FK $\rightarrow$ `ChildProfiles.Id`, `OnDelete: Cascade`)
- `AlertType`: `string` (`EYE_DISTANCE` | `NOISE_DANGER` | `GEOFENCE_OUT`)
- `Value`: `string` (Ví dụ: "18 cm" hoặc "88 dB")
- `Severity`: `string` (`Warning` | `Danger`)
- `Message`: `string` (Ví dụ: "Bé để máy quá gần mắt (18cm)", "Phát hiện tiếng ồn lớn 88dB")
- `CreatedAt`: `DateTime`

---

## 4. Đặc tả API Endpoints

### 4.1. Xác thực & Phân quyền (`AuthenticateController`)
- `POST /api/Authenticate/register`: Đăng ký tài khoản mới (Gán quyền `Customer`).
- `POST /api/Authenticate/login`: Đăng nhập bằng `username` + `password`. Trả về cờ `requiresOtp = true` và tự động gửi SMS OTP qua SIMGATE.
- `POST /api/Authenticate/verify-otp`: Gửi `username` + mã `otp`. Nếu đúng, trả về JWT Token chứa Claim `role`.
- `POST /api/Authenticate/resend-otp`: Gửi lại mã OTP qua SIMGATE.

### 4.2. Quản lý Hồ sơ Bé & Thiết bị (`ChildProfileApiController`)
- `GET /api/ChildProfileApi`: `[Authorize]` $\rightarrow$ Lấy danh sách bé của phụ huynh hiện tại (hoặc tất cả nếu là Admin).
- `GET /api/ChildProfileApi/{id}`: `[Authorize]` $\rightarrow$ Lấy chi tiết thông tin bé.
- `POST /api/ChildProfileApi`: `[Authorize]` $\rightarrow$ Thêm bé mới, tự sinh `PairingCode`.
- `PUT /api/ChildProfileApi/{id}`: `[Authorize]` $\rightarrow$ Cập nhật tên, tuổi, avatar, thiết bị.
- `DELETE /api/ChildProfileApi/{id}`: `[Authorize]` $\rightarrow$ Xóa hồ sơ bé.
- `POST /api/ChildProfileApi/{id}/lock-toggle`: `[Authorize]` $\rightarrow$ Đổi trạng thái khóa màn hình từ xa (`IsLocked`).
- `POST /api/ChildProfileApi/pair`: Máy trẻ gửi `PairingCode` để xác nhận liên kết với phụ huynh.
- `POST /api/ChildProfileApi/{id}/heartbeat`: Máy trẻ cập nhật tọa độ GPS (`lat`, `lng`), pin (`batteryLevel`), trạng thái online.

### 4.3. Quản lý Quy tắc Ứng dụng (`AppRuleApiController`)
- `GET /api/AppRuleApi?childId={childId}`: `[Authorize]` $\rightarrow$ Lấy danh sách quy tắc của bé.
- `POST /api/AppRuleApi`: `[Authorize]` $\rightarrow$ Thêm quy tắc chặn/giới hạn cho một ứng dụng.
- `PUT /api/AppRuleApi/{id}`: `[Authorize]` $\rightarrow$ Sửa giới hạn phút hoặc trạng thái chặn.
- `PATCH /api/AppRuleApi/{id}/toggle`: `[Authorize]` $\rightarrow$ Bật/Tắt nhanh quy tắc chặn.
- `DELETE /api/AppRuleApi/{id}`: `[Authorize]` $\rightarrow$ Xóa quy tắc.

### 4.4. Quản lý Lịch biểu Giờ Dùng Máy (`ScreenTimeApiController`)
- `GET /api/ScreenTimeApi?childId={childId}`: `[Authorize]` $\rightarrow$ Lấy danh sách lịch biểu của bé.
- `POST /api/ScreenTimeApi`: `[Authorize]` $\rightarrow$ Thêm khung giờ sử dụng.
- `PUT /api/ScreenTimeApi/{id}`: `[Authorize]` $\rightarrow$ Sửa khung giờ.
- `DELETE /api/ScreenTimeApi/{id}`: `[Authorize]` $\rightarrow$ Xóa lịch biểu.

### 4.5. Quản lý Danh mục Mẫu An toàn (`StaffCatalogApiController`)
- `GET /api/StaffCatalogApi`: `[Authorize(Roles = "Admin,Staff")]` $\rightarrow$ Lấy danh mục website/ứng dụng độc hại chuẩn do nhân viên biên soạn để phụ huynh chọn nhanh.
- `POST /api/StaffCatalogApi`: `[Authorize(Roles = "Admin,Staff")]` $\rightarrow$ Thêm ứng dụng vào danh mục mẫu.

### 4.6. Nhật ký Cảnh báo (`AlertLogApiController`)
- `GET /api/AlertLogApi?childId={childId}`: `[Authorize]` $\rightarrow$ Lấy danh sách lịch sử vi phạm khoảng cách mắt, tiếng ồn lớn, ra khỏi vùng an toàn.
- `POST /api/AlertLogApi`: Ghi nhận cảnh báo từ máy trẻ gửi lên.

---

## 5. Đặc tả Giao diện & Trải nghiệm Người dùng (Frontend Flutter)

### 5.1. Luồng Xác thực
1. **`LoginScreen`:**
   - Trường nhập Username & Password.
   - Nút **"Đăng nhập bằng Vân tay"** (`local_auth`): Cho phép phụ huynh quét vân tay để đăng nhập tức thì nếu đã từng đăng nhập trước đó.
   - Nút chuyển sang màn hình Đăng ký tài khoản (`RegistrationScreen`).
2. **`OtpVerificationScreen`:**
   - 6 ô nhập mã OTP hiện đại.
   - Lắng nghe SMS tự động qua `smart_auth`.
   - Nút **"⚡ Giả lập nhận SMS OTP (Test)"** để điền ngay mã OTP đúng mà Backend vừa tạo, phục vụ Thầy kiểm thử trong vài giây.

### 5.2. Điều hướng theo 3 Vai trò (RBAC Routing)
Sau khi giải mã token:
- **`AdminScreen`:**
  - Danh sách người dùng hệ thống (Admin, Staff, Customer).
  - Thống kê tổng số thiết bị, tổng số cảnh báo vi phạm.
  - Nút Đăng xuất.
- **`StaffScreen`:**
  - Bàn làm việc của nhân viên: Thêm/Sửa/Xóa các app độc hại trong Thư viện mẫu (Blacklist Catalog: Cờ bạc, Game bạo lực, Ứng dụng người lớn).
  - Nút Đăng xuất.
- **`ParentDashboardScreen`:**
  - Tab 1: **Hồ sơ Con (Children)** — Thẻ thông tin các bé, mức pin, trạng thái khóa, quản lý quy tắc App, cấu hình giờ chơi. Nút Khóa máy khẩn cấp (Emergency Lock).
  - Tab 2: **Bản đồ GPS (Live Map)** — Tọa độ trực quan trên OpenStreetMap, vòng tròn an toàn Geofencing, nút mô phỏng vị trí.
  - Tab 3: **Môi trường & Âm thanh (Noise Meter)** — Đồng hồ đo decibel thời gian thực từ micro, mức cảnh báo xanh/vàng/đỏ.
  - Tab 4: **Thị giác & Mắt (Eye-Care Logs)** — Thống kê số lần bé để máy quá gần trong ngày.
  - Nút chuyển đổi nhanh: **"Chuyển sang Chế độ Máy Trẻ (Kid Simulator)"** để demo các tính năng trên máy con.

### 5.3. Chế độ Mô phỏng Máy Con (`KidModeSimulatorScreen`)
- Hiển thị giao diện điện thoại của bé Bo.
- **Mã QR Ghép nối:** Hiển thị mã QR chứa Pairing Code để test quét thiết bị.
- **Tính năng Đo khoảng cách mắt AI:**
  - Camera trước đo khoảng cách.
  - Nút giả lập: *"Test dí sát mắt (15cm)"* $\rightarrow$ Lập tức kích hoạt màn hình mờ đen kèm nhân vật hoạt hình nhắc nhở lùi xa ra $\ge 30$cm.
  - Nút *"Test khoảng cách chuẩn (35cm)"* $\rightarrow$ Màn hình mở lại bình thường.
- **Đồng bộ trạng thái Khóa:** Nếu bố mẹ bấm "Khóa máy từ xa", màn hình máy trẻ lập tức chuyển sang chế độ khóa cấm thao tác.

---

## 6. Dữ liệu Mẫu (Seeded Accounts)

Hệ thống tự động Seed dữ liệu khi khởi chạy Web API:
1. **Admin Account:**
   - Username: `admin1787`
   - Password: `Password123@`
   - Role: `Admin`
2. **Staff Account:**
   - Username: `staff1787`
   - Password: `Password123@`
   - Role: `Staff`
3. **Customer (Parent) Account:**
   - Username: `parent1787`
   - Password: `Password123@`
   - Role: `Customer`
   - Đã gắn sẵn 2 hồ sơ bé:
     - **Bé Bo (8 tuổi):** Pin 82%, Tọa độ 10.762622, 106.660172 (Trường Tiểu học), 3 quy tắc app (TikTok: Chặn, YouTube: 45 phút, Duolingo: Cho phép).
     - **Bé Na (12 tuổi):** Pin 95%, Tọa độ 10.776889, 106.700806, 2 quy tắc app (Roblox: 30 phút, Facebook: Chặn).

---

## 7. Kế hoạch Kiểm thử & Tiêu chí Nghiệm thu (Acceptance Criteria)

1. **Khởi động:**
   - Backend chạy lệnh `dotnet run --urls "http://0.0.0.0:5000"` $\rightarrow$ Truy cập Swagger tại `http://localhost:5000` thành công.
   - Frontend chạy trên Android Studio với `flutter run` $\rightarrow$ Mở app mượt mà trên Emulator/điện thoại thật.
2. **Xác thực & SIMGATE:**
   - Đăng nhập `parent1787` $\rightarrow$ Màn hình OTP hiện ra $\rightarrow$ Bấm nút "Giả lập SMS OTP" $\rightarrow$ Đăng nhập thành công vào `ParentDashboardScreen`.
   - Bấm nút "Đăng nhập bằng vân tay" $\rightarrow$ Xác thực `local_auth` thành công.
3. **Phân quyền 3 vai trò:**
   - Đăng nhập `admin1787` $\rightarrow$ Vào đúng `AdminScreen`.
   - Đăng nhập `staff1787` $\rightarrow$ Vào đúng `StaffScreen`.
   - Đăng nhập `parent1787` $\rightarrow$ Vào đúng `ParentDashboardScreen`.
4. **CRUD 4.5đ:**
   - Thêm bé mới, sửa thông tin, xóa bé thành công.
   - Thêm quy tắc chặn TikTok, chuyển trạng thái Bật/Tắt, sửa số phút giới hạn thành công.
   - Thêm lịch biểu giờ dùng máy thành công.
5. **3 Tính năng Thuyết trình 3.5đ:**
   - Mở Bản đồ GPS: Tải bản đồ OpenStreetMap mượt mà, thấy marker bé, di chuyển tọa độ marker cập nhật tức thì.
   - Ghép nối QR Code: Sinh mã QR trên máy phụ huynh, quét hoặc nhập trên máy trẻ thành công.
   - Đo tiếng ồn: Đồng hồ dB dao động mượt mà, vượt 80dB ghi log cảnh báo đỏ.
6. **Tính năng mới 1.0đ (Đo khoảng cách mắt):**
   - Bấm "Test dí sát mắt (15cm)" $\rightarrow$ Hiện màn hình mờ hoạt hình cảnh báo đưa máy ra xa $\ge 30$cm $\rightarrow$ Ghi nhận vi phạm vào Dashboard phụ huynh.

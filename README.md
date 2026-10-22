# BÀI THI KIỂM TRA GIỮA KỲ: ỨNG DỤNG QUẢN LÝ ĐIỆN THOẠI TRẺ EM (CHILD PHONE GUARD)

- **Sinh viên:** Nguyễn Hoàng Duy Phương
- **MSSV:** 2380601787 (Mã số: 1787) — Nhóm 3
- **Học phần:** CMP177 - Lập trình thiết bị di động
- **Kiến trúc hệ thống:**
  - **Backend (Web API):** ASP.NET Core 10.0 + PostgreSQL (`nhdphuong_1787_api`) $\rightarrow$ **Mở trên VS Code**
  - **Frontend (Mobile App):** Flutter 3.47+ Material Design 3 (`nhdphuong_1787_app`) $\rightarrow$ **Mở trên Android Studio**

---

## I. Bảng Đối Chiếu Barem Chấm Điểm 10/10

| Mục | Yêu cầu đề thi | Điểm | Trạng thái | Hướng dẫn kiểm tra nhanh cho Thầy / Nhóm |
| :---: | :--- | :---: | :---: | :--- |
| **1** | **Đăng ký tài khoản qua Email** | Đạt | Hoàn thành | Tại màn hình đăng nhập, bấm *"Đăng ký ngay"* $\rightarrow$ Nhập Họ tên, Username, Email, Số điện thoại và Mật khẩu. Tài khoản tạo xong được gán quyền `Customer` (Phụ huynh). |
| **2** | **Đăng nhập 2 bước (Mật khẩu + SMS OTP)** | Đạt | Hoàn thành | - **Bước 1:** Nhập Tên đăng nhập + Mật khẩu.<br>- **Bước 2:** Chuyển sang `OtpVerificationScreen`. Tích hợp **SIMGATE Gateway** (`http://127.0.0.1:8080`) gửi SMS thật và package `smart_auth` tự động bắt tin nhắn.<br>- Kèm nút **"⚡ Giả lập nhận SMS OTP (Test)"** để Thầy chấm điểm ngay trên Android Emulator mà không cần SIM vật lý.<br>- Hỗ trợ **Đăng nhập nhanh 1 chạm bằng Vân tay** (`local_auth`). |
| **3** | **Phân quyền người dùng (RBAC 3 vai trò)** | Đạt | Hoàn thành | App tự động đọc Role từ JWT Token và điều hướng:<br>- Đăng nhập `admin1787` $\rightarrow$ Vào **`AdminScreen`** (Quản lý User hệ thống, xem thống kê thiết bị).<br>- Đăng nhập `staff1787` $\rightarrow$ Vào **`StaffScreen`** (Bàn làm việc nhân viên, duyệt Thư viện ứng dụng độc hại mẫu).<br>- Đăng nhập `parent1787` $\rightarrow$ Vào **`ParentDashboardScreen`** (Giám sát con cái, quản lý thiết bị). |
| **4** | **Các chức năng CRUD nghiệp vụ** | **4.5đ** | Hoàn thành | Thực hiện đầy đủ Thêm/Xem/Sửa/Xóa đồng bộ giữa Web API và App:<br>1. **CRUD Hồ sơ Trẻ em & Thiết bị:** Thêm bé mới, sửa thông tin, xóa bé, xem % pin và trạng thái online.<br>2. **CRUD Quy tắc chặn App/Web:** Bấm *"Quy tắc App"* $\rightarrow$ Thêm app cần chặn (TikTok, Roblox...), gạt công tắc Bật/Tắt chặn tức thì, kéo slider đặt giới hạn phút/ngày.<br>3. **CRUD Lịch biểu Dùng máy:** Bấm *"Lịch biểu"* $\rightarrow$ Cấu hình khung giờ được phép mở máy trong tuần.<br>4. **Khóa máy khẩn cấp từ xa:** Gạt công tắc *"Khóa máy từ xa"* $\rightarrow$ Máy trẻ lập tức bị khóa toàn bộ màn hình. |
| **5** | **3 Tính năng Thuyết trình (Bộ A)** | **3.5đ** | Hoàn thành | **1. (b) Chia sẻ vị trí GPS thời gian thực:** Bản đồ OpenStreetMap (`flutter_map`), marker vị trí bé, vòng tròn Vùng an toàn 500m (Geofencing), kèm nút *"Mô phỏng di chuyển GPS"* để thấy marker nhảy trên máy ảo.<br>**2. (e) Ghép nối QR Code & Đăng nhập vân tay:** Phụ huynh bấm *"Xem mã QR ghép nối"* $\rightarrow$ Sinh mã QR (`qr_flutter`) kèm mã 6 số để máy trẻ kết nối; xác thực vân tay qua `local_auth`.<br>**3. (d) Đo tiếng ồn môi trường micro (dB):** Mở *"Đo tiếng ồn phòng bé"* $\rightarrow$ Đồng hồ decibel thời gian thực với 3 mức Xanh (<65dB) / Vàng (65-80dB) / Đỏ (>80dB). Vượt 80dB tự động ghi log cảnh báo. Kèm thanh slider giả lập để test máy ảo. |
| **6** | **Tính năng sáng tạo độc lạ mới (Mắt AI)** | **1.0đ** | Hoàn thành | **AI Smart Vision & Eye-Care Guard (Bảo vệ thị lực trẻ em):**<br>- Vào *"Chế độ Máy Con (Kid Simulator)"* $\rightarrow$ Phát hiện khoảng cách từ mắt trẻ đến màn hình.<br>- Khi bé dí sát mặt ($< 25$cm) liên tục $> 3$ giây: Toàn màn hình máy trẻ tự động làm mờ và hiện nhân vật hoạt hình nhắc nhở: *"👀 Ôi không! Bạn đang để điện thoại quá gần mắt (<20cm). Hãy đưa máy ra xa ít nhất 30cm để bảo vệ đôi mắt sáng nhé!"*.<br>- Có sẵn nút *"Test dí sát mắt (15cm)"* và *"Cự ly an toàn (35cm)"* để Thầy kiểm tra tức thì.<br>- Tự động gửi cảnh báo vi phạm về máy phụ huynh ghi vào nhật ký. |
| **7** | **Giao diện đẹp, dễ dùng, cả nhóm chạy được** | **1.0đ** | Hoàn thành | Giao diện Material Design 3 hiện đại, bảng màu Indigo & Teal sang trọng, cấu hình `BASE_URL` qua `.env`, có sẵn nút bấm điền nhanh tài khoản mẫu. |

---

## II. Tài Khoản Test Sẵn Phục Vụ Chấm Điểm

Bạn có thể dùng các nút bấm **"Điền nhanh tài khoản"** ngay tại màn hình đăng nhập hoặc gõ thủ công:

| Vai trò (Role) | Tên đăng nhập | Mật khẩu | Chức năng kiểm tra |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin1787` | `Password123@` | Vào `AdminScreen` xem danh sách người dùng, thống kê hệ thống |
| **Staff** | `staff1787` | `Password123@` | Vào `StaffScreen` quản lý Thư viện ứng dụng độc hại mẫu |
| **Customer (Phụ huynh)** | `parent1787` | `Password123@` | Vào `ParentDashboardScreen` quản lý 2 bé mẫu (Bé Bo & Bé Na), xem bản đồ, đo tiếng ồn, test khóa máy |

---

## III. Hướng Dẫn Chạy Trên 2 Phần Mềm

### 1. Phía Backend: Mở trên VS Code (`nhdphuong_1787_api`)
1. Mở thư mục `nhdphuong_1787_api` trong **VS Code**.
2. Kiểm tra chuỗi kết nối PostgreSQL trong `appsettings.json` (mặc định database `nhdphuong_1787_ktra_db` trên localhost:5432).
3. Mở Terminal trong VS Code (`Ctrl + \``) và chạy:
   ```bash
   dotnet run --urls "http://0.0.0.0:5000"
   ```
4. Truy cập giao diện Swagger API trực tiếp trên trình duyệt tại:
   👉 **http://localhost:5000/**

---

### 2. Phía Frontend: Mở trên Android Studio (`nhdphuong_1787_app`)
1. Khởi động **Android Studio**.
2. Chọn **File** $\rightarrow$ **Open...** $\rightarrow$ Trỏ đến thư mục:
   ```text
   nhdphuong_1787_KtraGK/nhdphuong_1787_app
   ```
3. Android Studio sẽ tự động nhận diện đây là một **Flutter Project** chuẩn (do được tạo bằng lệnh `flutter create`).
4. Kiểm tra file `.env` tại thư mục gốc của app:
   ```env
   # Kết nối từ Android Emulator đến máy host:
   BASE_URL=http://10.0.2.2:5000/api/

   # Nếu chạy trên điện thoại thật cùng mạng WiFi, thay bằng IP máy tính (VD: http://192.168.1.15:5000/api/)
   ```
5. Chọn thiết bị **Android Emulator** hoặc điện thoại thật $\rightarrow$ Bấm nút **Run (Shift + F10)**.

---

## IV. Cấu Trúc Toàn Bộ Thư Mục Mã Nguồn

```text
nhdphuong_1787_KtraGK/
├── README.md                                          # Tài liệu hướng dẫn chấm điểm chi tiết này
├── docs/superpowers/
│   ├── specs/2026-10-22-child-phone-guard-design.md   # Bản đặc tả thiết kế kiến trúc hệ thống
│   └── plans/2026-10-22-child-phone-guard.md          # Kế hoạch thực hiện từng bước
│
├── nhdphuong_1787_api/                                # [BE] ASP.NET Core 10 Web API (VS Code)
│   ├── Controllers/
│   │   ├── AuthenticateController.cs                  # Đăng ký, Đăng nhập, Gửi & Xác thực OTP
│   │   ├── ChildProfileApiController.cs               # CRUD Bé & Thiết bị, GPS, Khóa từ xa
│   │   ├── AppRuleApiController.cs                    # CRUD Quy tắc chặn/giới hạn App & Web
│   │   ├── ScreenTimeApiController.cs                 # CRUD Lịch biểu dùng máy trong tuần
│   │   ├── StaffCatalogApiController.cs               # Quản lý Thư viện mẫu an toàn (Staff)
│   │   └── AlertLogApiController.cs                   # API ghi nhận cảnh báo vi phạm
│   ├── Models/
│   │   ├── User.cs                                    # IdentityUser mở rộng (FullName, Role)
│   │   ├── ChildProfile.cs                            # Model hồ sơ bé & tọa độ GPS
│   │   ├── AppRule.cs                                 # Model quy tắc ứng dụng
│   │   ├── ScreenTimeSchedule.cs                      # Model lịch biểu
│   │   ├── AlertLog.cs                                # Model cảnh báo vi phạm
│   │   └── ApplicationDbContext.cs                    # PostgreSQL DbContext
│   ├── Services/
│   │   ├── ISmsGatewayService.cs
│   │   └── SmsGatewayService.cs                       # Kết nối SIMGATE Gateway
│   ├── Program.cs                                     # Role Seeding & Swagger cấu hình
│   └── appsettings.json
│
└── nhdphuong_1787_app/                                # [FE] Flutter Mobile App (Android Studio)
    ├── .env                                           # Cấu hình BASE_URL
    ├── pubspec.yaml                                   # flutter_map, local_auth, smart_auth, qr_flutter...
    └── lib/
        ├── config/config_url.dart                     # Quản lý tập trung các URL endpoint
        ├── models/                                    # Dart Models tương ứng Backend
        ├── services/                                  # ApiClient, TokenService, AuthService, ChildService
        ├── screens/
        │   ├── login_screen.dart                      # Đăng nhập & Vân tay local_auth
        │   ├── registration_screen.dart               # Đăng ký tài khoản
        │   ├── otp_verification_screen.dart           # Xác thực SMS OTP + Nút giả lập test
        │   ├── admin_screen.dart                      # Giao diện Quản trị viên (Admin)
        │   ├── staff_screen.dart                      # Giao diện Nhân viên Kỹ thuật (Staff)
        │   ├── parent_dashboard_screen.dart           # Dashboard Phụ huynh (Parent)
        │   ├── live_map_screen.dart                   # Bản đồ GPS OpenStreetMap & Vùng an toàn
        │   ├── noise_meter_screen.dart                # Đo tiếng ồn Decibel micro (dB)
        │   └── kid_mode_simulator_screen.dart         # Máy con: Cảnh báo mắt AI, Quét QR, Khóa màn hình
        └── widgets/                                   # ChildCard, Dialogs, EyeCareOverlay
```

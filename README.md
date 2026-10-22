# HƯỚNG DẪN MỞ VÀ CHẠY FLUTTER APP TRÊN ANDROID STUDIO

1. Khởi động **Android Studio**.
2. Chọn **File** $\rightarrow$ **Open...** $\rightarrow$ Trỏ đến thư mục:
   ```text
   nhdphuong_1787_KtraGK/nhdphuong_1787_app
   ```
3. Android Studio sẽ tự động nhận diện đây là một **Flutter Project** chuẩn.
4. Kiểm tra file `.env`:
   - Kết nối máy ảo Android Emulator: `BASE_URL=http://10.0.2.2:5000/api/`
   - Hoặc kết nối qua điện thoại thật: `BASE_URL=http://<IP_MÁY_TÍNH>:5000/api/`
5. Chọn thiết bị Android Emulator hoặc điện thoại $\rightarrow$ Bấm nút **Run (Shift + F10)**.

## Tài khoản Test nhanh trên giao diện:
- Có sẵn 3 nút ActionChip: **Phụ huynh**, **Admin**, **Staff** để tự động điền Username/Password.
- Xác thực OTP có sẵn nút **"⚡ Giả lập nhận SMS OTP (Test)"** để Thầy kiểm tra ngay trên máy ảo.

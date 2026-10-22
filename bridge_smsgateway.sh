#!/bin/bash
# ==============================================================================
# Script tự động giữ kết nối Cloud Tunnel cho SIM Gateway trên điện thoại Z2464N
# Giúp Render Cloud API bắn tin nhắn SMS OTP thật qua điện thoại
# ==============================================================================

LOG_FILE="/tmp/smsgate_cloudflared.log"
RENDER_API="https://nhdphuong-1787-api.onrender.com/api/Authenticate/smsgateway-url"

# 1. Ưu tiên mở ADB forward nếu cắm cáp USB (Điện thoại hoàn toàn không cần bật WiFi)
if command -v adb > /dev/null 2>&1; then
    adb forward tcp:8080 tcp:8080 > /dev/null 2>&1
fi

# 2. Tự động phát hiện cổng kết nối (qua cáp USB hoặc qua WiFi LAN)
if curl -s -m 2 -u "sms:0vzi2T1_" "http://127.0.0.1:8080/" | grep -q "status"; then
    SMSGATE_LOCAL="http://127.0.0.1:8080"
    echo "📱 Đã kết nối SIM Gateway qua cáp USB (127.0.0.1:8080) - Không cần bật WiFi!"
elif curl -s -m 2 -u "sms:0vzi2T1_" "http://192.168.1.219:8080/" | grep -q "status"; then
    SMSGATE_LOCAL="http://192.168.1.219:8080"
    echo "📱 Đã kết nối SIM Gateway qua mạng WiFi LAN (192.168.1.219:8080)"
else
    SMSGATE_LOCAL="http://127.0.0.1:8080"
    echo "⚠️ Chưa thấy phản hồi từ SIM Gateway. Vui lòng kiểm tra app SMS Gateway trên máy."
fi

# Khởi chạy cloudflared nếu chưa chạy
if ! pgrep -f "cloudflared tunnel --url $SMSGATE_LOCAL" > /dev/null 2>&1; then
    echo "🌐 Đang khởi tạo Cloudflare Tunnel cho SIM Gateway..."
    setsid /home/nguyenphuong/.local/bin/cloudflared tunnel --url "$SMSGATE_LOCAL" > "$LOG_FILE" 2>&1 &
    sleep 4
fi

TUNNEL_URL=$(grep -o "https://[a-zA-Z0-9.-]*\.trycloudflare\.com" "$LOG_FILE" | tail -n 1)

if [ -n "$TUNNEL_URL" ]; then
    echo "✅ SIM Gateway Cloud Tunnel: $TUNNEL_URL"
    echo "📡 Đang đồng bộ URL lên Render Cloud API ($RENDER_API)..."
    RESP=$(curl -s -X POST "$RENDER_API" \
      -H "Content-Type: application/json" \
      -d "{\"url\": \"$TUNNEL_URL\"}")
    echo "🎉 Kết quả Render Cloud: $RESP"
else
    echo "⚠️ Chưa lấy được URL tunnel từ $LOG_FILE"
fi

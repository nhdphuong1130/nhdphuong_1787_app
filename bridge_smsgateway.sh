#!/bin/bash
# ==============================================================================
# Script tự động giữ kết nối Cloud Tunnel cho SIM Gateway trên điện thoại Z2464N
# Giúp Render Cloud API bắn tin nhắn SMS OTP thật qua điện thoại
# ==============================================================================

SMSGATE_LOCAL="http://192.168.1.219:8080"
LOG_FILE="/tmp/smsgate_cloudflared.log"
RENDER_API="https://nhdphuong-1787-api.onrender.com/api/Authenticate/smsgateway-url"

echo "📱 Đang kiểm tra SIM Gateway trên điện thoại ($SMSGATE_LOCAL)..."
if ! curl -s -m 2 -u "sms:0vzi2T1_" "$SMSGATE_LOCAL/" | grep -q "status"; then
    echo "⚠️ Không kết nối được SIM Gateway tại $SMSGATE_LOCAL. Vui lòng đảm bảo điện thoại bật app SMS Gateway và cùng mạng WiFi."
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

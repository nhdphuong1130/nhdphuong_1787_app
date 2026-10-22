#!/bin/bash

# ==============================================================================
# Script tự động khởi chạy ASP.NET Core API cho đồ án Child Phone Guard (1787)
# Tự động kích hoạt khi bấm nút Run (Chạy) trong Android Studio / Flutter
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=5000
API_URL="http://127.0.0.1:$PORT/api/Authenticate/login"
LOG_FILE="/tmp/nhdphuong_1787_api.log"

# Tìm thư mục API
if [ -d "$SCRIPT_DIR/../nhdphuong_1787_api" ]; then
    API_PATH="$(cd "$SCRIPT_DIR/../nhdphuong_1787_api" && pwd)"
elif [ -d "$SCRIPT_DIR/nhdphuong_1787_api" ]; then
    API_PATH="$(cd "$SCRIPT_DIR/nhdphuong_1787_api" && pwd)"
else
    API_PATH="/home/nguyenphuong/Documents/nhdphuong_1787_KtraGK/nhdphuong_1787_api"
fi

echo "========================================================="
echo "⚡ [Auto-API 1787] Đang kiểm tra trạng thái Backend API..."
echo "========================================================="

# 1. Kiểm tra xem API đã chạy chưa
API_RUNNING=0
if curl -s -m 2 "$API_URL" > /dev/null 2>&1; then
    API_RUNNING=1
elif lsof -i :$PORT > /dev/null 2>&1; then
    API_RUNNING=1
fi

if [ $API_RUNNING -eq 1 ]; then
    echo "✅ [Auto-API 1787] ASP.NET Core API đã ĐANG CHẠY sẵn sàng tại http://127.0.0.1:$PORT"
else
    echo "🚀 [Auto-API 1787] API chưa chạy. Đang tự động khởi động tại: $API_PATH..."
    (cd "$API_PATH" && setsid dotnet run --urls "http://0.0.0.0:$PORT" </dev/null > "$LOG_FILE" 2>&1 &)
    
    # Đợi API phản hồi tối đa 15 giây
    MAX_WAIT=15
    WAITED=0
    while [ $WAITED -lt $MAX_WAIT ]; do
        sleep 1
        WAITED=$((WAITED + 1))
        if curl -s -m 1 "$API_URL" > /dev/null 2>&1 || lsof -i :$PORT > /dev/null 2>&1; then
            echo "✅ [Auto-API 1787] Backend API đã khởi động xong sau ${WAITED}s!"
            break
        fi
        echo "   ... chờ API khởi động (${WAITED}s/${MAX_WAIT}s)"
    done
fi

# 2. Tự động cấu hình ADB Reverse tcp:5000 cho các thiết bị Android (máy thật + máy ảo)
if command -v adb > /dev/null 2>&1; then
    DEVICES=$(adb devices 2>/dev/null | grep -w "device" | awk '{print $1}')
    if [ -n "$DEVICES" ]; then
        for DEV in $DEVICES; do
            adb -s "$DEV" reverse tcp:$PORT tcp:$PORT > /dev/null 2>&1
            adb -s "$DEV" forward tcp:8080 tcp:8080 > /dev/null 2>&1
            echo "📱 [Auto-API 1787] Đã mở ADB reverse tcp:$PORT & forward tcp:8080 (SIMGATE) cho thiết bị: $DEV"
        done
    fi
fi

# 3. Kiểm tra Cloudflare Tunnel (hỗ trợ ghép nối 2 máy qua mạng ngoài)
if command -v cloudflared > /dev/null 2>&1; then
    if ! pgrep -f "cloudflared tunnel" > /dev/null 2>&1; then
        echo "🌐 [Auto-API 1787] Đang bật Cloudflare Tunnel ngầm..."
        setsid cloudflared tunnel --url "http://127.0.0.1:$PORT" </dev/null > /tmp/nhdphuong_cloudflared.log 2>&1 &
    else
        echo "🌐 [Auto-API 1787] Cloudflare Tunnel đang hoạt động sẵn sàng."
    fi
fi

# 4. Kích hoạt Cloud Bridge cho SIM Gateway (Render Cloud API -> Điện thoại gửi SMS thật)
if [ -f "$SCRIPT_DIR/bridge_smsgateway.sh" ]; then
    bash "$SCRIPT_DIR/bridge_smsgateway.sh" > /dev/null 2>&1 &
fi

echo "========================================================="
echo "🎉 [Auto-API 1787] Hoàn tất chuẩn bị! Khởi chạy Flutter..."
echo "========================================================="
exit 0

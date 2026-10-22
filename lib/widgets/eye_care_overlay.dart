import 'package:flutter/material.dart';

class EyeCareOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  final String distanceText;
  final double distanceCm;

  const EyeCareOverlay({
    super.key,
    required this.onDismiss,
    this.distanceText = '18 cm',
    this.distanceCm = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final isSafe = distanceCm >= 28.0;
    final progress = (distanceCm / 35.0).clamp(0.0, 1.0);

    return Container(
      color: Colors.black.withValues(alpha: 0.94),
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon cảnh báo mắt
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isSafe ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: isSafe ? Colors.green : Colors.redAccent, width: 3),
              ),
              child: Icon(
                isSafe ? Icons.check_circle : Icons.visibility,
                size: 72,
                color: isSafe ? Colors.greenAccent : Colors.amber,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isSafe ? '✅ KHOẢNG CÁCH ĐÃ AN TOÀN!' : '👀 ÔI KHÔNG! QUÁ GẦN MẮT RỒI!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSafe ? Colors.greenAccent : Colors.amber,
                fontSize: 21,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),

            // Badge khoảng cách thời gian thực
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSafe ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSafe ? Colors.green : Colors.redAccent),
              ),
              child: Text(
                'Khoảng cách: $distanceText ${isSafe ? "(Đạt chuẩn)" : "(Nguy hiểm < 25cm)"}',
                style: TextStyle(
                  color: isSafe ? Colors.greenAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Thanh tiến trình đo cự ly mắt trực quan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSafe ? Colors.greenAccent : (distanceCm > 22 ? Colors.orange : Colors.redAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('10cm (Dí sát)', style: TextStyle(color: Colors.white54, fontSize: 10)),
                      Text('25cm (Ngưỡng)', style: TextStyle(color: Colors.amberAccent, fontSize: 10)),
                      Text('35cm (An toàn)', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hướng dẫn hành động
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Text(
                    '👉 Hãy đưa điện thoại ra xa ít nhất 30cm',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Màn hình sẽ TỰ ĐỘNG MỞ KHÓA ngay khi bé giữ khoảng cách an toàn với điện thoại.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nút hỗ trợ kiểm tra lại
            FilledButton.icon(
              onPressed: () {
                if (isSafe) {
                  onDismiss();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚠️ Mắt vẫn đang quá gần ($distanceText)! Bé hãy đẩy máy ra xa thêm một chút nhé.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: isSafe ? Colors.green : Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: Icon(isSafe ? Icons.check_circle : Icons.refresh),
              label: Text(
                isSafe ? 'Mở Khóa Ngay (Đã An Toàn)' : 'Đang phát hiện: $distanceText',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class EyeCareOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  final String distanceText;

  const EyeCareOverlay({
    super.key,
    required this.onDismiss,
    this.distanceText = '18 cm',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      padding: const EdgeInsets.all(28.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.visibility,
                size: 80,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '👀 ÔI KHÔNG! QUÁ GẦN MẮT RỒI!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.amber,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Text(
                'Khoảng cách phát hiện: $distanceText (Cự ly nguy hiểm < 25cm)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Việc dí sát màn hình vào mắt sẽ làm tăng nguy cơ cận thị và thoái hóa điểm vàng.\n\n👉 Hãy đưa điện thoại ra xa ít nhất 30cm để bảo vệ đôi mắt sáng nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onDismiss,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'Con đã đưa máy ra xa (≥30cm)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

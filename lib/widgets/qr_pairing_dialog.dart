import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPairingDialog extends StatelessWidget {
  final String childName;
  final String pairingCode;
  final String childUsername;
  final String childPassword;

  const QrPairingDialog({
    super.key,
    required this.childName,
    required this.pairingCode,
    this.childUsername = 'bebo1787',
    this.childPassword = 'Password123@',
  });

  @override
  Widget build(BuildContext context) {
    final qrData = 'CHILDGUARD_PAIR:$pairingCode';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.qr_code_2, color: Colors.indigo, size: 28),
          const SizedBox(width: 8),
          Expanded(child: Text('Ghép Nối Máy Bé $childName')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bé có thể dùng 1 trong 3 cách sau trên điện thoại của mình để kích hoạt bảo vệ:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 190.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Mã 6 số
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.indigo[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Mã 6 số: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    pairingCode,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Khung tài khoản do phụ huynh cấp cho bé
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge, size: 16, color: Colors.deepPurple),
                      SizedBox(width: 6),
                      Text('Tài khoản bạn đã cấp cho bé:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepPurple)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('• Tên đăng nhập: ${childUsername.isNotEmpty ? childUsername : "bebo1787"}', style: const TextStyle(fontSize: 12)),
                  Text('• Mật khẩu: ${childPassword.isNotEmpty ? childPassword : "Password123@"}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

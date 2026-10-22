import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPairingDialog extends StatelessWidget {
  final String childName;
  final String pairingCode;

  const QrPairingDialog({
    super.key,
    required this.childName,
    required this.pairingCode,
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
              'Mở ứng dụng trên điện thoại của bé, chọn "Quét mã QR" hoặc nhập mã bên dưới để liên kết quản lý:',
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
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.indigo[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Mã ghép nối: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    pairingCode,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.indigo,
                    ),
                  ),
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

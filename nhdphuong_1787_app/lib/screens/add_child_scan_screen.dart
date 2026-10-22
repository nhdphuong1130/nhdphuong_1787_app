import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/child_profile.dart';
import '../services/child_service.dart';

class AddChildScanScreen extends StatefulWidget {
  final VoidCallback? onSaved;

  const AddChildScanScreen({super.key, this.onSaved});

  @override
  State<AddChildScanScreen> createState() => _AddChildScanScreenState();
}

class _AddChildScanScreenState extends State<AddChildScanScreen> {
  int _currentStep = 0; // 0: Quét mã QR, 1: Nhập thông tin bé
  String _scannedCode = '';
  final MobileScannerController _scannerController = MobileScannerController();

  // Controllers cho form nhập thông tin bé ở Bước 2
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController(text: '8');
  final TextEditingController _deviceCtrl = TextEditingController(text: 'Android Phone (Máy Thật)');
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController(text: 'Password123@');

  String _avatar = 'boy';
  bool _isLoading = false;
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _deviceCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onCodeDetected(String code) {
    if (_hasScanned) return;
    _hasScanned = true;
    final cleanCode = code.replaceAll('CHILDGUARD_PAIR:', '').trim();

    setState(() {
      _scannedCode = cleanCode;
      _currentStep = 1; // Chuyển sang Bước 2: Nhập thông tin
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📷 Đã quét thành công mã máy con: $cleanCode'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showManualCodeDialog() {
    final manualCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập Mã Ghép Nối Thủ Công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nếu máy ảo không có Camera, bạn có thể gõ mã 6 số hiển thị trên máy con:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Mã Bé Bo: 178701'),
                  onPressed: () => manualCtrl.text = '178701',
                ),
                ActionChip(
                  label: const Text('Mã Bé Na: 178702'),
                  onPressed: () => manualCtrl.text = '178702',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: manualCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mã số ghép nối (6 chữ số)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (manualCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                _onCodeDetected(manualCtrl.text.trim());
              }
            },
            child: const Text('Tiếp Tục'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChildProfile() async {
    final fullName = _nameCtrl.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên của bé!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Tự sinh username nếu để trống
    String username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      username = 'be${DateTime.now().millisecondsSinceEpoch % 10000}';
    }

    final newChild = ChildProfile(
      id: 0,
      parentId: '',
      fullName: fullName,
      age: int.tryParse(_ageCtrl.text) ?? 8,
      avatarUrl: _avatar,
      deviceName: _deviceCtrl.text.trim().isNotEmpty ? _deviceCtrl.text.trim() : 'Android Phone',
      deviceModel: 'Android Device',
      pairingCode: _scannedCode.isNotEmpty ? _scannedCode : '178701',
      childUsername: username,
      childPassword: _passwordCtrl.text.trim().isNotEmpty ? _passwordCtrl.text.trim() : 'Password123@',
      batteryLevel: 85,
      isOnline: true,
      isLocked: false,
      lastKnownLat: 10.762622,
      lastKnownLng: 106.660172,
      updatedAt: DateTime.now(),
    );

    final success = await ChildService.createChild(newChild);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đã thêm hồ sơ và liên kết máy thành công với $fullName!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSaved?.call();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Không thể thêm hồ sơ bé! Vui lòng thử lại.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0 ? 'Bước 1: Quét Mã Máy Con' : 'Bước 2: Nhập Thông Tin Bé'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_currentStep == 0)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Nhập mã số thủ công (Test)',
              onPressed: _showManualCodeDialog,
            ),
        ],
      ),
      body: _currentStep == 0 ? _buildScannerStep() : _buildFormStep(),
    );
  }

  /// BƯỚC 1: BẬT CAMERA QUÉT MÃ QR TỪ MÁY CON
  Widget _buildScannerStep() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            for (final barcode in capture.barcodes) {
              final raw = barcode.rawValue;
              if (raw != null && raw.isNotEmpty) {
                _onCodeDetected(raw);
                break;
              }
            }
          },
        ),

        // Khung kính ngắm
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amberAccent, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // Hướng dẫn ở trên
        Positioned(
          top: 24,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Icon(Icons.qr_code_scanner, color: Colors.amberAccent, size: 28),
                SizedBox(height: 6),
                Text(
                  'Hướng Camera vào Mã QR trên màn hình máy con',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Sau khi quét xong mã thiết bị, bạn sẽ nhập tên và thông tin của bé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        // Nút hỗ trợ bên dưới
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: _showManualCodeDialog,
                icon: const Icon(Icons.keyboard, size: 18),
                label: const Text('Không quét được? Nhập mã 6 số thủ công'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.flash_on),
                      onPressed: () => _scannerController.toggleTorch(),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.cameraswitch),
                      onPressed: () => _scannerController.switchCamera(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// BƯỚC 2: NHẬP THÔNG TIN CỦA BÉ SAU KHI ĐÃ QUÉT MÃ
  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner thông báo đã quét mã thành công
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đã liên kết mã máy con thành công!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                      ),
                      Text(
                        'Mã thiết bị: $_scannedCode',
                        style: TextStyle(fontSize: 12, color: Colors.green[900]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _hasScanned = false;
                    _currentStep = 0;
                  }),
                  child: const Text('Quét lại', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chọn hình đại diện
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('👦 Bé Trai'),
                selected: _avatar == 'boy',
                onSelected: (s) => setState(() => _avatar = 'boy'),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('👧 Bé Gái'),
                selected: _avatar == 'girl',
                onSelected: (s) => setState(() => _avatar = 'girl'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Họ và tên của bé *',
              hintText: 'VD: Bé Bông, Bé Tin...',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              if (_usernameCtrl.text.isEmpty || _usernameCtrl.text.startsWith('be')) {
                final normalized = val.toLowerCase().replaceAll(' ', '');
                _usernameCtrl.text = normalized.isNotEmpty ? '${normalized}1787' : '';
              }
            },
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tuổi của bé',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _deviceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên thiết bị con',
                    prefixIcon: Icon(Icons.phone_android),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Khung thiết lập tài khoản cấp cho con
          Card(
            color: Colors.deepPurple[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge, color: Colors.deepPurple, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cấp Tài Khoản Cho Bé Đăng Nhập:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bé có thể dùng tài khoản này để đăng nhập trực tiếp trên điện thoại con.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập của bé',
                      hintText: 'bebong1787',
                      prefixIcon: Icon(Icons.account_circle),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu cấp cho bé',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isLoading ? null : _saveChildProfile,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: const Text('LƯU & KẾT NỐI HỒ SƠ BÉ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

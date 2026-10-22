import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/child_profile.dart';
import '../services/child_service.dart';

class AddChildScanScreen extends StatefulWidget {
  final VoidCallback? onSaved;

  const AddChildScanScreen({super.key, this.onSaved});

  @override
  State<AddChildScanScreen> createState() => _AddChildScanScreenState();
}

class _AddChildScanScreenState extends State<AddChildScanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers cho form tạo tài khoản trực tiếp
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController(text: '8');
  final TextEditingController _deviceCtrl = TextEditingController(text: 'Điện thoại của bé');
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController(text: 'Password123@');

  // Scanner state
  String _scannedCode = '';
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;

  String _avatar = 'boy';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      _tabController.animateTo(0); // Chuyển sang Tab Tạo Tài Khoản & áp mã đã quét
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📷 Đã nhận diện mã máy con: $cleanCode! Hãy kiểm tra thông tin tài khoản bên dưới.'),
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
              'Nếu máy con hiển thị mã số 6 chữ số, bạn có thể gõ vào đây để liên kết:',
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
        const SnackBar(content: Text('Vui lòng nhập họ và tên của bé!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Tự sinh username nếu phụ huynh để trống
    String username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      final clean = fullName.toLowerCase().replaceAll(' ', '').replaceAll('bé', 'be');
      username = clean.isNotEmpty ? '${clean}1787' : 'be${DateTime.now().millisecondsSinceEpoch % 10000}';
    }

    final password = _passwordCtrl.text.trim().isNotEmpty ? _passwordCtrl.text.trim() : 'Password123@';

    final newChild = ChildProfile(
      id: 0,
      parentId: '',
      fullName: fullName,
      age: int.tryParse(_ageCtrl.text) ?? 8,
      avatarUrl: _avatar,
      deviceName: _deviceCtrl.text.trim().isNotEmpty ? _deviceCtrl.text.trim() : 'Điện thoại của bé',
      deviceModel: 'Android Device',
      pairingCode: _scannedCode.isNotEmpty ? _scannedCode : '',
      childUsername: username,
      childPassword: password,
      batteryLevel: 85,
      isOnline: true,
      isLocked: false,
      lastKnownLat: 0.0,
      lastKnownLng: 0.0,
      updatedAt: DateTime.now(),
    );

    final createdChild = await ChildService.createChildWithResult(newChild);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (createdChild != null) {
      widget.onSaved?.call();
      _showSuccessDialog(createdChild);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Không thể tạo tài khoản bé! Vui lòng thử lại.'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog(ChildProfile child) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('Tạo Tài Khoản Thành Công!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Đã cấp tài khoản quản lý và bảo vệ cho bé ${child.fullName}:',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),

              // Thẻ thông tin đăng nhập
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_circle, size: 18, color: Colors.indigo),
                        const SizedBox(width: 6),
                        const Text('Tên đăng nhập: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        SelectableText(
                          child.childUsername,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.lock, size: 18, color: Colors.indigo),
                        const SizedBox(width: 6),
                        const Text('Mật khẩu: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        SelectableText(
                          child.childPassword,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.pin, size: 18, color: Colors.indigo),
                        const SizedBox(width: 6),
                        const Text('Mã ghép nối 6 số: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        SelectableText(
                          child.pairingCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Mã QR cho máy con quét vào
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: 'CHILDGUARD_PAIR:${child.pairingCode}',
                  version: QrVersions.auto,
                  size: 150.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bé chỉ cần mở App trên máy con, nhập Tên đăng nhập & Mật khẩu ở trên hoặc quét mã QR này.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              final info = 'Tài khoản ChildGuard của bé ${child.fullName}:\n- Tên đăng nhập: ${child.childUsername}\n- Mật khẩu: ${child.childPassword}\n- Mã ghép nối: ${child.pairingCode}';
              Clipboard.setData(ClipboardData(text: info));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📋 Đã sao chép thông tin tài khoản bé vào bộ nhớ tạm!'), backgroundColor: Colors.indigo),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Sao Chép'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Hoàn Tất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấp Tài Khoản Cho Con', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3730A3),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person_add_alt_1_rounded), text: 'Tạo Tài Khoản Bé'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Quét QR Máy Con'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormStep(),
          _buildScannerStep(),
        ],
      ),
    );
  }

  /// TAB 1: FORM TẠO TÀI KHOẢN TRỰC TIẾP CHO BÉ
  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_scannedCode.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đã liên kết mã thiết bị con: $_scannedCode',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => setState(() => _scannedCode = ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

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
          const SizedBox(height: 16),

          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Họ và tên của bé *',
              hintText: 'VD: Bé Bo, Bé Bông, Nguyễn Văn An...',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              if (_usernameCtrl.text.isEmpty || _usernameCtrl.text.startsWith('be')) {
                final normalized = val.toLowerCase().replaceAll(' ', '').replaceAll('bé', 'be');
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
            elevation: 0,
            color: const Color(0xFFF5F3FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFDDD6FE)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge_rounded, color: Color(0xFF6D28D9), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Cấp Tài Khoản Cho Bé Đăng Nhập:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6D28D9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Phụ huynh thiết lập Tên đăng nhập & Mật khẩu này để bé đăng nhập trên điện thoại của mình.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập cấp cho bé *',
                      hintText: 'VD: bebo1787, bebong1787...',
                      prefixIcon: Icon(Icons.account_circle, color: Color(0xFF6D28D9)),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu cấp cho bé *',
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF6D28D9)),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3730A3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isLoading ? null : _saveChildProfile,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.how_to_reg_rounded),
            label: const Text('TẠO TÀI KHOẢN CHO BÉ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  /// TAB 2: BẬT CAMERA QUÉT MÃ QR NẾU MÁY CON CÓ SẴN
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
                  'Sau khi quét xong mã thiết bị, hệ thống sẽ tự động liên kết máy.',
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
                label: const Text('Nhập mã 6 số thủ công (Nếu máy con hiển thị số)'),
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
}

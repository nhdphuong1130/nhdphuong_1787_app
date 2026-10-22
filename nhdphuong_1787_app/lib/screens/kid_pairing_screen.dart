import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/child_service.dart';
import 'kid_mode_simulator_screen.dart';

class KidPairingScreen extends StatefulWidget {
  const KidPairingScreen({super.key});

  @override
  State<KidPairingScreen> createState() => _KidPairingScreenState();
}

class _KidPairingScreenState extends State<KidPairingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _usernameController = TextEditingController(text: 'bebo1787');
  final TextEditingController _passwordController = TextEditingController(text: 'Password123@');
  final TextEditingController _codeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _hasScanned = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleSuccess(int childId, String childName, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('paired_child_id', childId);
    await prefs.setString('paired_child_name', childName);
    await prefs.setString('paired_code', code);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Kích hoạt máy của $childName thành công!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => KidModeSimulatorScreen(
          childId: childId,
          childName: childName,
        ),
      ),
    );
  }

  // 1. Đăng nhập bằng tài khoản do phụ huynh cấp
  Future<void> _loginChildAccount() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập tên tài khoản và mật khẩu của bé!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ChildService.kidLogin(
      username: username,
      password: password,
      deviceName: 'Android Z2464N (Máy Thật)',
      deviceModel: 'P780F01',
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final childId = res['childProfileId'] as int;
      final childName = res['childName'] as String? ?? 'Bé Yêu';
      final code = res['pairingCode'] as String? ?? '178701';
      await _handleSuccess(childId, childName, code);
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Đăng nhập tài khoản bé thất bại!';
        _isLoading = false;
      });
    }
  }

  // 2. Ghép nối bằng mã 6 số hoặc QR code
  Future<void> _performPair(String code) async {
    final cleanCode = code.replaceAll('CHILDGUARD_PAIR:', '').trim();
    if (cleanCode.length < 4) {
      setState(() => _errorMessage = 'Vui lòng nhập đúng mã ghép nối 6 chữ số!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ChildService.pairDevice(
      pairingCode: cleanCode,
      deviceName: 'Android Z2464N (Máy Thật)',
      deviceModel: 'P780F01',
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final childId = res['childProfileId'] as int;
      final childName = res['childName'] as String? ?? 'Bé Yêu';
      await _handleSuccess(childId, childName, cleanCode);
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Ghép nối thất bại!';
        _isLoading = false;
        _hasScanned = false;
      });
    }
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_hasScanned || _isLoading) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _hasScanned = true;
        _performPair(rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kích Hoạt Máy Trẻ Em (Kid Guard)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.badge), text: 'Tài Khoản Bé'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Quét Mã QR'),
            Tab(icon: Icon(Icons.pin), text: 'Mã 6 Số'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: ĐĂNG NHẬP BẰNG TÀI KHOẢN DO BỐ MẸ CẤP
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.child_care, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tài Khoản Do Phụ Huynh Cấp',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nhập tài khoản và mật khẩu của con mà cha mẹ đã cấp trên ứng dụng quản lý:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Nút điền nhanh tài khoản bé mẫu
                Card(
                  color: Colors.deepPurple[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tài khoản bé mẫu do phụ huynh cấp sẵn:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.person, size: 14),
                              label: const Text('Bé Bo: bebo1787'),
                              onPressed: () {
                                setState(() {
                                  _usernameController.text = 'bebo1787';
                                  _passwordController.text = 'Password123@';
                                });
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.person, size: 14),
                              label: const Text('Bé Na: bena1787'),
                              onPressed: () {
                                setState(() {
                                  _usernameController.text = 'bena1787';
                                  _passwordController.text = 'Password123@';
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tài khoản của con',
                    hintText: 'bebo1787',
                    prefixIcon: Icon(Icons.person_pin),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu của con',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _loginChildAccount,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.login),
                  label: const Text('ĐĂNG NHẬP & KÍCH HOẠT BẢO VỆ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // TAB 2: QUÉT MÃ QR BẰNG CAMERA
          Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onQrDetected,
              ),
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amberAccent, width: 3),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.transparent,
                  ),
                ),
              ),
              Positioned(
                top: 24,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '📷 Hướng Camera vào Mã QR trên màn hình máy phụ huynh',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          color: Colors.white,
                          icon: const Icon(Icons.flash_on),
                          onPressed: () => _scannerController.toggleTorch(),
                        ),
                        IconButton(
                          color: Colors.white,
                          icon: const Icon(Icons.cameraswitch),
                          onPressed: () => _scannerController.switchCamera(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text('Đang xác thực mã ghép nối...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // TAB 3: NHẬP MÃ GHÉP NỐI 6 SỐ
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.phonelink_ring, size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text(
                  'Nhập Mã Ghép Nối 6 Chữ Số',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Xem mã này tại mục "Xem mã QR ghép nối" trong hồ sơ của bé trên máy phụ huynh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),

                Card(
                  color: Colors.deepPurple[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gợi ý mã có sẵn trong Database:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.child_care, size: 14),
                              label: const Text('Bé Bo (Mã: 178701)'),
                              onPressed: () => setState(() => _codeController.text = '178701'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.face_3, size: 14),
                              label: const Text('Bé Na (Mã: 178702)'),
                              onPressed: () => setState(() => _codeController.text = '178702'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.deepPurple),
                  decoration: const InputDecoration(
                    labelText: 'Mã ghép nối (6 chữ số)',
                    hintText: '178701',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 12),

                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : () => _performPair(_codeController.text),
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.link),
                  label: const Text('XÁC NHẬN GHÉP NỐI VỚI PHỤ HUYNH', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

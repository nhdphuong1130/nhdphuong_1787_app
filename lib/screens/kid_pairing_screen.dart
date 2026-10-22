import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/child_service.dart';
import 'kid_mode_simulator_screen.dart';

/// Màn hình Kích Hoạt Máy Trẻ Em (Kid Pairing Screen)
/// Theo đúng nghiệp vụ: Máy con chỉ CUNG CẤP mã QR & mã OTP (6 số) để Phụ huynh quét/nhập.
/// Con không có quyền gì ngoài việc xuất trình mã hoặc đăng nhập bằng tài khoản Phụ huynh cấp.
class KidPairingScreen extends StatefulWidget {
  const KidPairingScreen({super.key});

  @override
  State<KidPairingScreen> createState() => _KidPairingScreenState();
}

class _KidPairingScreenState extends State<KidPairingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _usernameController = TextEditingController(text: 'bebo1787');
  final TextEditingController _passwordController = TextEditingController(text: 'Password123@');

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Mã ghép nối máy con xuất trình cho Phụ huynh quét
  String _devicePairingCode = '178701';
  Timer? _pairCheckTimer;
  bool _isCheckingPair = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initDeviceCode();
    // Định kỳ kiểm tra xem Phụ huynh đã quét và liên kết thành công chưa mỗi 3s
    _pairCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) => _autoCheckPairStatus());
  }

  Future<void> _initDeviceCode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('paired_code');
    if (savedCode != null && savedCode.isNotEmpty) {
      if (mounted) setState(() => _devicePairingCode = savedCode);
    }
  }

  @override
  void dispose() {
    _pairCheckTimer?.cancel();
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Tự động kiểm tra realtime xem Phụ huynh đã quét mã kết nối chưa
  Future<void> _autoCheckPairStatus() async {
    if (!mounted || _isCheckingPair || _isLoading) return;
    _isCheckingPair = true;
    try {
      final res = await ChildService.checkPairStatus(_devicePairingCode);
      if (res != null && mounted) {
        final isPaired = res['isPaired'] == true;
        if (isPaired && res['childProfileId'] != null) {
          final childId = res['childProfileId'] as int;
          final childName = res['childName'] as String? ?? 'Bé Yêu';
          final code = res['pairingCode'] as String? ?? _devicePairingCode;
          _pairCheckTimer?.cancel();
          await _handleSuccess(childId, childName, code);
        }
      }
    } catch (_) {
    } finally {
      _isCheckingPair = false;
    }
  }

  Future<void> _handleSuccess(int childId, String childName, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('paired_child_id', childId);
    await prefs.setString('paired_child_name', childName);
    await prefs.setString('paired_code', code);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Thiết bị đã được Phụ huynh kết nối thành công! Đang kích hoạt bảo vệ máy cho $childName...'),
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

  /// 1. Đăng nhập bằng tài khoản do phụ huynh cấp trực tiếp
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
      deviceName: 'Android Z2464N (Máy Con)',
      deviceModel: 'P780F01',
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final childId = res['childProfileId'] as int;
      final childName = res['childName'] as String? ?? 'Bé Yêu';
      final code = res['pairingCode'] as String? ?? _devicePairingCode;
      _pairCheckTimer?.cancel();
      await _handleSuccess(childId, childName, code);
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Đăng nhập tài khoản bé thất bại!';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Máy Trẻ Em (Kid Guard)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3730A3),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'Mã QR & OTP Máy Con'),
            Tab(icon: Icon(Icons.badge_rounded), text: 'Đăng Nhập Tài Khoản'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: MÁY CON XUẤT TRÌNH MÃ QR & OTP ĐỂ PHỤ HUYNH QUÉT
          _buildPresentQrTab(),

          // TAB 2: ĐĂNG NHẬP BẰNG TÀI KHOẢN CON DO BA MẸ CẤP
          _buildLoginAccountTab(),
        ],
      ),
    );
  }

  /// TAB 1: MÁY CON CUNG CẤP MÃ QR & OTP ĐỂ PHỤ HUYNH QUÉT KẾT NỐI
  Widget _buildPresentQrTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 16, color: Color(0xFF4338CA)),
                SizedBox(width: 6),
                Text(
                  'Thiết bị trẻ em được bảo vệ bởi Phụ huynh',
                  style: TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Xuất Trình Mã Cho Phụ Huynh Quét',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Phụ huynh mở ứng dụng trên máy Cha Mẹ, bấm "Quét QR Máy Con" và hướng camera vào mã bên dưới để liên kết ngay:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 20),

          // Khung hiển thị QR Code lớn của máy con
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  QrImageView(
                    data: 'CHILDGUARD_PAIR:$_devicePairingCode',
                    version: QrVersions.auto,
                    size: 210.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF3730A3)),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1E1B4B)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Mã Ghép Nối 6 Chữ Số Của Bé:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _devicePairingCode,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Color(0xFF3730A3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                          tooltip: 'Sao chép mã',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _devicePairingCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã sao chép mã ghép nối vào bộ nhớ tạm!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Chọn nhanh mã mẫu cho thầy / bạn test demo
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.swap_horiz, size: 14),
                label: const Text('Mã Bé Bo: 178701'),
                onPressed: () => setState(() => _devicePairingCode = '178701'),
              ),
              ActionChip(
                avatar: const Icon(Icons.swap_horiz, size: 14),
                label: const Text('Mã Bé Na: 178702'),
                onPressed: () => setState(() => _devicePairingCode = '178702'),
              ),
              ActionChip(
                avatar: const Icon(Icons.swap_horiz, size: 14),
                label: const Text('Mã Bé Bông: 779967'),
                onPressed: () => setState(() => _devicePairingCode = '779967'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nút kiểm tra trạng thái kết nối ngay
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3730A3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _autoCheckPairStatus,
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Kiểm Tra Phụ Huynh Đã Kết Nối Chưa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          const Text(
            '🔄 Hệ thống đang tự động dò tìm liên kết từ Phụ huynh mỗi 3 giây...',
            style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  /// TAB 2: ĐĂNG NHẬP BẰNG TÀI KHOẢN CON DO PHỤ HUYNH CẤP
  Widget _buildLoginAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFF3730A3),
              child: Icon(Icons.child_care, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tài Khoản Do Cha Mẹ Cấp',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nhập tên tài khoản và mật khẩu của con mà Phụ huynh đã tạo trên ứng dụng quản lý:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Tên tài khoản của bé',
              hintText: 'VD: bebo1787, bena1787, b1787...',
              prefixIcon: Icon(Icons.account_circle_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu của bé',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Gợi ý tài khoản nhanh
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.bolt, size: 14),
                label: const Text('Bé Bo (bebo1787)'),
                onPressed: () {
                  setState(() {
                    _usernameController.text = 'bebo1787';
                    _passwordController.text = 'Password123@';
                  });
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.bolt, size: 14),
                label: const Text('Bé Na (bena1787)'),
                onPressed: () {
                  setState(() {
                    _usernameController.text = 'bena1787';
                    _passwordController.text = 'Password123@';
                  });
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.bolt, size: 14),
                label: const Text('Bé Bông (b1787)'),
                onPressed: () {
                  setState(() {
                    _usernameController.text = 'b1787';
                    _passwordController.text = 'Password123@';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3730A3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isLoading ? null : _loginChildAccount,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.login),
            label: Text(
              _isLoading ? 'Đang kích hoạt máy...' : 'KÍCH HOẠT MÁY BÉ NGAY',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

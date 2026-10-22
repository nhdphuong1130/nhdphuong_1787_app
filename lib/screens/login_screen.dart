import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../config/config_url.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import 'otp_verification_screen.dart';
import 'registration_screen.dart';
import 'admin_screen.dart';
import 'staff_screen.dart';
import 'parent_dashboard_screen.dart';
import 'kid_mode_simulator_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'parent1787');
  final _passwordController = TextEditingController(text: 'Password123@');
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Kiểm tra Auto-login nếu đã lưu Token hợp lệ
  Future<void> _checkAutoLogin() async {
    final token = await TokenService.getToken();
    if (token != null) {
      final role = await TokenService.getRole();
      if (!mounted) return;
      _navigateByRole(role ?? 'Customer');
    }
  }

  /// Kiểm tra phần cứng sinh trắc học
  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      setState(() => _canCheckBiometrics = canCheck || isSupported);
    } catch (_) {}
  }

  /// Đăng nhập nhanh bằng vân tay (local_auth)
  Future<void> _handleBiometricLogin() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Quét vân tay để đăng nhập nhanh vào Child Guard',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        final token = await TokenService.getToken();
        final role = await TokenService.getRole() ?? 'Customer';

        if (token != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xác thực sinh trắc học thành công!'), backgroundColor: Colors.green),
          );
          _navigateByRole(role);
        } else {
          // Nếu chưa có token lưu trữ, tự động đăng nhập tài khoản phụ huynh mẫu
          _handleLogin();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi sinh trắc học: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateByRole(String role) {
    Widget destination;
    if (role == 'Admin') {
      destination = const AdminScreen();
    } else if (role == 'Staff') {
      destination = const StaffScreen();
    } else {
      destination = const ParentDashboardScreen();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đăng nhập và mật khẩu!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await AuthService.login(username, password);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      // Chuyển sang màn hình xác thực OTP (Bước 2)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            username: username,
            phoneNumber: res['phoneNumber'],
            simulatedOtp: res['simulatedOtp'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Đăng nhập thất bại!'), backgroundColor: Colors.red),
      );
    }
  }

  void _openKidModeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.child_care, color: Colors.deepPurple, size: 28),
                SizedBox(width: 8),
                Text(
                  'Chọn Máy Trẻ Em Để Demo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Điện thoại này sẽ đóng vai trò là "Máy Con", nhận lệnh khóa từ máy ảo (Laptop) và thử nghiệm AI bảo vệ mắt, đo tiếng ồn dB.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ListTile(
              tileColor: Colors.deepPurple[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const CircleAvatar(backgroundColor: Colors.deepPurple, child: Text('Bo', style: TextStyle(color: Colors.white))),
              title: const Text('Bé Bo (ID: 1)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Thiết bị: Samsung Galaxy A15'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KidModeSimulatorScreen(childId: 1, childName: 'Bé Bo')),
                );
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: Colors.pink[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const CircleAvatar(backgroundColor: Colors.pink, child: Text('Na', style: TextStyle(color: Colors.white))),
              title: const Text('Bé Na (ID: 2)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Thiết bị: iPad Gen 9'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KidModeSimulatorScreen(childId: 2, childName: 'Bé Na')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _fillAccount(String username, String pass) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = pass;
    });
  }

  void _showApiConfigDialog() {
    final urlCtrl = TextEditingController(text: ConfigUrl.baseUrl);
    bool isTesting = false;
    String? testResult;
    Color testResultColor = Colors.green;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings_ethernet, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Cấu Hình Địa Chỉ API', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn hoặc nhập URL Web API để kết nối:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'API Base URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Gợi ý kết nối nhanh:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.cloud_done, size: 14, color: Colors.blue),
                      label: const Text('Tunnel (Khuyên dùng)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDlgState(() {
                          urlCtrl.text = 'https://knowing-clicks-ice-financing.trycloudflare.com/api/';
                          testResult = null;
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wifi, size: 14, color: Colors.orange),
                      label: const Text('WiFi LAN (10.12.24.140)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDlgState(() {
                          urlCtrl.text = 'http://10.12.24.140:5000/api/';
                          testResult = null;
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.phone_android, size: 14, color: Colors.green),
                      label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDlgState(() {
                          urlCtrl.text = 'http://10.0.2.2:5000/api/';
                          testResult = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: isTesting
                      ? null
                      : () async {
                          setDlgState(() {
                            isTesting = true;
                            testResult = null;
                          });
                          await ConfigUrl.setCustomBaseUrl(urlCtrl.text.trim());
                          final ok = await ConfigUrl.testConnection();
                          setDlgState(() {
                            isTesting = false;
                            if (ok) {
                              testResult = '✅ Kết nối thành công tới Web API!';
                              testResultColor = Colors.green;
                            } else {
                              testResult = '❌ Không thể kết nối tới URL này!\n(Nếu dùng WiFi chung bị chặn AP isolation, hãy bấm nút "Tunnel (Khuyên dùng)")';
                              testResultColor = Colors.red;
                            }
                          });
                        },
                  icon: isTesting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.network_check, size: 18),
                  label: const Text('Kiểm tra kết nối (Ping API)'),
                ),
                if (testResult != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: testResultColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: testResultColor),
                    ),
                    child: Text(
                      testResult!,
                      style: TextStyle(fontSize: 12, color: testResultColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await ConfigUrl.resetToDefault();
                if (ctx.mounted) Navigator.of(ctx).pop();
                setState(() {});
              },
              child: const Text('Đặt Lại Mặc Định'),
            ),
            FilledButton(
              onPressed: () async {
                if (urlCtrl.text.isNotEmpty) {
                  await ConfigUrl.setCustomBaseUrl(urlCtrl.text.trim());
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã cập nhật URL API thành công: ${ConfigUrl.baseUrl}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Lưu & Áp Dụng'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet, color: Colors.indigo),
            tooltip: 'Cấu hình API URL',
            onPressed: _showApiConfigDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo ứng dụng
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield, size: 48, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CHILD GUARD',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hệ Thống Quản Lý & Bảo Vệ Điện Thoại Trẻ Em',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 28),

                  // Nút điền nhanh tài khoản mẫu để Thầy kiểm tra chấm điểm nhanh
                  Card(
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        children: [
                          const Text('Điền nhanh tài khoản kiểm tra theo Role:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('Phụ huynh', style: TextStyle(fontSize: 11)),
                                avatar: const Icon(Icons.person, size: 14),
                                onPressed: () => _fillAccount('parent1787', 'Password123@'),
                              ),
                              ActionChip(
                                label: const Text('Admin', style: TextStyle(fontSize: 11)),
                                avatar: const Icon(Icons.admin_panel_settings, size: 14),
                                onPressed: () => _fillAccount('admin1787', 'Password123@'),
                              ),
                              ActionChip(
                                label: const Text('Staff', style: TextStyle(fontSize: 11)),
                                avatar: const Icon(Icons.support_agent, size: 14),
                                onPressed: () => _fillAccount('staff1787', 'Password123@'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('ĐĂNG NHẬP (BƯỚC 1: XÁC THỰC MẬT KHẨU)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),

                  // Nút đăng nhập vân tay
                  if (_canCheckBiometrics)
                    OutlinedButton.icon(
                      onPressed: _handleBiometricLogin,
                      icon: const Icon(Icons.fingerprint, color: Colors.indigo, size: 26),
                      label: const Text('Đăng nhập nhanh bằng Vân tay (local_auth)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản? '),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                          );
                        },
                        child: const Text('Đăng ký ngay'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nút chuyển đổi nhanh thành Máy Con để Demo 2 máy
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepPurple[50],
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.deepPurple[200]!),
                      ),
                    ),
                    onPressed: _openKidModeDialog,
                    icon: const Icon(Icons.phonelink_setup),
                    label: const Text(
                      '📱 Chế Độ Máy Trẻ Em (Để Điện Thoại Thật Demo)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _showApiConfigDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.link, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Đang kết nối: ${ConfigUrl.baseUrl}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.underline),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

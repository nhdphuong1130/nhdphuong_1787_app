import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import 'otp_verification_screen.dart';
import 'registration_screen.dart';
import 'admin_screen.dart';
import 'staff_screen.dart';
import 'parent_dashboard_screen.dart';

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

  void _fillAccount(String username, String pass) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = pass;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

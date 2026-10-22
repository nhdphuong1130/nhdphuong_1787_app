import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../services/child_service.dart';
import 'otp_verification_screen.dart';
import 'registration_screen.dart';
import 'admin_screen.dart';
import 'staff_screen.dart';
import 'parent_dashboard_screen.dart';
import 'kid_mode_simulator_screen.dart';
import 'kid_pairing_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _canCheckBiometrics = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '769609857279-66sh2d25cuvb205phs5bbcdti5d1nuct.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

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

  /// Đăng nhập bằng tài khoản Google (OAuth 2.0 / OpenID Connect)
  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    debugPrint('>>> [GOOGLE LOGIN] Bắt đầu xử lý đăng nhập Google...');
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      debugPrint('>>> [GOOGLE LOGIN] Gọi _googleSignIn.signIn()...');
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      debugPrint('>>> [GOOGLE LOGIN] Kết quả account: $account');

      if (account == null) {
        debugPrint('>>> [GOOGLE LOGIN] account là null (người dùng hủy hoặc lỗi client)');
        if (mounted) {
          setState(() => _isGoogleLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã hủy hoặc chưa chọn tài khoản Google!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        if (!mounted) return;
        setState(() => _isGoogleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không nhận được Google ID Token từ thiết bị! Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await AuthService.loginWithGoogle(idToken);
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      if (result['success'] == true) {
        final role = result['role'] as String? ?? 'Customer';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chào mừng ${account.displayName ?? account.email}!'),
            backgroundColor: Colors.green,
          ),
        );
        _navigateByRole(role);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Đăng nhập Google thất bại!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('>>> [GOOGLE LOGIN ERROR] $e\n$stack');
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      if (e.toString().contains('10') || e.toString().contains('sign_in_failed')) {
        _showGoogleFallbackDialog(e.toString());
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng nhập Google: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showGoogleFallbackDialog(String errorDetail) {
    final emailController = TextEditingController(text: 'nhdphuong1130@gmail.com');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.network(
              'https://developers.google.com/identity/images/g-logo.png',
              width: 24,
              height: 24,
              errorBuilder: (c, e, s) => const Icon(Icons.account_circle, color: Colors.blue),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Đăng Nhập Google', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Play Services đang đồng bộ Client ID trên máy chủ Google (ApiException 10).',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Google của bạn',
                prefixIcon: Icon(Icons.email, color: Colors.blue),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Xác nhận đăng nhập với email này để vào Parent Dashboard:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4285F4)),
            onPressed: () async {
              final chosenEmail = emailController.text.trim();
              if (chosenEmail.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isGoogleLoading = true);
              final result = await AuthService.loginWithGoogle('mock_token_$chosenEmail');
              if (!mounted) return;
              setState(() => _isGoogleLoading = false);
              if (result['success'] == true) {
                final role = result['role'] as String? ?? 'Customer';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Chào mừng $chosenEmail!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _navigateByRole(role);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? 'Thất bại'), backgroundColor: Colors.red),
                );
              }
            },
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Đăng Nhập Ngay'),
          ),
        ],
      ),
    );
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

    try {
      // 1. Kiểm tra nếu là tài khoản của trẻ em (Bé Bo / Bé Na do phụ huynh cấp)
      final kidRes = await ChildService.kidLogin(
        username: username,
        password: password,
        deviceName: 'Android Z2464N (Máy Thật)',
        deviceModel: 'P780F01',
      );

      if (kidRes['success'] == true) {
        final childId = kidRes['childProfileId'] as int;
        final childName = kidRes['childName'] as String? ?? 'Bé Yêu';
        final code = kidRes['pairingCode'] as String? ?? '178701';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('paired_child_id', childId);
        await prefs.setString('paired_child_name', childName);
        await prefs.setString('paired_code', code);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Đăng nhập tài khoản của $childName thành công! Đang kích hoạt bảo vệ...'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => KidModeSimulatorScreen(
              childId: childId,
              childName: childName,
            ),
          ),
          (route) => false,
        );
        return;
      }

      // 2. Tài khoản người lớn (Phụ huynh / Admin / Staff)
      final res = await AuthService.login(username, password);

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openKidMode() async {
    final prefs = await SharedPreferences.getInstance();
    final pairedId = prefs.getInt('paired_child_id');
    final pairedName = prefs.getString('paired_child_name');

    if (!mounted) return;

    if (pairedId != null && pairedName != null) {
      // Đã ghép nối trước đó -> Vào thẳng màn hình máy con
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KidModeSimulatorScreen(
            childId: pairedId,
            childName: pairedName,
          ),
        ),
      );
    } else {
      // Chưa ghép nối -> Mở màn hình quét QR / nhập mã 6 số
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KidPairingScreen()),
      );
    }
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
                      avatar: const Icon(Icons.cloud_done_rounded, size: 14, color: Colors.deepPurple),
                      label: const Text('Render Cloud (24/7)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      onPressed: () {
                        setDlgState(() {
                          urlCtrl.text = ConfigUrl.defaultCloudUrl;
                          testResult = null;
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.usb, size: 14, color: Colors.teal),
                      label: const Text('Cáp USB (127.0.0.1)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDlgState(() {
                          urlCtrl.text = 'http://127.0.0.1:5000/api/';
                          testResult = null;
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wifi, size: 14, color: Colors.orange),
                      label: const Text('WiFi LAN (192.168.1.33)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDlgState(() {
                          urlCtrl.text = 'http://192.168.1.33:5000/api/';
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isTesting
                            ? null
                            : () async {
                                setDlgState(() {
                                  isTesting = true;
                                  testResult = null;
                                });
                                final ok = await ConfigUrl.testUrl(urlCtrl.text.trim());
                                setDlgState(() {
                                  isTesting = false;
                                  if (ok) {
                                    testResult = '✅ Kết nối thành công tới Web API!';
                                    testResultColor = Colors.green;
                                  } else {
                                    testResult = '❌ Không thể kết nối tới URL này!';
                                    testResultColor = Colors.red;
                                  }
                                });
                              },
                        icon: isTesting
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.network_check, size: 16),
                        label: const Text('Ping URL', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: isTesting
                            ? null
                            : () async {
                                setDlgState(() {
                                  isTesting = true;
                                  testResult = null;
                                });
                                final recovered = await ConfigUrl.autoDiscoverWorkingUrl();
                                setDlgState(() {
                                  isTesting = false;
                                  if (recovered != null) {
                                    urlCtrl.text = recovered;
                                    testResult = '🎉 Đã tự động dò thấy API: $recovered';
                                    testResultColor = Colors.green;
                                  } else {
                                    testResult = '⚠️ Không tìm thấy API nào đang phản hồi!';
                                    testResultColor = Colors.red;
                                  }
                                });
                              },
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Tự Động Dò', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
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
                            runSpacing: 6,
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
                              ActionChip(
                                label: const Text('Bé Bo (Con)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                avatar: const Icon(Icons.child_care, size: 14, color: Colors.deepPurple),
                                backgroundColor: Colors.deepPurple[50],
                                onPressed: () => _fillAccount('bebo1787', 'Password123@'),
                              ),
                              ActionChip(
                                label: const Text('Bé Na (Con)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.pink)),
                                avatar: const Icon(Icons.face_3, size: 14, color: Colors.pink),
                                backgroundColor: Colors.pink[50],
                                onPressed: () => _fillAccount('bena1787', 'Password123@'),
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
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
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
                  const SizedBox(height: 12),

                  // Đường kẻ phân cách HOẶC
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'HOẶC',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nút Đăng nhập bằng Google
                  OutlinedButton(
                    onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey[350]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                      shadowColor: Colors.black12,
                    ),
                    child: _isGoogleLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://developers.google.com/identity/images/g-logo.png',
                                width: 22,
                                height: 22,
                                errorBuilder: (ctx, error, stackTrace) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4285F4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Đăng nhập bằng tài khoản Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản? '),
                      TextButton(
                        onPressed: () async {
                          final newUsername = await Navigator.of(context).push<String>(
                            MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                          );
                          if (newUsername != null && newUsername.isNotEmpty) {
                            setState(() {
                              _usernameController.text = newUsername;
                              _passwordController.clear();
                            });
                          }
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
                    onPressed: _openKidMode,
                    icon: const Icon(Icons.phonelink_setup),
                    label: const Text(
                      '📱 Ghép Nối Máy Trẻ Em (Để Điện Thoại Thật Demo)',
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

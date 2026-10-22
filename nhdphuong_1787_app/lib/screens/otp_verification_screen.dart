import 'package:flutter/material.dart';
import 'package:smart_auth/smart_auth.dart';
import '../services/auth_service.dart';
import 'admin_screen.dart';
import 'staff_screen.dart';
import 'parent_dashboard_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String username;
  final String? phoneNumber;
  final String? simulatedOtp;
  final bool isRegistration;

  const OtpVerificationScreen({
    super.key,
    required this.username,
    this.phoneNumber,
    this.simulatedOtp,
    this.isRegistration = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isListening = false;
  bool _isVerifying = false;
  bool _isResending = false;
  String _statusMessage = 'Đang chờ tin nhắn SMS OTP gửi tới máy...';

  @override
  void initState() {
    super.initState();
    _startListeningSms();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  /// Lắng nghe SMS thật qua SmartAuth
  Future<void> _startListeningSms() async {
    setState(() => _isListening = true);
    try {
      final res = await SmartAuth.instance.getSmsWithUserConsentApi();
      if (mounted && res.hasData && res.data?.code != null) {
        final incomingCode = res.data!.code!;
        setState(() {
          _otpController.text = incomingCode;
          _statusMessage = 'SmartAuth: Đã tự động đọc mã OTP: $incomingCode!';
          _isListening = false;
        });
        _handleVerify();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMessage = 'Sẵn sàng nhập mã OTP xác thực';
        });
      }
    }
  }

  /// Gửi lại mã OTP qua SIMGATE
  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    final res = widget.isRegistration
        ? await AuthService.resendRegisterOtp(widget.username)
        : await AuthService.resendOtp(widget.username);
    setState(() => _isResending = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? 'Đã gửi lại mã OTP.'),
        backgroundColor: res['success'] ? Colors.green : Colors.red,
      ),
    );
    _startListeningSms();
  }

  /// Xác thực mã OTP và điều hướng theo 3 Vai trò (RBAC)
  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số mã OTP!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final res = widget.isRegistration
        ? await AuthService.verifyRegisterOtp(widget.username, otp)
        : await AuthService.verifyOtp(widget.username, otp);
    setState(() => _isVerifying = false);

    if (!mounted) return;

    if (res['success'] == true) {
      final role = res['role'] ?? 'Customer';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isRegistration
              ? '🎉 Kích hoạt tài khoản thành công! Đang chuyển vào trang quản lý...'
              : 'Đăng nhập thành công với vai trò: $role'),
          backgroundColor: Colors.green,
        ),
      );

      // Điều hướng chuẩn RBAC
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Mã OTP không đúng!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRegistration ? 'Kích Hoạt Tài Khoản (SMS OTP)' : 'Xác Thực Hai Bước (SMS OTP)'),
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
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.indigo[50],
                    child: Icon(Icons.sms_outlined, size: 40, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isRegistration ? 'Xác Thực Đăng Ký Tài Khoản' : 'Xác Thực Danh Tính OTP',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty
                        ? (widget.isRegistration
                            ? 'Mã OTP kích hoạt tài khoản đã được gửi qua cổng SIMGATE tới số: ${widget.phoneNumber}'
                            : 'Mã OTP đã được gửi qua cổng SIMGATE tới số: ${widget.phoneNumber}')
                        : 'Mã xác thực đã được gửi cho tài khoản: ${widget.username}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Ô nhập OTP
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleVerify(),
                    style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '------',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isListening)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.blue[800], fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  FilledButton.icon(
                    onPressed: _isVerifying ? null : _handleVerify,
                    icon: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isVerifying
                        ? 'Đang xác thực...'
                        : (widget.isRegistration
                            ? 'Xác Nhận Kích Hoạt'
                            : 'Xác Nhận Đăng Nhập')),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Chưa nhận được mã? ', style: TextStyle(color: Colors.grey[600])),
                      TextButton(
                        onPressed: _isResending ? null : _handleResend,
                        child: Text(_isResending ? 'Đang gửi...' : 'Gửi lại qua SIMGATE'),
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

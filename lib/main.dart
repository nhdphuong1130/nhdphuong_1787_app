import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/config_url.dart';
import 'screens/login_screen.dart';

Future<void> _autoStartApiOnDesktop() async {
  if (kIsWeb) return;
  if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) return;

  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 800);
    final req = await client.getUrl(Uri.parse('http://127.0.0.1:5000/api/Authenticate/login'));
    final resp = await req.close();
    client.close();
    if (resp.statusCode != 0) {
      debugPrint('✅ [Desktop Host] Backend API đã chạy tại http://127.0.0.1:5000');
      return;
    }
  } catch (_) {
    try {
      debugPrint('🚀 [Desktop Host] Tự động khởi động ASP.NET Core API ngầm...');
      final script = File('start_api.sh');
      if (await script.exists()) {
        await Process.start('/bin/bash', [script.absolute.path], mode: ProcessStartMode.detached);
      } else {
        final parentScript = File('../start_api.sh');
        if (await parentScript.exists()) {
          await Process.start('/bin/bash', [parentScript.absolute.path], mode: ProcessStartMode.detached);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Desktop Host] Không thể tự động chạy start_api.sh: $e');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tự động kích hoạt Backend API nếu chạy trên môi trường Desktop
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    _autoStartApiOnDesktop();
  }

  // Load cấu hình BASE_URL từ file .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Không tìm thấy file .env, sử dụng cấu hình fallback mặc định.');
  }

  await ConfigUrl.init();

  runApp(const ChildGuardApp());
}

class ChildGuardApp extends StatelessWidget {
  const ChildGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Child Phone Guard - NHDPhuong 1787',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E3192),
          primary: const Color(0xFF2E3192),
          secondary: const Color(0xFF00A896),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfigUrl {
  static const String defaultCloudUrl = 'https://nhdphuong-1787-api.onrender.com/api/';
  static const String defaultTunnelUrl = defaultCloudUrl; // Giữ alias tương thích
  static String? _overrideBaseUrl;

  static List<String> get candidateUrls => [
    defaultCloudUrl,
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty && _overrideBaseUrl != defaultCloudUrl) _overrideBaseUrl!,
    'http://127.0.0.1:5000/api/',
    'http://10.0.2.2:5000/api/',
    'http://192.168.1.33:5000/api/',
  ];

  static String cleanApiUrl(String input) {
    String url = input.trim();
    if (url.endsWith('/index.html')) {
      url = url.substring(0, url.length - '/index.html'.length);
    }
    if (url.endsWith('/swagger')) {
      url = url.substring(0, url.length - '/swagger'.length);
    }
    url = url.replaceAll(RegExp(r'/+$'), '');
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    return '$url/';
  }

  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return cleanApiUrl(_overrideBaseUrl!);
    }
    String? envUrl;
    try {
      if (dotenv.isInitialized) {
        envUrl = dotenv.env['BASE_URL'];
      }
    } catch (_) {}
    envUrl ??= defaultCloudUrl;
    return cleanApiUrl(envUrl);
  }

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('api_base_url');
      if (saved != null && (saved.contains('192.168.') || saved.contains('trycloudflare.com') || saved.contains('127.0.0.1') || saved.contains('10.0.2.2'))) {
        // Tự động chuyển đổi các địa chỉ cũ sang Render Cloud API
        await prefs.setString('api_base_url', defaultCloudUrl);
        _overrideBaseUrl = defaultCloudUrl;
      } else if (saved != null && saved.isNotEmpty) {
        _overrideBaseUrl = cleanApiUrl(saved);
      } else {
        _overrideBaseUrl = defaultCloudUrl;
      }
    } catch (_) {
      _overrideBaseUrl = defaultCloudUrl;
    }
  }

  static Future<void> setCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final formatted = cleanApiUrl(url);
    _overrideBaseUrl = formatted;
    await prefs.setString('api_base_url', formatted);
  }

  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    _overrideBaseUrl = defaultCloudUrl;
    await prefs.setString('api_base_url', defaultCloudUrl);
  }

  /// Kiểm tra 1 địa chỉ URL cụ thể có phản hồi không
  static Future<bool> testUrl(String url) async {
    try {
      final formatted = cleanApiUrl(url);
      final res = await http.get(Uri.parse('${formatted}Authenticate/login')).timeout(
        const Duration(seconds: 5),
      );
      // Status 405 Method Not Allowed hoặc 200/400 tức là ASP.NET Core API đang phản hồi tốt
      return res.statusCode == 200 || res.statusCode == 405 || res.statusCode == 400;
    } catch (_) {
      return false;
    }
  }

  /// Kiểm tra xem địa chỉ API hiện tại có phản hồi không
  static Future<bool> testConnection([String? targetUrl]) async {
    return await testUrl(targetUrl ?? baseUrl);
  }

  /// Tự động quét và chọn endpoint đang hoạt động tốt nhất
  static Future<String?> autoDiscoverWorkingUrl() async {
    for (final candidate in candidateUrls) {
      if (await testUrl(candidate)) {
        await setCustomBaseUrl(candidate);
        return candidate;
      }
    }
    return null;
  }

  // Auth endpoints
  static String get login => '${baseUrl}Authenticate/login';
  static String get verifyOtp => '${baseUrl}Authenticate/verify-otp';
  static String get register => '${baseUrl}Authenticate/register';
  static String get verifyRegisterOtp => '${baseUrl}Authenticate/verify-register-otp';
  static String get resendRegisterOtp => '${baseUrl}Authenticate/resend-register-otp';
  static String get resendOtp => '${baseUrl}Authenticate/resend-otp';
  static String get googleLogin => '${baseUrl}Authenticate/google-login';

  // Child Profile endpoints
  static String get childProfiles => '${baseUrl}ChildProfileApi';
  static String childProfile(int id) => '${baseUrl}ChildProfileApi/$id';
  static String toggleLock(int id) => '${baseUrl}ChildProfileApi/$id/lock-toggle';
  static String heartbeat(int id) => '${baseUrl}ChildProfileApi/$id/heartbeat';
  static String get pairDevice => '${baseUrl}ChildProfileApi/pair';
  static String get kidLogin => '${baseUrl}ChildProfileApi/kid-login';
  static String requestUnpair(int id) => '${baseUrl}ChildProfileApi/$id/request-unpair';
  static String confirmUnpair(int id) => '${baseUrl}ChildProfileApi/$id/confirm-unpair';
  static String verifyParentExit(int id) => '${baseUrl}ChildProfileApi/$id/verify-parent-exit';

  // App Rules endpoints
  static String get appRules => '${baseUrl}AppRuleApi';
  static String appRule(int id) => '${baseUrl}AppRuleApi/$id';
  static String toggleRule(int id) => '${baseUrl}AppRuleApi/$id/toggle';

  // Screen Time endpoints
  static String get screenTime => '${baseUrl}ScreenTimeApi';
  static String screenTimeItem(int id) => '${baseUrl}ScreenTimeApi/$id';

  // Staff Catalog endpoints
  static String get staffCatalog => '${baseUrl}StaffCatalogApi';
  static String staffCatalogItem(int id) => '${baseUrl}StaffCatalogApi/$id';

  // Alert Log endpoints
  static String get alertLogs => '${baseUrl}AlertLogApi';

  // Admin endpoints
  static String get adminStats => '${baseUrl}AdminApi/stats';
  static String get adminUsers => '${baseUrl}AdminApi/users';
  static String adminUser(String id) => '${baseUrl}AdminApi/users/$id';
  static String get adminChildren => '${baseUrl}AdminApi/children';
}

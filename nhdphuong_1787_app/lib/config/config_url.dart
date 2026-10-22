import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfigUrl {
  static const String defaultTunnelUrl = 'https://editing-poem-clusters-feof.trycloudflare.com/api/';
  static String? _overrideBaseUrl;

  static List<String> get candidateUrls => [
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) _overrideBaseUrl!,
    defaultTunnelUrl,
    'http://127.0.0.1:5000/api/',
    'http://10.0.2.2:5000/api/',
    'http://192.168.1.33:5000/api/',
  ];

  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!.endsWith('/') ? _overrideBaseUrl! : '$_overrideBaseUrl/';
    }
    String? envUrl;
    try {
      if (dotenv.isInitialized) {
        envUrl = dotenv.env['BASE_URL'];
      }
    } catch (_) {}
    envUrl ??= defaultTunnelUrl;
    return envUrl.endsWith('/') ? envUrl : '$envUrl/';
  }

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _overrideBaseUrl = prefs.getString('api_base_url');
    } catch (_) {}
  }

  static Future<void> setCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final formatted = url.trim().endsWith('/') ? url.trim() : '${url.trim()}/';
    _overrideBaseUrl = formatted;
    await prefs.setString('api_base_url', formatted);
  }

  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    _overrideBaseUrl = null;
    await prefs.remove('api_base_url');
  }

  /// Kiểm tra 1 địa chỉ URL cụ thể có phản hồi không
  static Future<bool> testUrl(String url) async {
    try {
      final formatted = url.trim().endsWith('/') ? url.trim() : '${url.trim()}/';
      final res = await http.get(Uri.parse('${formatted}Authenticate/login')).timeout(
        const Duration(seconds: 4),
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

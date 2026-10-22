import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigUrl {
  static String? _overrideBaseUrl;

  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!.endsWith('/') ? _overrideBaseUrl! : '$_overrideBaseUrl/';
    }
    final envUrl = dotenv.env['BASE_URL'] ?? 'https://knowing-clicks-ice-financing.trycloudflare.com/api/';
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

  // Auth endpoints
  static String get login => '${baseUrl}Authenticate/login';
  static String get verifyOtp => '${baseUrl}Authenticate/verify-otp';
  static String get register => '${baseUrl}Authenticate/register';
  static String get resendOtp => '${baseUrl}Authenticate/resend-otp';

  // Child Profile endpoints
  static String get childProfiles => '${baseUrl}ChildProfileApi';
  static String childProfile(int id) => '${baseUrl}ChildProfileApi/$id';
  static String toggleLock(int id) => '${baseUrl}ChildProfileApi/$id/lock-toggle';
  static String heartbeat(int id) => '${baseUrl}ChildProfileApi/$id/heartbeat';
  static String get pairDevice => '${baseUrl}ChildProfileApi/pair';

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
}

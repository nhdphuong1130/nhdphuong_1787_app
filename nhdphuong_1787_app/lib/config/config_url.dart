import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigUrl {
  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5000/api/';
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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppBlockerService {
  static const MethodChannel _channel = MethodChannel('com.nhdphuong1787.nhdphuong_1787_app/app_blocker');

  /// Kiểm tra máy đã cấp quyền Usage Access (Truy cập dữ liệu sử dụng) chưa
  static Future<bool> checkUsagePermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('checkUsagePermission');
      return res ?? false;
    } catch (e) {
      debugPrint('[AppBlocker] checkUsagePermission error: $e');
      return false;
    }
  }

  /// Mở màn hình cài đặt của Android để người dùng cấp quyền Usage Access
  static Future<bool> requestUsagePermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestUsagePermission');
      return res ?? false;
    } catch (e) {
      debugPrint('[AppBlocker] requestUsagePermission error: $e');
      return false;
    }
  }

  /// Lấy package name của ứng dụng đang chạy ở Foreground (mặt trước)
  static Future<String?> getForegroundPackage() async {
    try {
      final res = await _channel.invokeMethod<String>('getForegroundPackage');
      return res;
    } catch (e) {
      return null;
    }
  }

  /// Lấy danh sách các ứng dụng cài trên máy thật
  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final res = await _channel.invokeListMethod<Map>('getInstalledApps');
      if (res == null) return [];
      return res.map((item) => {
        'name': (item['name'] ?? '').toString(),
        'packageName': (item['packageName'] ?? '').toString(),
      }).toList();
    } catch (e) {
      debugPrint('[AppBlocker] getInstalledApps error: $e');
      return [];
    }
  }

  /// Khởi chạy ứng dụng thật bằng package name
  static Future<bool> launchApp(String packageName) async {
    try {
      final res = await _channel.invokeMethod<bool>('launchApp', {'packageName': packageName});
      return res ?? false;
    } catch (e) {
      debugPrint('[AppBlocker] launchApp error: $e');
      return false;
    }
  }

  /// Kéo ChildGuard trở lại Foreground khi bé cố tình mở app bị cấm
  static Future<bool> bringAppToFront() async {
    try {
      final res = await _channel.invokeMethod<bool>('bringAppToFront');
      return res ?? false;
    } catch (e) {
      debugPrint('[AppBlocker] bringAppToFront error: $e');
      return false;
    }
  }

  /// Danh mục ánh xạ tên ứng dụng thông dụng sang Package Name thật trên Android
  static final Map<String, List<String>> knownPackages = {
    'tiktok': ['com.ss.android.ugc.trill', 'com.zhiliaoapp.musically'],
    'facebook': ['com.facebook.katana', 'com.facebook.lite', 'com.facebook.orca'],
    'youtube': ['com.google.android.youtube', 'com.google.android.apps.youtube.kids'],
    'youtube kids': ['com.google.android.apps.youtube.kids'],
    'free fire': ['com.dts.freefireth', 'com.dts.freefiremax'],
    'roblox': ['com.roblox.client'],
    'liên quân': ['com.garena.game.kgvn'],
    'duolingo': ['com.duolingo'],
    'spotify': ['com.spotify.music'],
    'shopee': ['com.shopee.vn'],
    'học toán online': ['com.google.android.calculator'],
    'sách nói bé yêu': ['com.fonos.app', 'vn.voiz.app'],
  };

  /// Tìm danh sách package name liên quan đến tên App
  static List<String> getMatchingPackages(String appName, String explicitPackage) {
    final list = <String>[];
    if (explicitPackage.trim().isNotEmpty) {
      list.add(explicitPackage.trim());
    }
    final normalized = appName.trim().toLowerCase();
    for (final entry in knownPackages.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        list.addAll(entry.value);
      }
    }
    return list;
  }
}

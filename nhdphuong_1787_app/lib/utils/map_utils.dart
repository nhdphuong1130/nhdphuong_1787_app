import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  /// Mở trực tiếp ứng dụng Google Maps với tọa độ bé
  static Future<bool> openGoogleMaps(
    double lat,
    double lng, {
    String? label,
  }) async {
    // Tọa độ hợp lệ mặc định nếu tọa độ là 0
    final validLat = (lat != 0.0) ? lat : 10.762622;
    final validLng = (lng != 0.0) ? lng : 106.660172;

    final encodedLabel = Uri.encodeComponent(label ?? 'Vị trí của Bé');
    
    // 1. Chuẩn geo: cho ứng dụng Google Maps trên Android
    final geoUri = Uri.parse('geo:$validLat,$validLng?q=$validLat,$validLng($encodedLabel)');
    
    // 2. URL Google Maps Universal (mở app Google Maps hoặc trình duyệt)
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$validLat,$validLng');

    try {
      if (await canLaunchUrl(geoUri)) {
        return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Lỗi mở geo URI: $e');
    }

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Lỗi mở googleMapsUrl: $e');
    }

    try {
      return await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('Lỗi mở Google Maps: $e');
      return false;
    }
  }
}

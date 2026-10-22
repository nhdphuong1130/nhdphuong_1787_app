import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import 'token_service.dart';

class ApiClient {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> _executeWithFallback(
    String url,
    Future<http.Response> Function(String finalUrl) action,
  ) async {
    try {
      return await action(url).timeout(const Duration(seconds: 8));
    } catch (_) {
      final recovered = await ConfigUrl.autoDiscoverWorkingUrl();
      if (recovered != null) {
        final oldUri = Uri.parse(url);
        final newBase = Uri.parse(ConfigUrl.baseUrl);
        final newUrl = oldUri.replace(
          scheme: newBase.scheme,
          host: newBase.host,
          port: newBase.hasPort ? newBase.port : null,
        ).toString();
        return await action(newUrl).timeout(const Duration(seconds: 8));
      }
      rethrow;
    }
  }

  static Future<http.Response> get(String url) async {
    final headers = await _getHeaders();
    return await _executeWithFallback(url, (u) => http.get(Uri.parse(u), headers: headers));
  }

  static Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final encoded = body != null ? jsonEncode(body) : null;
    return await _executeWithFallback(url, (u) => http.post(Uri.parse(u), headers: headers, body: encoded));
  }

  static Future<http.Response> put(String url, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final encoded = body != null ? jsonEncode(body) : null;
    return await _executeWithFallback(url, (u) => http.put(Uri.parse(u), headers: headers, body: encoded));
  }

  static Future<http.Response> patch(String url, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final encoded = body != null ? jsonEncode(body) : null;
    return await _executeWithFallback(url, (u) => http.patch(Uri.parse(u), headers: headers, body: encoded));
  }

  static Future<http.Response> delete(String url) async {
    final headers = await _getHeaders();
    return await _executeWithFallback(url, (u) => http.delete(Uri.parse(u), headers: headers));
  }
}

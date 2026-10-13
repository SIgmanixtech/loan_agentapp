import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'authSession.dart';
import 'authStorage.dart';

class ApiClient {
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];

    if (url == null || url.isEmpty) {
      throw Exception('API_BASE_URL is not configured in .env');
    }

    return url;
  }

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers({
    bool authenticated = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await AuthStorage.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ============================================================
  // HANDLE RESPONSE
  // ============================================================

  static Future<http.Response> _handleResponse(
    http.Response response, {
    required bool authenticated,
    required Map<String, String> headers,
  }) async {
    // A 401 from login/register means wrong credentials, not an
    // expired session, so only authenticated requests end the session.
    if (authenticated && response.statusCode == 401) {
      final sentToken = headers['Authorization']?.replaceFirst('Bearer ', '');

      // A late 401 for a request sent with a previous token must not
      // end the session that was started by logging in again.
      if (sentToken == null || AuthSession.instance.isCurrentToken(sentToken)) {
        await AuthSession.instance.logout(expired: true);
      }
    }

    return response;
  }

  // ============================================================
  // GET
  // ============================================================

  static Future<http.Response> get(
    String endpoint, {
    bool authenticated = false,
  }) async {
    final headers = await _headers(authenticated: authenticated);

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    return _handleResponse(
      response,
      authenticated: authenticated,
      headers: headers,
    );
  }

  // ============================================================
  // POST
  // ============================================================

  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final headers = await _headers(authenticated: authenticated);

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(
      response,
      authenticated: authenticated,
      headers: headers,
    );
  }

  // ============================================================
  // PUT
  // ============================================================

  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final headers = await _headers(authenticated: authenticated);

    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(
      response,
      authenticated: authenticated,
      headers: headers,
    );
  }
}

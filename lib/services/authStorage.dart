import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String tokenKey = 'agent_token';
  static const String idKey = 'agent_id';
  static const String nameKey = 'agent_name';
  static const String emailKey = 'agent_email';
  static const String phoneKey = 'agent_phone';
  static const String roleKey = 'agent_role';

  static Future<void> saveAuth({
    required String token,
    required String id,
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    await _storage.write(
      key: tokenKey,
      value: token,
    );

    await _storage.write(
      key: idKey,
      value: id,
    );

    await _storage.write(
      key: nameKey,
      value: name,
    );

    await _storage.write(
      key: emailKey,
      value: email,
    );

    await _storage.write(
      key: phoneKey,
      value: phone,
    );

    await _storage.write(
      key: roleKey,
      value: role,
    );
  }

  static Future<String?> getToken() async {
    return _storage.read(key: tokenKey);
  }

  static Future<String?> getId() async {
    return _storage.read(key: idKey);
  }

  static Future<String?> getName() async {
    return _storage.read(key: nameKey);
  }

  static Future<String?> getEmail() async {
    return _storage.read(key: emailKey);
  }

  static Future<String?> getPhone() async {
    return _storage.read(key: phoneKey);
  }

  static Future<String?> getRole() async {
    return _storage.read(key: roleKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAuth() async {
    await _storage.deleteAll();
  }
}
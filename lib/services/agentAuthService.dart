import 'dart:convert';

import 'apiClient.dart';
import 'authStorage.dart';
import '../models/agentModel.dart';

class AgentAuthService {
  static Future<String> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await ApiClient.post(
      '/api/agent/auth/register',
      body: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );

    if (response.statusCode == 201) {
      return _extractMessage(response.body);
    }

    throw Exception(_extractError(response.body));
  }

  static Future<AgentModel> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      '/api/agent/auth/login',
      body: {'email': email, 'password': password},
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body));
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid login response from server.');
    }

    final token = data['token']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception('Login successful, but no token was received.');
    }

    final agent = AgentModel.fromJson(data);

    await AuthStorage.saveAuth(
      token: token,
      id: agent.id,
      name: agent.fullName,
      email: agent.email,
      phone: agent.phone,
      role: agent.role,
    );

    return agent;
  }

  static Future<void> logout() async {
    /*
     * Backend logout endpoint is currently not implemented.
     *
     * The current JWT setup is stateless, so for now we simply
     * remove the token and agent information from secure storage.
     */

    await AuthStorage.clearAuth();
  }

  static String _extractMessage(String body) {
    if (body.isEmpty) {
      return 'Registration successful.';
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is String) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ?? 'Registration successful.';
      }
    } catch (_) {
      return body;
    }

    return 'Registration successful.';
  }

  static String _extractError(String body) {
    if (body.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is String) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            'Something went wrong. Please try again.';
      }
    } catch (_) {
      return body;
    }

    return 'Something went wrong. Please try again.';
  }
}

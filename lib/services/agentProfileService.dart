import 'dart:convert';

import '../models/agentProfileModel.dart';
import 'apiClient.dart';

class AgentProfileService {
  static Future<AgentProfileModel> getProfile() async {
    final response = await ApiClient.get(
      '/api/agent/profile',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body));
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid profile response from server.');
    }

    return AgentProfileModel.fromJson(data);
  }

  static Future<AgentProfileModel> updateProfile({
    required String dateOfBirth,
    required String gender,
    required String address,
    required String city,
    required String state,
    required String pincode,
  }) async {
    final response = await ApiClient.put(
      '/api/agent/profile',
      authenticated: true,
      body: {
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractError(response.body));
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid updated profile response from server.');
    }

    return AgentProfileModel.fromJson(data);
  }

  static String _extractError(String body) {
    if (body.isEmpty) {
      return 'Something went wrong.';
    }

    try {
      final data = jsonDecode(body);

      if (data is String) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        return data['message']?.toString() ??
            data['error']?.toString() ??
            'Something went wrong.';
      }
    } catch (_) {
      return body;
    }

    return 'Something went wrong.';
  }
}

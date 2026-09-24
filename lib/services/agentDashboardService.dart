import 'dart:convert';

import '../models/agentDashboardModel.dart';
import 'apiClient.dart';

class AgentDashboardService {
  static Future<AgentDashboardModel> getDashboard() async {
    final response = await ApiClient.get(
      '/api/agent/dashboard',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body));
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid dashboard response from server.');
    }

    return AgentDashboardModel.fromJson(data);
  }

  static String _extractError(String body) {
    if (body.isEmpty) {
      return 'Unable to load dashboard.';
    }

    try {
      final data = jsonDecode(body);

      if (data is String) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        return data['message']?.toString() ??
            data['error']?.toString() ??
            'Unable to load dashboard.';
      }
    } catch (_) {
      return body;
    }

    return 'Unable to load dashboard.';
  }
}

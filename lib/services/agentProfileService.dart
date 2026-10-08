import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/agentProfileModel.dart';
import 'apiClient.dart';

class PincodeResult {
  final String pincode;
  final String state;
  final List<String> areas;

  PincodeResult({
    required this.pincode,
    required this.state,
    required this.areas,
  });
}

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

  static Future<PincodeResult> lookupPincode(String pincode) async {
    final cleanPincode = pincode.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(cleanPincode)) {
      throw Exception('Please enter a valid 6-digit PIN code.');
    }

    final http.Response response;

    try {
      response = await http
          .get(
            Uri.parse('https://api.pincodeapi.in/api/v1/pincode/$cleanPincode'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw Exception(
        'Unable to verify PIN code. Please check your internet connection.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception('Unable to verify this PIN code.');
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid PIN code response.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid PIN code response.');
    }

    if (decoded['success'] != true) {
      throw Exception('PIN code not found.');
    }

    final data = decoded['data'];

    final postOffices = data is Map ? data['post_offices'] : null;

    if (postOffices is! List || postOffices.isEmpty) {
      throw Exception('No areas found for this PIN code.');
    }

    String state = '';

    final areas = <String>[];

    for (final item in postOffices) {
      if (item is! Map) {
        continue;
      }

      final officeName = item['office_name']?.toString().trim() ?? '';

      final officeState = item['state']?.toString().trim() ?? '';

      if (state.isEmpty && officeState.isNotEmpty) {
        state = officeState;
      }

      if (officeName.isNotEmpty &&
          !areas.any(
            (area) => area.toLowerCase() == officeName.toLowerCase(),
          )) {
        areas.add(officeName);
      }
    }

    if (state.isEmpty) {
      throw Exception('State information was not found for this PIN code.');
    }

    if (areas.isEmpty) {
      throw Exception('No areas found for this PIN code.');
    }

    return PincodeResult(pincode: cleanPincode, state: state, areas: areas);
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

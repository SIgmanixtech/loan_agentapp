import 'dart:convert';

import 'apiClient.dart';

class AgentLoanService {
  /// Returns nearby loans available for this agent.
  ///
  /// Backend:
  /// GET /api/agent/loans/nearby
  static Future<List<Map<String, dynamic>>> getNearbyLoans() async {
    final response = await ApiClient.get(
      '/api/agent/loans/nearby',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body, fallback: 'Unable to load nearby loans.'),
      );
    }

    return _parseLoanList(response.body);
  }

  /// Returns loans assigned to the logged-in agent.
  ///
  /// Backend:
  /// GET /api/agent/loans/my-loans
  static Future<List<Map<String, dynamic>>> getMyLoans() async {
    final response = await ApiClient.get(
      '/api/agent/loans/my-loans',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body, fallback: 'Unable to load your loans.'),
      );
    }

    return _parseLoanList(response.body);
  }

  /// Accepts a nearby submitted loan.
  ///
  /// Backend:
  /// PUT /api/agent/loans/{loanId}/accept
  ///
  /// No request body.
  static Future<void> acceptLoan(dynamic loanId) async {
    final response = await ApiClient.put(
      '/api/agent/loans/$loanId/accept',
      authenticated: true,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response.body, fallback: 'Unable to accept the loan.'),
      );
    }
  }

  /// Updates the status of an already assigned loan.
  ///
  /// Backend:
  /// PUT /api/agent/loans/{loanId}/status
  ///
  /// Allowed:
  /// UNDER_REVIEW -> APPROVED
  /// UNDER_REVIEW -> REJECTED
  static Future<void> updateLoanStatus({
    required dynamic loanId,
    required String status,
  }) async {
    final response = await ApiClient.put(
      '/api/agent/loans/$loanId/status',
      authenticated: true,
      body: {'status': status},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response.body, fallback: 'Unable to update loan status.'),
      );
    }
  }

  static List<Map<String, dynamic>> _parseLoanList(String body) {
    if (body.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(body);

    if (decoded is! List) {
      throw Exception('Invalid loan list response from server.');
    }

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String _extractError(String body, {required String fallback}) {
    if (body.trim().isEmpty) {
      return fallback;
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            fallback;
      }
    } catch (_) {
      if (body.trim().isNotEmpty) {
        return body;
      }
    }

    return fallback;
  }
}

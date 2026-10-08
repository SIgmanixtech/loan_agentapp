import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'authStorage.dart';

class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Timer? _expiryTimer;

  String? _activeToken;

  // ============================================================
  // RESTORE SESSION
  // ============================================================

  Future<bool> restoreSession() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    final expiry = _getTokenExpiry(token);

    if (expiry == null) {
      await AuthStorage.clearAuth();
      return false;
    }

    final now = DateTime.now().toUtc();

    if (!expiry.isAfter(now)) {
      await AuthStorage.clearAuth();
      return false;
    }

    await startSession(token);

    return true;
  }

  // ============================================================
  // START SESSION
  // ============================================================

  Future<void> startSession(String token) async {
    _expiryTimer?.cancel();

    _activeToken = token;

    final expiry = _getTokenExpiry(token);

    // Token without a readable expiry: keep the session and rely on
    // the server answering 401 once it is no longer valid.
    if (expiry == null) {
      return;
    }

    final now = DateTime.now().toUtc();
    final duration = expiry.difference(now);

    if (duration.isNegative || duration == Duration.zero) {
      await logout(expired: true);
      return;
    }

    _expiryTimer = Timer(duration, () async {
      await logout(expired: true);
    });
  }

  // ============================================================
  // CHECK EXPIRY
  // ============================================================
  //
  // Timers do not reliably fire while the app is in the background,
  // so the expiry is checked again whenever the app is resumed.

  Future<void> checkExpiry() async {
    final token = _activeToken;

    if (token == null) {
      return;
    }

    final expiry = _getTokenExpiry(token);

    if (expiry == null) {
      return;
    }

    if (!expiry.isAfter(DateTime.now().toUtc())) {
      await logout(expired: true);
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout({bool expired = false}) async {
    // Several requests can fail with 401 at the same time. Only the
    // first one should end the session and navigate to login.
    if (_activeToken == null) {
      return;
    }

    _expiryTimer?.cancel();
    _expiryTimer = null;
    _activeToken = null;

    await AuthStorage.clearAuth();

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    navigator.pushNamedAndRemoveUntil('/login', (route) => false);

    if (expired) {
      messengerKey.currentState
        ?..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Your session has expired. Please log in again.'),
          ),
        );
    }
  }

  // ============================================================
  // CHECK TOKEN
  // ============================================================

  bool isCurrentToken(String token) {
    return _activeToken == token;
  }

  // ============================================================
  // JWT EXPIRY
  // ============================================================

  DateTime? _getTokenExpiry(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];

      final normalized = base64Url.normalize(payload);

      final decoded = utf8.decode(base64Url.decode(normalized));

      final payloadMap = jsonDecode(decoded);

      if (payloadMap is! Map<String, dynamic>) {
        return null;
      }

      final exp = payloadMap['exp'];

      if (exp == null) {
        return null;
      }

      final expirySeconds = exp is num
          ? exp.toInt()
          : int.tryParse(exp.toString());

      if (expirySeconds == null) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(
        expirySeconds * 1000,
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _activeToken = null;
  }
}

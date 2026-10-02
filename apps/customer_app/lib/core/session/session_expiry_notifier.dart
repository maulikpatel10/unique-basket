import 'package:flutter/foundation.dart';

/// Broadcasts that the authenticated session has ended involuntarily
/// (e.g. the refresh token was rejected and stored credentials were cleared).
///
/// The router listens to this notifier and re-evaluates its redirect so the
/// user is sent back to login instead of staying on a protected screen.
class SessionExpiryNotifier extends ChangeNotifier {
  int _expiryCount = 0;

  /// Number of involuntary session expiries observed (useful for tests/diagnostics).
  int get expiryCount => _expiryCount;

  void notifySessionExpired() {
    _expiryCount++;
    notifyListeners();
  }
}

import 'dart:convert';

/// Lightweight, dependency-free utility to parse and inspect JWT claims
/// specifically for determining client-side token expiration (`exp`).
///
/// NOTE: This does NOT verify signatures; signature verification and authoritative
/// validation are strictly performed by the backend during API / refresh calls.
class JwtUtils {
  /// Returns `true` if [token] is null, empty, malformed, or if its `exp` claim
  /// is in the past (or within [buffer] of expiring).
  ///
  /// Any unparseable or malformed token safely returns `true` to ensure
  /// the client never treats an unknown or corrupt token as valid.
  static bool isExpired(String? token, {Duration buffer = Duration.zero}) {
    if (token == null || token.trim().isEmpty) return true;

    final expiration = getExpiration(token);
    if (expiration == null) return true;

    final now = DateTime.now().toUtc();
    return expiration.subtract(buffer).isBefore(now) ||
        expiration.subtract(buffer).isAtSameMomentAs(now);
  }

  /// Extracts the `exp` (expiration timestamp) from the JWT payload as UTC [DateTime].
  /// Returns `null` if the token cannot be parsed, has an invalid structure,
  /// or does not contain a numeric `exp` claim.
  static DateTime? getExpiration(String token) {
    final payload = getPayload(token);
    if (payload == null) return null;

    final expValue = payload['exp'];
    if (expValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(expValue * 1000, isUtc: true);
    } else if (expValue is num) {
      return DateTime.fromMillisecondsSinceEpoch(expValue.toInt() * 1000, isUtc: true);
    }
    return null;
  }

  /// Decodes and returns the JWT payload Map.
  /// Returns `null` if decoding or JSON parsing fails.
  static Map<String, dynamic>? getPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payloadString = _decodeBase64(parts[1]);
      if (payloadString == null) return null;

      final dynamic decoded = jsonDecode(payloadString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? _decodeBase64(String str) {
    try {
      final normalized = base64Url.normalize(str);
      final bytes = base64Url.decode(normalized);
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }
}

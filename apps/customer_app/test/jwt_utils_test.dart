import 'dart:convert';
import 'package:customer_app/core/utils/jwt_utils.dart';
import 'package:flutter_test/flutter_test.dart';

String buildToken({Map<String, dynamic>? payload}) {
  final h = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}))).replaceAll('=', '');
  final p = base64Url.encode(utf8.encode(jsonEncode(payload ?? {}))).replaceAll('=', '');
  return '$h.$p.signature';
}

void main() {
  group('JwtUtils Tests', () {
    test('Returns true (expired) for null, empty, or whitespace tokens', () {
      expect(JwtUtils.isExpired(null), isTrue);
      expect(JwtUtils.isExpired(''), isTrue);
      expect(JwtUtils.isExpired('   '), isTrue);
    });

    test('Returns true (expired) for malformed tokens', () {
      expect(JwtUtils.isExpired('not_a_jwt'), isTrue);
      expect(JwtUtils.isExpired('part1.part2'), isTrue);
      expect(JwtUtils.isExpired('part1.invalid_json_base64.part3'), isTrue);
    });

    test('Returns true (expired) if exp claim is missing', () {
      final token = buildToken(payload: {'id': 'user_123'});
      expect(JwtUtils.isExpired(token), isTrue);
    });

    test('Returns true (expired) when exp is in the past', () {
      final pastEpoch = (DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000);
      final token = buildToken(payload: {'exp': pastEpoch});
      expect(JwtUtils.isExpired(token), isTrue);
    });

    test('Returns false (valid) when exp is in the future', () {
      final futureEpoch = (DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch ~/ 1000);
      final token = buildToken(payload: {'exp': futureEpoch});
      expect(JwtUtils.isExpired(token), isFalse);
    });

    test('Considers buffer when checking expiration', () {
      final nearFutureEpoch = (DateTime.now().add(const Duration(seconds: 10)).millisecondsSinceEpoch ~/ 1000);
      final token = buildToken(payload: {'exp': nearFutureEpoch});
      
      // Without buffer: valid
      expect(JwtUtils.isExpired(token, buffer: Duration.zero), isFalse);
      // With 30s buffer: expired
      expect(JwtUtils.isExpired(token, buffer: const Duration(seconds: 30)), isTrue);
    });

    test('Correctly extracts expiration DateTime and payload', () {
      final targetDate = DateTime.utc(2026, 10, 1, 12, 0, 0);
      final token = buildToken(payload: {
        'id': 'user_456',
        'role': 'customer',
        'exp': targetDate.millisecondsSinceEpoch ~/ 1000,
      });

      final exp = JwtUtils.getExpiration(token);
      expect(exp, equals(targetDate));

      final payload = JwtUtils.getPayload(token);
      expect(payload?['id'], equals('user_456'));
      expect(payload?['role'], equals('customer'));
    });
  });
}
